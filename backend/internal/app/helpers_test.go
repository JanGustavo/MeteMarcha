package app

import (
	"bytes"
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/jpeg"
	"image/png"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

// fakeClock deixa os testes "viajarem no tempo" sem esperar horas de verdade.
type fakeClock struct {
	mu sync.Mutex
	t  time.Time
}

func (c *fakeClock) Now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.t
}
func (c *fakeClock) Set(t time.Time) { c.mu.Lock(); c.t = t; c.mu.Unlock() }
func (c *fakeClock) Advance(d time.Duration) {
	c.mu.Lock()
	c.t = c.t.Add(d)
	c.mu.Unlock()
}

var t0 = time.Date(2026, 11, 1, 12, 0, 0, 0, time.UTC)

type env struct {
	t     *testing.T
	cfg   platform.Config
	clock *fakeClock
	app   *App
	srv   *httptest.Server
}

type user struct {
	id, name, token string
}

// newEnv sobe o programa inteiro (banco SQLite temporário, pastas temporárias,
// catálogo de músicas de teste) com um relógio controlável.
func newEnv(t *testing.T, mutate ...func(*platform.Config)) *env {
	t.Helper()
	dir := t.TempDir()
	cfg := platform.DefaultConfig()
	cfg.DBPath = filepath.Join(dir, "db", "test.db")
	cfg.MediaDir = filepath.Join(dir, "media")
	cfg.MusicDir = filepath.Join(dir, "music")
	cfg.PasswordMemoryKiB = 1024 // barato para os testes
	for _, m := range mutate {
		m(&cfg)
	}

	if err := os.MkdirAll(cfg.MusicDir, 0o755); err != nil {
		t.Fatal(err)
	}
	for _, f := range []string{"forca.mp3", "ritmo.mp3"} {
		if err := os.WriteFile(filepath.Join(cfg.MusicDir, f), bytes.Repeat([]byte("a"), 2048), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	catalog := `{"tracks":[
	 {"id":"forca-total","title":"Força Total","artist":"Banda Própria","file":"forca.mp3","duration_ms":120000,"license":"Autoria própria"},
	 {"id":"ritmo-curto","title":"Ritmo Curto","artist":"Banda Própria","file":"ritmo.mp3","duration_ms":20000,"license":"Autoria própria"}]}`
	if err := os.WriteFile(filepath.Join(cfg.MusicDir, "catalog.json"), []byte(catalog), 0o644); err != nil {
		t.Fatal(err)
	}

	clock := &fakeClock{t: t0}
	a, err := New(cfg, clock.Now)
	if err != nil {
		t.Fatal(err)
	}
	srv := httptest.NewServer(a.Handler)
	t.Cleanup(func() { srv.Close(); a.Close() })
	return &env{t: t, cfg: cfg, clock: clock, app: a, srv: srv}
}

// ---- requisições -------------------------------------------------------------

func (e *env) do(method, path, token string, body any) (int, map[string]any) {
	status, _, m := e.doHeaders(method, path, token, body)
	return status, m
}

func (e *env) doHeaders(method, path, token string, body any) (int, http.Header, map[string]any) {
	var rd io.Reader
	if body != nil {
		b, _ := json.Marshal(body)
		rd = bytes.NewReader(b)
	}
	req, _ := http.NewRequest(method, e.srv.URL+path, rd)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	return e.send(req)
}

func (e *env) send(req *http.Request) (int, http.Header, map[string]any) {
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		e.t.Errorf("%s %s: %v", req.Method, req.URL.Path, err)
		return 0, nil, nil
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	var m map[string]any
	_ = json.Unmarshal(raw, &m)
	return resp.StatusCode, resp.Header, m
}

func (e *env) getBytes(path, token string) (int, []byte, http.Header) {
	req, _ := http.NewRequest("GET", e.srv.URL+path, nil)
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		e.t.Errorf("GET %s: %v", path, err)
		return 0, nil, nil
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	return resp.StatusCode, raw, resp.Header
}

// publish envia multipart/form-data como o Flutter enviaria.
func (e *env) publish(token, key string, fields map[string]string, photo []byte) (int, http.Header, map[string]any) {
	var buf bytes.Buffer
	mw := multipart.NewWriter(&buf)
	for k, v := range fields {
		mw.WriteField(k, v)
	}
	if photo != nil {
		part, _ := mw.CreateFormFile("photo", "foto.jpg")
		part.Write(photo)
	}
	mw.Close()
	req, _ := http.NewRequest("POST", e.srv.URL+"/v1/stories", &buf)
	req.Header.Set("Content-Type", mw.FormDataContentType())
	req.Header.Set("Authorization", "Bearer "+token)
	if key != "" {
		req.Header.Set("Idempotency-Key", key)
	}
	return e.send(req)
}

// ---- atalhos de cenário ---------------------------------------------------------

func (e *env) register(name string) user {
	e.t.Helper()
	status, body := e.do("POST", "/v1/auth/register", "", map[string]string{
		"email": name + "@example.com", "display_name": name, "password": "senha-segura-123",
	})
	if status != 201 {
		e.t.Fatalf("register %s: status %d %v", name, status, body)
	}
	return user{id: str(body, "user", "id"), name: name, token: str(body, "session", "token")}
}

func (e *env) createGroup(owner user, name string) {
	e.t.Helper()
	if status, body := e.do("POST", "/v1/groups", owner.token, map[string]string{"name": name}); status != 201 {
		e.t.Fatalf("createGroup: %d %v", status, body)
	}
}

func (e *env) invite(from user) string {
	e.t.Helper()
	status, body := e.do("POST", "/v1/groups/me/invites", from.token, nil)
	if status != 201 {
		e.t.Fatalf("invite: %d %v", status, body)
	}
	return str(body, "invite", "code")
}

func (e *env) join(u user, code string) (int, map[string]any) {
	return e.do("POST", "/v1/groups/join", u.token, map[string]string{"code": code})
}

// newGroup cria uma roda com o dono e já entra com os demais.
func (e *env) newGroup(name string, owner user, others ...user) {
	e.t.Helper()
	e.createGroup(owner, name)
	for _, o := range others {
		if status, body := e.join(o, e.invite(owner)); status != 200 {
			e.t.Fatalf("join %s: %d %v", o.name, status, body)
		}
	}
}

func (e *env) post(u user, key string) string {
	e.t.Helper()
	status, _, body := e.publish(u.token, key, map[string]string{"caption": "treino de perna"}, jpegBytes(32, 32))
	if status != 201 {
		e.t.Fatalf("publish: %d %v", status, body)
	}
	return str(body, "story", "id")
}

func (e *env) feed(u user) (int, []any) {
	status, body := e.do("GET", "/v1/feed", u.token, nil)
	list, _ := body["stories"].([]any)
	return status, list
}

func (e *env) count(query string, args ...any) int {
	e.t.Helper()
	var n int
	if err := e.app.DB.QueryRow(query, args...).Scan(&n); err != nil {
		e.t.Fatal(err)
	}
	return n
}

func (e *env) photoFiles() []string {
	entries, _ := os.ReadDir(filepath.Join(e.cfg.MediaDir, "photos"))
	var names []string
	for _, en := range entries {
		names = append(names, en.Name())
	}
	return names
}

// ---- utilidades de dados --------------------------------------------------------

func dig(m map[string]any, path ...string) any {
	var cur any = m
	for _, p := range path {
		mm, ok := cur.(map[string]any)
		if !ok {
			return nil
		}
		cur = mm[p]
	}
	return cur
}

func str(m map[string]any, path ...string) string {
	s, _ := dig(m, path...).(string)
	return s
}

func errCode(m map[string]any) string { return str(m, "error", "code") }

func jpegBytes(w, h int) []byte {
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			img.Set(x, y, color.RGBA{uint8(x * 7), uint8(y * 5), 120, 255})
		}
	}
	var buf bytes.Buffer
	jpeg.Encode(&buf, img, &jpeg.Options{Quality: 80})
	return buf.Bytes()
}

func pngBytes(w, h int) []byte {
	img := image.NewNRGBA(image.Rect(0, 0, w, h))
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			img.Set(x, y, color.NRGBA{200, 30, 30, 128})
		}
	}
	var buf bytes.Buffer
	png.Encode(&buf, img)
	return buf.Bytes()
}

// jpegWithMetadata injeta um segmento EXIF (APP1) com um texto "secreto",
// simulando coordenadas de GPS de uma foto de celular.
func jpegWithMetadata(w, h int, secret string) []byte {
	plain := jpegBytes(w, h)
	payload := append([]byte("Exif\x00\x00"), []byte(secret)...)
	segLen := len(payload) + 2
	out := append([]byte{}, plain[:2]...) // SOI
	out = append(out, 0xFF, 0xE1, byte(segLen>>8), byte(segLen&0xFF))
	out = append(out, payload...)
	return append(out, plain[2:]...)
}

func containsBytes(file string, needle string) bool {
	b, err := os.ReadFile(file)
	return err == nil && strings.Contains(string(b), needle)
}

func keyN(prefix string, n int) string { return fmt.Sprintf("%s-%08d", prefix, n) }
