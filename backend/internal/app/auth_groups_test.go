package app

import (
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

func TestAuthFlow(t *testing.T) {
	e := newEnv(t)
	u := e.register("ana")

	if status, body := e.do("GET", "/v1/me", u.token, nil); status != 200 || str(body, "user", "email") != "ana@example.com" {
		t.Fatalf("me: %d %v", status, body)
	}

	// e-mail repetido (maiúsculas não enganam), senha curta, e-mail inválido
	if status, body := e.do("POST", "/v1/auth/register", "", map[string]string{"email": "ANA@example.com", "display_name": "x", "password": "senha-segura-123"}); status != 409 || errCode(body) != "email_taken" {
		t.Errorf("e-mail repetido: %d %v", status, body)
	}
	if status, body := e.do("POST", "/v1/auth/register", "", map[string]string{"email": "b@example.com", "display_name": "b", "password": "curta"}); status != 422 || errCode(body) != "invalid_password" {
		t.Errorf("senha curta: %d %v", status, body)
	}
	if status, body := e.do("POST", "/v1/auth/register", "", map[string]string{"email": "nao-e-email", "display_name": "b", "password": "senha-segura-123"}); status != 422 || errCode(body) != "invalid_email" {
		t.Errorf("e-mail inválido: %d %v", status, body)
	}

	// login: senha errada e e-mail inexistente dão a MESMA resposta
	s1, b1 := e.do("POST", "/v1/auth/login", "", map[string]string{"email": "ana@example.com", "password": "errada-errada"})
	s2, b2 := e.do("POST", "/v1/auth/login", "", map[string]string{"email": "ninguem@example.com", "password": "errada-errada"})
	if s1 != 401 || s2 != 401 || errCode(b1) != "invalid_credentials" || errCode(b2) != "invalid_credentials" {
		t.Errorf("login inválido: %d %v / %d %v", s1, b1, s2, b2)
	}

	status, body := e.do("POST", "/v1/auth/login", "", map[string]string{"email": "ana@example.com", "password": "senha-segura-123"})
	if status != 200 {
		t.Fatalf("login: %d %v", status, body)
	}
	second := str(body, "session", "token")
	if second == u.token {
		t.Error("cada login deve gerar um token novo")
	}

	// sem token / token inventado
	if status, body := e.do("GET", "/v1/me", "", nil); status != 401 || errCode(body) != "unauthorized" {
		t.Errorf("sem token: %d %v", status, body)
	}
	if status, _ := e.do("GET", "/v1/me", "token-inventado", nil); status != 401 {
		t.Errorf("token inventado: %d", status)
	}

	// logout revoga só a sessão usada
	if status, _ := e.do("POST", "/v1/auth/logout", second, nil); status != 204 {
		t.Errorf("logout: %d", status)
	}
	if status, _ := e.do("GET", "/v1/me", second, nil); status != 401 {
		t.Errorf("sessão revogada ainda funciona: %d", status)
	}
	if status, _ := e.do("GET", "/v1/me", u.token, nil); status != 200 {
		t.Errorf("a outra sessão deveria continuar válida: %d", status)
	}

	// o banco guarda hash, nunca o token nem a senha
	if n := e.count(`SELECT COUNT(*) FROM sessions WHERE token_hash = ?`, u.token); n != 0 {
		t.Error("token puro encontrado no banco")
	}
	if n := e.count(`SELECT COUNT(*) FROM users WHERE password_hash LIKE '$argon2id$%'`); n != 1 {
		t.Errorf("hash argon2id esperado, achei %d", n)
	}

	// sessão expira com o tempo (30 dias por padrão)
	e.clock.Advance(31 * 24 * time.Hour)
	if status, _ := e.do("GET", "/v1/me", u.token, nil); status != 401 {
		t.Errorf("sessão expirada ainda funciona: %d", status)
	}
}

func TestGroupRules(t *testing.T) {
	e := newEnv(t)
	owner, bia, caio := e.register("dona"), e.register("bia"), e.register("caio")

	// sem roda ainda
	if status, body := e.do("GET", "/v1/groups/me", owner.token, nil); status != 403 || errCode(body) != "not_in_group" {
		t.Errorf("sem roda: %d %v", status, body)
	}
	if status, body := e.do("POST", "/v1/groups/me/invites", owner.token, nil); status != 403 {
		t.Errorf("convite sem roda: %d %v", status, body)
	}

	e.createGroup(owner, "Roda da Perna")
	if status, body := e.do("POST", "/v1/groups", owner.token, map[string]string{"name": "Outra"}); status != 409 || errCode(body) != "already_in_group" {
		t.Errorf("segunda roda: %d %v", status, body)
	}

	code := e.invite(owner)
	// código aceita minúsculas e sem hífen
	if status, body := e.join(bia, lowerNoDash(code)); status != 200 {
		t.Fatalf("join com código normalizado: %d %v", status, body)
	}
	// convite é de uso único
	if status, body := e.join(caio, code); status != 404 || errCode(body) != "invite_invalid" {
		t.Errorf("convite reutilizado: %d %v", status, body)
	}
	// código inventado dá a mesma resposta
	if status, body := e.join(caio, "AAAAA-AAAAA"); status != 404 || errCode(body) != "invite_invalid" {
		t.Errorf("convite inexistente: %d %v", status, body)
	}
	// quem já está numa roda não entra em outra
	e.newGroup("Outra roda", caio)
	if status, body := e.join(caio, e.invite(owner)); status != 409 || errCode(body) != "already_in_group" {
		t.Errorf("entrar já estando em roda: %d %v", status, body)
	}

	// convite expira
	old := e.invite(owner)
	e.clock.Advance(8 * 24 * time.Hour)
	d := e.register("duda")
	if status, body := e.join(d, old); status != 404 || errCode(body) != "invite_invalid" {
		t.Errorf("convite expirado: %d %v", status, body)
	}

	// sair: dona sai → participante mais antigo vira dona
	if status, _ := e.do("POST", "/v1/groups/me/leave", owner.token, nil); status != 204 {
		t.Fatalf("leave: %d", status)
	}
	status, body := e.do("GET", "/v1/groups/me", bia.token, nil)
	members, _ := body["members"].([]any)
	if status != 200 || len(members) != 1 || str(members[0].(map[string]any), "role") != "owner" {
		t.Errorf("sucessão de dona: %d %v", status, body)
	}
	if status, body := e.do("POST", "/v1/groups/me/leave", owner.token, nil); status != 403 {
		t.Errorf("sair sem estar em roda: %d %v", status, body)
	}
	// a ex-dona pode entrar em outra roda depois de sair
	if status, body := e.join(owner, e.invite(caio)); status != 200 {
		t.Errorf("entrar em outra roda após sair: %d %v", status, body)
	}
}

func lowerNoDash(s string) string {
	out := []byte{}
	for _, c := range []byte(s) {
		if c == '-' {
			continue
		}
		if c >= 'A' && c <= 'Z' {
			c += 'a' - 'A'
		}
		out = append(out, c)
	}
	return string(out)
}

// O limite de participantes vale mesmo quando várias pessoas entram AO MESMO TEMPO.
func TestGroupLimitUnderConcurrency(t *testing.T) {
	e := newEnv(t, func(c *platform.Config) { c.GroupMaxMembers = 3 })
	owner := e.register("dono")
	e.createGroup(owner, "Roda pequena")

	const n = 60 // muita disputa pela mesma vaga
	users := make([]user, n)
	codes := make([]string, n)
	for i := range users {
		users[i] = e.register(fmt.Sprintf("u%d", i))
		codes[i] = e.invite(owner)
	}

	statuses := make([]int, n)
	start := make(chan struct{})
	var wg sync.WaitGroup
	for i := range users {
		wg.Add(1)
		go func() {
			defer wg.Done()
			<-start
			s, body := e.join(users[i], codes[i])
			statuses[i] = s
			if s == 409 && errCode(body) != "group_full" {
				t.Errorf("409 inesperado: %v", body)
			}
		}()
	}
	close(start)
	wg.Wait()

	ok := 0
	for _, s := range statuses {
		if s == 200 {
			ok++
		} else if s != 409 {
			t.Errorf("status inesperado %d", s)
		}
	}
	if ok != 2 { // dono + 2 = 3 participantes
		t.Errorf("entraram %d pessoas; esperado 2 (limite 3 com o dono)", ok)
	}
	if n := e.count(`SELECT COUNT(*) FROM group_members`); n != 3 {
		t.Errorf("group_members tem %d linhas; esperado 3", n)
	}
	// convites de quem não entrou NÃO foram consumidos
	if n := e.count(`SELECT COUNT(*) FROM group_invites WHERE used_at IS NOT NULL`); n != 2 {
		t.Errorf("convites usados: %d; esperado 2", n)
	}
}

func TestSameInviteUsedConcurrently(t *testing.T) {
	e := newEnv(t)
	owner := e.register("dono")
	e.createGroup(owner, "Roda")
	code := e.invite(owner)
	a, b := e.register("a"), e.register("b")

	statuses := make([]int, 2)
	start := make(chan struct{})
	var wg sync.WaitGroup
	for i, u := range []user{a, b} {
		wg.Add(1)
		go func() {
			defer wg.Done()
			<-start
			statuses[i], _ = e.join(u, code)
		}()
	}
	close(start)
	wg.Wait()
	if !(statuses[0] == 200 && statuses[1] == 404 || statuses[0] == 404 && statuses[1] == 200) {
		t.Errorf("um convite só pode ser usado uma vez: %v", statuses)
	}
}

func TestCatalogInvalidStopsStartup(t *testing.T) {
	dir := t.TempDir()
	cfg := platform.DefaultConfig()
	cfg.DBPath = filepath.Join(dir, "t.db")
	cfg.MediaDir = filepath.Join(dir, "m")
	cfg.MusicDir = filepath.Join(dir, "music")
	cfg.PasswordMemoryKiB = 1024
	os.MkdirAll(cfg.MusicDir, 0o755)
	// sem license, arquivo inexistente e tentativa de sair da pasta
	bad := `{"tracks":[{"id":"x","title":"T","artist":"A","file":"../segredo.mp3","duration_ms":1000,"license":""}]}`
	os.WriteFile(filepath.Join(cfg.MusicDir, "catalog.json"), []byte(bad), 0o644)

	if a, err := New(cfg, platform.SystemClock); err == nil {
		a.Close()
		t.Fatal("catálogo inválido deveria impedir o início")
	}
}
