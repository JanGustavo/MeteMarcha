package app

import (
	"bytes"
	"net/http"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

// Isolamento: uma roda nunca enxerga o conteúdo de outra.
func TestRoundIsolation(t *testing.T) {
	e := newEnv(t)
	a1, a2 := e.register("a1"), e.register("a2")
	b1 := e.register("b1")
	semRoda := e.register("sem-roda")
	e.newGroup("Roda A", a1, a2)
	e.newGroup("Roda B", b1)

	id := e.post(a1, keyN("iso", 1))

	if _, items := e.feed(a2); len(items) != 1 {
		t.Fatalf("participante da roda A deveria ver 1 story, viu %d", len(items))
	}
	if status, items := e.feed(b1); status != 200 || len(items) != 0 {
		t.Errorf("roda B não pode ver stories da roda A: %d %v", status, items)
	}
	if status, body := e.do("GET", "/v1/feed", semRoda.token, nil); status != 403 || errCode(body) != "not_in_group" {
		t.Errorf("sem roda: %d %v", status, body)
	}

	photo := "/v1/stories/" + id + "/photo"
	if status, raw, hdr := e.getBytes(photo, a2.token); status != 200 || hdr.Get("Content-Type") != "image/jpeg" || len(raw) < 100 {
		t.Errorf("participante deveria baixar a foto: %d %s", status, hdr.Get("Content-Type"))
	} else if hdr.Get("Cache-Control") != "private, no-store" {
		t.Errorf("Cache-Control = %q", hdr.Get("Cache-Control"))
	}
	// Range: o app pode pedir só um pedaço da foto
	rangeReq, _ := http.NewRequest("GET", e.srv.URL+photo, nil)
	rangeReq.Header.Set("Authorization", "Bearer "+a2.token)
	rangeReq.Header.Set("Range", "bytes=0-9")
	if resp, err := http.DefaultClient.Do(rangeReq); err != nil {
		t.Errorf("Range: %v", err)
	} else {
		resp.Body.Close()
		if resp.StatusCode != 206 || resp.ContentLength != 10 {
			t.Errorf("Range na foto: status %d, %d bytes", resp.StatusCode, resp.ContentLength)
		}
	}
	if status, _, _ := e.getBytes(photo, b1.token); status != 404 {
		t.Errorf("outra roda deveria receber 404, recebeu %d", status)
	}
	if status, _, _ := e.getBytes(photo, semRoda.token); status != 404 {
		t.Errorf("sem roda deveria receber 404, recebeu %d", status)
	}
	if status, _, _ := e.getBytes(photo, ""); status != 401 {
		t.Errorf("sem login deveria receber 401, recebeu %d", status)
	}
	if status, body := e.do("PUT", "/v1/stories/"+id+"/reaction", b1.token, map[string]string{"kind": "fire"}); status != 404 {
		t.Errorf("reagir de outra roda: %d %v", status, body)
	}
	// id inexistente e id de outra roda são indistinguíveis
	if status, _, _ := e.getBytes("/v1/stories/naoexiste/photo", a1.token); status != 404 {
		t.Errorf("id inexistente: %d", status)
	}
}

// As regras de 24 h / 72 h valem SEM a limpeza ter rodado.
func TestStoryTimeWindows(t *testing.T) {
	e := newEnv(t)
	autor, membro, fora := e.register("autor"), e.register("membro"), e.register("fora")
	e.newGroup("Roda", autor, membro)
	e.newGroup("Outra", fora)
	id := e.post(autor, keyN("janela", 1))
	photo := "/v1/stories/" + id + "/photo"

	cases := []struct {
		name         string
		age          time.Duration
		inFeed       bool
		member, auth int
	}{
		{"recém publicado", 0, true, 200, 200},
		{"23h59m59s", 24*time.Hour - time.Second, true, 200, 200},
		{"exatamente 24h", 24 * time.Hour, false, 404, 200},
		{"48h", 48 * time.Hour, false, 404, 200},
		{"71h59m59s", 72*time.Hour - time.Second, false, 404, 200},
		{"exatamente 72h", 72 * time.Hour, false, 404, 410},
		{"100h", 100 * time.Hour, false, 404, 410},
	}
	for _, c := range cases {
		e.clock.Set(t0.Add(c.age))
		if _, items := e.feed(membro); (len(items) == 1) != c.inFeed {
			t.Errorf("%s: feed do participante com %d itens (esperado visível=%v)", c.name, len(items), c.inFeed)
		}
		if _, items := e.feed(autor); (len(items) == 1) != c.inFeed {
			t.Errorf("%s: feed do autor com %d itens (esperado visível=%v)", c.name, len(items), c.inFeed)
		}
		if s, _, _ := e.getBytes(photo, membro.token); s != c.member {
			t.Errorf("%s: participante recebeu %d, esperado %d", c.name, s, c.member)
		}
		if s, _, _ := e.getBytes(photo, autor.token); s != c.auth {
			t.Errorf("%s: autor recebeu %d, esperado %d", c.name, s, c.auth)
		}
		if s, _, _ := e.getBytes(photo, fora.token); s != 404 {
			t.Errorf("%s: outra roda recebeu %d, esperado 404", c.name, s)
		}
	}

	// A limpeza NÃO rodou: o story e o arquivo ainda existem; só a autorização bloqueou.
	if e.count(`SELECT COUNT(*) FROM stories`) != 1 || len(e.photoFiles()) != 1 {
		t.Error("o teste deveria provar que a autorização não depende da limpeza")
	}
	// Corpo do 410 tem o código esperado pelo app
	if _, _, hdrBody := e.doHeaders("GET", photo, autor.token, nil); hdrBody == nil || errCode(hdrBody) != "story_expired" {
		t.Errorf("410 sem o código story_expired: %v", hdrBody)
	}

	// Reação só enquanto o story está no feed (primeiras 24 h)
	e.clock.Set(t0.Add(24 * time.Hour))
	if status, _ := e.do("PUT", "/v1/stories/"+id+"/reaction", membro.token, map[string]string{"kind": "fire"}); status != 404 {
		t.Errorf("reagir após 24h: %d", status)
	}
}

// "Participantes ATUAIS": quem sai perde o acesso; quem entra depois ganha.
func TestAccessFollowsCurrentMembership(t *testing.T) {
	e := newEnv(t)
	a, b := e.register("a"), e.register("b")
	e.newGroup("Roda", a, b)
	id := e.post(a, keyN("membros", 1))
	photo := "/v1/stories/" + id + "/photo"

	e.clock.Advance(time.Hour)
	if status, _ := e.do("POST", "/v1/groups/me/leave", b.token, nil); status != 204 {
		t.Fatalf("leave: %d", status)
	}
	if s, _, _ := e.getBytes(photo, b.token); s != 404 {
		t.Errorf("quem saiu deveria receber 404, recebeu %d", s)
	}
	if status, _ := e.do("GET", "/v1/feed", b.token, nil); status != 403 {
		t.Errorf("feed de quem saiu: %d", status)
	}

	c := e.register("c")
	if status, body := e.join(c, e.invite(a)); status != 200 {
		t.Fatalf("join: %d %v", status, body)
	}
	if _, items := e.feed(c); len(items) != 1 {
		t.Errorf("quem entrou depois vê os stories ainda válidos da roda; viu %d", len(items))
	}
	if s, _, _ := e.getBytes(photo, c.token); s != 200 {
		t.Errorf("novo participante deveria baixar a foto: %d", s)
	}
}

func TestPublishIdempotency(t *testing.T) {
	e := newEnv(t)
	u := e.register("ana")
	e.newGroup("Roda", u)

	fields := map[string]string{"caption": "braço"}
	s1, h1, b1 := e.publish(u.token, "chave-unica-01", fields, jpegBytes(32, 32))
	s2, h2, b2 := e.publish(u.token, "chave-unica-01", fields, jpegBytes(32, 32))
	if s1 != 201 || s2 != 200 {
		t.Fatalf("status %d e %d; esperado 201 e 200", s1, s2)
	}
	if str(b1, "story", "id") == "" || str(b1, "story", "id") != str(b2, "story", "id") {
		t.Errorf("a repetição deve devolver o MESMO story: %v / %v", b1, b2)
	}
	if h1.Get("Idempotent-Replayed") != "" || h2.Get("Idempotent-Replayed") != "true" {
		t.Errorf("cabeçalho Idempotent-Replayed: %q / %q", h1.Get("Idempotent-Replayed"), h2.Get("Idempotent-Replayed"))
	}
	if n := e.count(`SELECT COUNT(*) FROM stories`); n != 1 {
		t.Errorf("%d stories; esperado 1", n)
	}
	if n := e.count(`SELECT COUNT(*) FROM media_files`); n != 1 || len(e.photoFiles()) != 1 {
		t.Errorf("a repetição não pode deixar fotos extras: %d registros, %d arquivos", n, len(e.photoFiles()))
	}

	// chave diferente = publicação nova
	if s, _, _ := e.publish(u.token, "chave-unica-02", fields, jpegBytes(32, 32)); s != 201 {
		t.Errorf("chave nova: %d", s)
	}
	// a mesma chave por OUTRA pessoa é outra publicação
	v := e.register("bia")
	e.join(v, e.invite(u))
	if s, _, _ := e.publish(v.token, "chave-unica-01", fields, jpegBytes(32, 32)); s != 201 {
		t.Errorf("mesma chave, outro autor: %d", s)
	}

	// chave ausente ou inválida
	if s, _, b := e.publish(u.token, "", fields, jpegBytes(32, 32)); s != 400 || errCode(b) != "invalid_idempotency_key" {
		t.Errorf("sem chave: %d %v", s, b)
	}
	if s, _, b := e.publish(u.token, "curta", fields, jpegBytes(32, 32)); s != 400 || errCode(b) != "invalid_idempotency_key" {
		t.Errorf("chave curta: %d %v", s, b)
	}
}

// Cinco requisições idênticas ao mesmo tempo (o celular insistindo) = um story só.
func TestPublishIdempotencyConcurrent(t *testing.T) {
	e := newEnv(t)
	u := e.register("ana")
	e.newGroup("Roda", u)

	const n = 5
	ids := make([]string, n)
	statuses := make([]int, n)
	start := make(chan struct{})
	var wg sync.WaitGroup
	for i := 0; i < n; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			<-start
			s, _, b := e.publish(u.token, "chave-concorrente", map[string]string{"caption": "x"}, jpegBytes(32, 32))
			statuses[i], ids[i] = s, str(b, "story", "id")
		}()
	}
	close(start)
	wg.Wait()

	created := 0
	for i := range ids {
		if statuses[i] == 201 {
			created++
		} else if statuses[i] != 200 {
			t.Errorf("status inesperado: %d", statuses[i])
		}
		if ids[i] != ids[0] || ids[i] == "" {
			t.Errorf("ids diferentes: %v", ids)
		}
	}
	if created != 1 {
		t.Errorf("%d respostas 201; esperado exatamente 1", created)
	}
	if e.count(`SELECT COUNT(*) FROM stories`) != 1 || len(e.photoFiles()) != 1 || e.count(`SELECT COUNT(*) FROM media_files`) != 1 {
		t.Errorf("sobraram duplicatas: %d stories, %d arquivos, %d registros de mídia",
			e.count(`SELECT COUNT(*) FROM stories`), len(e.photoFiles()), e.count(`SELECT COUNT(*) FROM media_files`))
	}
}

func TestUploadValidation(t *testing.T) {
	e := newEnv(t, func(c *platform.Config) {
		c.MaxPhotoBytes = 20_000
		c.MaxPhotoSide = 64
	})
	u := e.register("ana")
	e.newGroup("Roda", u)
	key := 0
	try := func(photo []byte) (int, map[string]any) {
		key++
		s, _, b := e.publish(u.token, keyN("up", key), nil, photo)
		return s, b
	}

	if s, b := try([]byte("isto é texto, não uma imagem")); s != 415 || errCode(b) != "unsupported_photo_type" {
		t.Errorf("texto: %d %v", s, b)
	}
	// nome .jpg e Content-Type de imagem não enganam: o conteúdo manda
	if s, b := try([]byte("<html><script>alert(1)</script></html>")); s != 415 {
		t.Errorf("html disfarçado: %d %v", s, b)
	}
	if s, b := try(bytes.Repeat([]byte{0xFF, 0xD8, 0xFF}, 10_000)); s != 413 || errCode(b) != "photo_too_large" {
		t.Errorf("grande demais: %d %v", s, b)
	}
	if s, b := try(jpegBytes(100, 100)); s != 422 || errCode(b) != "invalid_photo" {
		t.Errorf("dimensões acima do limite: %d %v", s, b)
	}
	truncated := jpegBytes(32, 32)
	if s, b := try(truncated[:len(truncated)/2]); s != 422 || errCode(b) != "invalid_photo" {
		t.Errorf("JPEG truncado: %d %v", s, b)
	}
	if s, _, b := e.publish(u.token, "sem-foto-0001", map[string]string{"caption": "x"}, nil); s != 400 || errCode(b) != "photo_required" {
		t.Errorf("sem foto: %d %v", s, b)
	}
	if s, _, b := e.publish(u.token, "legenda-grande", map[string]string{"caption": string(bytes.Repeat([]byte("a"), 301))}, jpegBytes(32, 32)); s != 422 || errCode(b) != "invalid_caption" {
		t.Errorf("legenda grande: %d %v", s, b)
	}
	// nenhuma tentativa recusada pode deixar rastro
	if len(e.photoFiles()) != 0 || e.count(`SELECT COUNT(*) FROM media_files`) != 0 || e.count(`SELECT COUNT(*) FROM stories`) != 0 {
		t.Errorf("uploads recusados deixaram rastro: %v", e.photoFiles())
	}

	// PNG é aceito e armazenado como JPEG
	s, _, b := e.publish(u.token, "png-valido-01", nil, pngBytes(32, 32))
	if s != 201 {
		t.Fatalf("PNG: %d %v", s, b)
	}
	_, raw, hdr := e.getBytes(str(b, "story", "photo_url"), u.token)
	if hdr.Get("Content-Type") != "image/jpeg" || len(raw) < 3 || raw[0] != 0xFF || raw[1] != 0xD8 {
		t.Errorf("PNG deveria virar JPEG; Content-Type=%q", hdr.Get("Content-Type"))
	}

	// Metadados (EXIF/GPS) são removidos
	const secret = "GPS-LAT-9.999-LON-8.888"
	s, _, b = e.publish(u.token, "exif-valido-01", nil, jpegWithMetadata(32, 32, secret))
	if s != 201 {
		t.Fatalf("JPEG com EXIF: %d %v", s, b)
	}
	for _, name := range e.photoFiles() {
		if containsBytes(filepath.Join(e.cfg.MediaDir, "photos", name), secret) {
			t.Error("o EXIF com a localização continua no arquivo guardado")
		}
	}
	// Nomes no disco são gerados pelo servidor: 32 hex + .jpg
	for _, name := range e.photoFiles() {
		if len(name) != 36 || name[32:] != ".jpg" {
			t.Errorf("nome de arquivo inesperado: %q", name)
		}
	}

	// Corpo que não é multipart
	jsonReq, _ := http.NewRequest("POST", e.srv.URL+"/v1/stories", strings.NewReader(`{"caption":"x"}`))
	jsonReq.Header.Set("Content-Type", "application/json")
	jsonReq.Header.Set("Authorization", "Bearer "+u.token)
	jsonReq.Header.Set("Idempotency-Key", "nao-multipart-01")
	if s, _, b := e.send(jsonReq); s != 400 || errCode(b) != "invalid_multipart" {
		t.Errorf("corpo JSON em vez de multipart: %d %v", s, b)
	}

	// Corpo gigante é cortado antes de ser lido por inteiro
	big := bytes.Repeat([]byte("a"), 2<<20)
	if s, _, b := e.publish(u.token, "corpo-gigante-1", nil, big); s != 413 || errCode(b) != "request_too_large" {
		t.Errorf("corpo gigante: %d %v", s, b)
	}
}

func TestReactions(t *testing.T) {
	e := newEnv(t)
	a, b := e.register("a"), e.register("b")
	e.newGroup("Roda", a, b)
	id := e.post(a, keyN("react", 1))
	path := "/v1/stories/" + id + "/reaction"

	status, body := e.do("PUT", path, b.token, map[string]string{"kind": "fire"})
	if status != 200 || dig(body, "reactions", "mine") != "fire" || dig(body, "reactions", "counts", "fire") != float64(1) {
		t.Fatalf("reagir: %d %v", status, body)
	}
	// repetir a mesma reação não duplica
	e.do("PUT", path, b.token, map[string]string{"kind": "fire"})
	// trocar substitui (não soma)
	status, body = e.do("PUT", path, b.token, map[string]string{"kind": "clap"})
	if status != 200 || dig(body, "reactions", "mine") != "clap" || dig(body, "reactions", "counts", "clap") != float64(1) || dig(body, "reactions", "counts", "fire") != nil {
		t.Errorf("trocar: %d %v", status, body)
	}
	// outra pessoa reage; o autor vê a contagem e a própria reação nula
	e.do("PUT", path, a.token, map[string]string{"kind": "clap"})
	_, items := e.feed(a)
	first := items[0].(map[string]any)
	if dig(first, "reactions", "counts", "clap") != float64(2) || dig(first, "reactions", "mine") != "clap" {
		t.Errorf("feed do autor: %v", first["reactions"])
	}
	// banco: uma linha por pessoa por story
	if n := e.count(`SELECT COUNT(*) FROM reactions`); n != 2 {
		t.Errorf("%d linhas em reactions; esperado 2", n)
	}

	if status, body := e.do("PUT", path, b.token, map[string]string{"kind": "💥"}); status != 422 || errCode(body) != "invalid_reaction" {
		t.Errorf("reação inválida: %d %v", status, body)
	}

	// remover (e remover de novo é seguro)
	for i := 0; i < 2; i++ {
		status, body = e.do("DELETE", path, b.token, nil)
		if status != 200 || dig(body, "reactions", "mine") != nil || dig(body, "reactions", "counts", "clap") != float64(1) {
			t.Errorf("remover #%d: %d %v", i+1, status, body)
		}
	}
	if status, _ := e.do("PUT", "/v1/stories/inexistente/reaction", b.token, map[string]string{"kind": "fire"}); status != 404 {
		t.Errorf("story inexistente: %d", status)
	}
}

func TestTracks(t *testing.T) {
	e := newEnv(t)
	u := e.register("ana")
	e.newGroup("Roda", u)

	if status, _ := e.do("GET", "/v1/tracks", "", nil); status != 401 {
		t.Errorf("catálogo sem login: %d", status)
	}
	if status, _, _ := (func() (int, []byte, http.Header) { return e.getBytes("/v1/tracks/forca-total/audio", "") })(); status != 401 {
		t.Errorf("áudio sem login: %d", status)
	}
	status, body := e.do("GET", "/v1/tracks", u.token, nil)
	if tracks, _ := body["tracks"].([]any); status != 200 || len(tracks) != 2 {
		t.Fatalf("catálogo: %d %v", status, body)
	}

	// áudio com suporte a Range (o app pode pular para o instante inicial)
	req, _ := http.NewRequest("GET", e.srv.URL+"/v1/tracks/forca-total/audio", nil)
	req.Header.Set("Authorization", "Bearer "+u.token)
	req.Header.Set("Range", "bytes=0-9")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()
	if resp.StatusCode != 206 || resp.Header.Get("Content-Type") != "audio/mpeg" {
		t.Errorf("Range: %d %q", resp.StatusCode, resp.Header.Get("Content-Type"))
	}

	// publicar com faixa: trecho padrão = começo, até o limite de 30 s
	s, _, b := e.publish(u.token, "faixa-valida-01", map[string]string{"track_id": "forca-total"}, jpegBytes(32, 32))
	if s != 201 || dig(b, "story", "track", "start_ms") != float64(0) || dig(b, "story", "track", "duration_ms") != float64(30000) || str(b, "story", "track", "audio_url") != "/v1/tracks/forca-total/audio" {
		t.Errorf("trecho padrão: %d %v", s, b)
	}
	// trecho explícito
	s, _, b = e.publish(u.token, "faixa-valida-02", map[string]string{"track_id": "forca-total", "track_start_ms": "45000", "track_duration_ms": "15000"}, jpegBytes(32, 32))
	if s != 201 || dig(b, "story", "track", "start_ms") != float64(45000) {
		t.Errorf("trecho explícito: %d %v", s, b)
	}
	// sem faixa: track é null
	s, _, b = e.publish(u.token, "sem-faixa-0001", nil, jpegBytes(32, 32))
	if s != 201 || dig(b, "story", "track") != nil {
		t.Errorf("sem faixa: %d %v", s, b)
	}

	invalid := []struct {
		name   string
		fields map[string]string
	}{
		{"faixa inexistente", map[string]string{"track_id": "nao-existe"}},
		{"começo fora da faixa", map[string]string{"track_id": "ritmo-curto", "track_start_ms": "20000"}},
		{"trecho passa do fim", map[string]string{"track_id": "ritmo-curto", "track_start_ms": "15000", "track_duration_ms": "10000"}},
		{"trecho maior que o máximo", map[string]string{"track_id": "forca-total", "track_duration_ms": "31000"}},
		{"duração zero", map[string]string{"track_id": "forca-total", "track_duration_ms": "0"}},
		{"início negativo", map[string]string{"track_id": "forca-total", "track_start_ms": "-1"}},
		{"trecho sem faixa", map[string]string{"track_start_ms": "1000"}},
	}
	for i, c := range invalid {
		if s, _, b := e.publish(u.token, keyN("inv", i), c.fields, jpegBytes(32, 32)); s != 422 || errCode(b) != "invalid_track" {
			t.Errorf("%s: %d %v", c.name, s, b)
		}
	}
	if s, _, b := e.publish(u.token, "numero-ruim-01", map[string]string{"track_id": "forca-total", "track_start_ms": "abc"}, jpegBytes(32, 32)); s != 400 || errCode(b) != "invalid_field" {
		t.Errorf("número inválido: %d %v", s, b)
	}
}

func TestFeedPagination(t *testing.T) {
	e := newEnv(t)
	u := e.register("ana")
	e.newGroup("Roda", u)
	var ids []string
	for i := 0; i < 5; i++ {
		ids = append(ids, e.post(u, keyN("pag", i)))
	}

	status, body := e.do("GET", "/v1/feed?limit=2", u.token, nil)
	page1, _ := body["stories"].([]any)
	if status != 200 || len(page1) != 2 || str(page1[0].(map[string]any), "id") != ids[4] {
		t.Fatalf("página 1: %d %v", status, body)
	}
	cursor := str(body, "next_cursor")
	_, body = e.do("GET", "/v1/feed?limit=2&before="+cursor, u.token, nil)
	page2, _ := body["stories"].([]any)
	if len(page2) != 2 || str(page2[0].(map[string]any), "id") != ids[2] {
		t.Fatalf("página 2: %v", body)
	}
	_, body = e.do("GET", "/v1/feed?limit=2&before="+str(body, "next_cursor"), u.token, nil)
	page3, _ := body["stories"].([]any)
	if len(page3) != 1 || body["next_cursor"] != nil {
		t.Errorf("página 3 deveria ter 1 item e terminar: %v", body)
	}
	if s, b := e.do("GET", "/v1/feed?limit=0", u.token, nil); s != 400 || errCode(b) != "invalid_limit" {
		t.Errorf("limit inválido: %d %v", s, b)
	}
	if s, b := e.do("GET", "/v1/feed?before=abc", u.token, nil); s != 400 || errCode(b) != "invalid_cursor" {
		t.Errorf("cursor inválido: %d %v", s, b)
	}
}

func TestWorkoutReportSnapshotInFeed(t *testing.T) {
	e := newEnv(t)
	a, b := e.register("reporta"), e.register("reportb")
	outsider := e.register("reportoutside")
	e.newGroup("Reports", a, b)
	e.newGroup("Other", outsider)
	raw := `{"version":1,"title":"Treino A","date":"2026-11-20","duration_seconds":60,"sets":[{"exercise":"Supino","number":1,"weight_kg":20,"reps":10,"side":"ambos","completed":true,"equipment":"barra","notes":"","at":"2026-11-20"}]}`
	status, _, body := e.publish(a.token, keyN("report", 1), map[string]string{"workout_report": raw}, jpegBytes(20, 20))
	if status != 201 {
		t.Fatalf("publish: %d %v", status, body)
	}
	_, items := e.feed(b)
	if len(items) != 1 {
		t.Fatal(items)
	}
	report := items[0].(map[string]any)["workout_report"].(map[string]any)
	if report["title"] != "Treino A" || len(report["sets"].([]any)) != 1 {
		t.Fatal(report)
	}
	_, outside := e.feed(outsider)
	if len(outside) != 0 {
		t.Fatal("report leaked")
	}
	e.clock.Advance(25 * time.Hour)
	_, items = e.feed(b)
	if len(items) != 0 {
		t.Fatal("expired report in feed")
	}
}

func TestSecondStoryDoesNotReplaceFirst(t *testing.T) {
	e := newEnv(t)
	author, viewer := e.register("listauthor"), e.register("listviewer")
	e.newGroup("Publicações", author, viewer)
	_, _, first := e.publish(author.token, keyN("separate", 1), map[string]string{"caption": "Primeiro"}, jpegBytes(20, 20))
	firstID := str(first, "story", "id")
	_, before, _ := e.getBytes("/v1/stories/"+firstID+"/photo", viewer.token)
	status, _, second := e.publish(author.token, keyN("separate", 2), map[string]string{"caption": "Segundo"}, jpegBytes(30, 30))
	if status != 201 || str(second, "story", "id") == firstID {
		t.Fatalf("second not created: %d %v", status, second)
	}
	_, items := e.feed(viewer)
	if len(items) != 2 {
		t.Fatalf("wanted 2 separate posts, got %d", len(items))
	}
	_, after, _ := e.getBytes("/v1/stories/"+firstID+"/photo", viewer.token)
	if !bytes.Equal(before, after) {
		t.Fatal("first story photo was overwritten")
	}
}

func TestStoryVideoLink(t *testing.T) {
	e := newEnv(t)
	owner, member := e.register("videoowner"), e.register("videomember")
	e.newGroup("Vídeos", owner, member)
	link := "https://www.youtube.com/watch?v=jNo3GqP-d4I"
	status, _, body := e.publish(owner.token, keyN("video", 1), map[string]string{"video_url": link}, jpegBytes(20, 20))
	if status != 201 || str(body, "story", "video_url") != link {
		t.Fatalf("video: %d %v", status, body)
	}
	_, items := e.feed(member)
	if len(items) != 1 || items[0].(map[string]any)["video_url"] != link {
		t.Fatal("video not shared with member")
	}
	for i, link := range []string{"javascript:alert(1)", "https://youtube.com.attacker.test/watch?v=x", "https://example.com/video"} {
		if status, _, _ := e.publish(owner.token, keyN("invalid-video", i), map[string]string{"video_url": link}, jpegBytes(20, 20)); status != 422 {
			t.Fatal("invalid video accepted", status)
		}
	}
}
