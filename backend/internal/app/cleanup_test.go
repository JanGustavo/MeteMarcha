package app

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestCleanupExpiresStoriesAndKeepsTracks(t *testing.T) {
	e := newEnv(t)
	a, b := e.register("a"), e.register("b")
	e.newGroup("Roda", a, b)

	// story 1 (com música e reação) em t0; story 2 cinquenta horas depois
	_, _, s1 := e.publish(a.token, "limpeza-0001", map[string]string{"track_id": "forca-total"}, jpegBytes(32, 32))
	id1 := str(s1, "story", "id")
	e.do("PUT", "/v1/stories/"+id1+"/reaction", b.token, map[string]string{"kind": "fire"})
	e.clock.Advance(50 * time.Hour)
	id2 := e.post(a, "limpeza-0002")

	// 72h + 1min depois do story 1: ele expirou; o 2 tem 22h e continua
	e.clock.Set(t0.Add(72*time.Hour + time.Minute))
	rep, err := e.app.Cleanup.RunOnce(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if rep.StoriesExpired != 1 || rep.PhotosDeleted != 1 {
		t.Errorf("relatório: %+v", rep)
	}
	if e.count(`SELECT COUNT(*) FROM stories WHERE id = ?`, id1) != 0 || e.count(`SELECT COUNT(*) FROM stories WHERE id = ?`, id2) != 1 {
		t.Error("só o story 1 deveria ter sido apagado")
	}
	if e.count(`SELECT COUNT(*) FROM reactions`) != 0 {
		t.Error("reações do story expirado deveriam ter sido apagadas")
	}
	if e.count(`SELECT COUNT(*) FROM media_files`) != 1 || len(e.photoFiles()) != 1 {
		t.Errorf("deveria sobrar só a foto do story 2: %d registros, %d arquivos", e.count(`SELECT COUNT(*) FROM media_files`), len(e.photoFiles()))
	}
	// músicas compartilhadas NÃO são apagadas junto
	if e.count(`SELECT COUNT(*) FROM tracks WHERE active = 1`) != 2 {
		t.Error("o catálogo de músicas não pode ser afetado pela limpeza")
	}
	if status, _, _ := e.getBytes("/v1/tracks/forca-total/audio", a.token); status != 200 {
		t.Errorf("áudio do catálogo deveria continuar disponível: %d", status)
	}
	if status, _, _ := e.getBytes("/v1/stories/"+id2+"/photo", b.token); status != 200 {
		t.Errorf("foto do story ainda válido deveria continuar: %d", status)
	}
	// uma segunda rodada logo em seguida não encontra mais nada
	rep, _ = e.app.Cleanup.RunOnce(context.Background())
	if rep.StoriesExpired != 0 || rep.PhotosDeleted != 0 {
		t.Errorf("rodada repetida deveria ser vazia: %+v", rep)
	}
}

// Falha ao apagar o arquivo: o registro fica, a tentativa é reagendada com
// espera crescente, e o trabalho continua mesmo depois de reiniciar o programa.
func TestCleanupRetriesFailedDeletion(t *testing.T) {
	e := newEnv(t)
	a := e.register("a")
	e.newGroup("Roda", a)
	e.post(a, "retry-0001")

	e.clock.Set(t0.Add(73 * time.Hour))
	calls := 0
	e.app.Cleanup.SetPhotoRemover(func(string) error { calls++; return errors.New("disco cheio de erros") })

	rep, err := e.app.Cleanup.RunOnce(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if rep.StoriesExpired != 1 || rep.PhotoFailures != 1 || rep.PhotosDeleted != 0 {
		t.Errorf("1ª rodada: %+v", rep)
	}
	if e.count(`SELECT COUNT(*) FROM media_files WHERE delete_attempts = 1 AND last_error IS NOT NULL AND next_attempt_at > ?`, e.clock.Now().Unix()) != 1 {
		t.Error("a falha deveria ficar registrada com próxima tentativa no futuro")
	}
	if len(e.photoFiles()) != 1 {
		t.Error("o arquivo ainda deve existir após a falha")
	}

	// Logo em seguida: ainda em espera, nem tenta de novo.
	e.app.Cleanup.RunOnce(context.Background())
	if calls != 1 {
		t.Errorf("tentou apagar %d vezes; deveria respeitar a espera (1)", calls)
	}

	// Ainda falhando depois da espera: a espera dobra.
	e.clock.Advance(2 * time.Minute)
	e.app.Cleanup.RunOnce(context.Background())
	if calls != 2 || e.count(`SELECT COUNT(*) FROM media_files WHERE delete_attempts = 2`) != 1 {
		t.Errorf("2ª tentativa: calls=%d", calls)
	}

	// "Reinício" do programa: novo App sobre o MESMO banco e pasta. O disco voltou
	// a funcionar. Nada ficou só na memória, então a limpeza conclui o serviço.
	e.clock.Advance(time.Hour)
	restarted, err := New(e.cfg, e.clock.Now)
	if err != nil {
		t.Fatal(err)
	}
	defer restarted.Close()
	rep, err = restarted.Cleanup.RunOnce(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if rep.PhotosDeleted != 1 || len(e.photoFiles()) != 0 || e.count(`SELECT COUNT(*) FROM media_files`) != 0 {
		t.Errorf("após o reinício: %+v, %d arquivos", rep, len(e.photoFiles()))
	}
}

func TestCleanupOrphanFiles(t *testing.T) {
	e := newEnv(t)
	a := e.register("a")
	e.newGroup("Roda", a)
	e.post(a, "orfao-0001") // foto em uso: nunca pode ser apagada
	e.clock.Advance(10 * time.Hour)
	now := e.clock.Now()

	photos := filepath.Join(e.cfg.MediaDir, "photos")
	tmp := filepath.Join(e.cfg.MediaDir, "tmp")
	write := func(dir, name string, age time.Duration) string {
		p := filepath.Join(dir, name)
		if err := os.WriteFile(p, []byte("restos"), 0o600); err != nil {
			t.Fatal(err)
		}
		if err := os.Chtimes(p, now.Add(-age), now.Add(-age)); err != nil {
			t.Fatal(err)
		}
		return p
	}
	oldOrphan := write(photos, "0123456789abcdef0123456789abcdef.jpg", 2*time.Hour)    // envio interrompido, antigo
	newOrphan := write(photos, "fedcba9876543210fedcba9876543210.jpg", 10*time.Minute) // pode estar em andamento
	oldTemp := write(tmp, "upload-antigo", 3*time.Hour)
	newTemp := write(tmp, "upload-recente", time.Minute)

	rep, err := e.app.Cleanup.RunOnce(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	exists := func(p string) bool { _, err := os.Stat(p); return err == nil }
	if exists(oldOrphan) || !exists(newOrphan) || exists(oldTemp) || !exists(newTemp) {
		t.Errorf("órfão antigo=%v novo=%v tmp antigo=%v tmp novo=%v (esperado: removido, mantido, removido, mantido)",
			exists(oldOrphan), exists(newOrphan), exists(oldTemp), exists(newTemp))
	}
	if rep.OrphanFilesDeleted != 1 || rep.TempFilesDeleted != 1 {
		t.Errorf("relatório: %+v", rep)
	}
	if len(e.photoFiles()) != 2 { // a foto em uso + o órfão recente
		t.Errorf("arquivos em photos: %v", e.photoFiles())
	}
	if e.count(`SELECT COUNT(*) FROM media_files`) != 1 {
		t.Error("a foto em uso deve continuar registrada")
	}
}

// Foto enviada mas que nunca virou story (celular perdeu a conexão antes do
// fim) é recolhida depois da carência, mesmo com registro no banco.
func TestCleanupUnreferencedMediaRow(t *testing.T) {
	e := newEnv(t)
	a := e.register("a")
	e.newGroup("Roda", a)
	if _, err := e.app.DB.Exec(`INSERT INTO media_files (id, owner_id, file_name, content_type, size_bytes, created_at)
		VALUES ('m1', ?, '0123456789abcdef0123456789abcdef.jpg', 'image/jpeg', 6, ?)`, a.id, e.clock.Now().Unix()); err != nil {
		t.Fatal(err)
	}
	p := filepath.Join(e.cfg.MediaDir, "photos", "0123456789abcdef0123456789abcdef.jpg")
	os.WriteFile(p, []byte("restos"), 0o600)

	// dentro da carência (1 h): preservada
	e.clock.Advance(30 * time.Minute)
	e.app.Cleanup.RunOnce(context.Background())
	if e.count(`SELECT COUNT(*) FROM media_files`) != 1 {
		t.Fatal("não pode apagar durante a carência")
	}
	e.clock.Advance(31 * time.Minute)
	rep, _ := e.app.Cleanup.RunOnce(context.Background())
	if rep.PhotosDeleted != 1 || e.count(`SELECT COUNT(*) FROM media_files`) != 0 {
		t.Errorf("depois da carência deveria apagar: %+v", rep)
	}
	if _, err := os.Stat(p); err == nil {
		t.Error("arquivo deveria ter sido removido")
	}
}

func TestCleanupPurgesOldSessionsAndInvites(t *testing.T) {
	e := newEnv(t)
	a := e.register("a")
	e.createGroup(a, "Roda")
	e.invite(a)
	e.clock.Advance(40 * 24 * time.Hour) // convite (7d) e sessão (30d) vencidos há mais de 1 dia
	rep, err := e.app.Cleanup.RunOnce(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if rep.SessionsDeleted != 1 || rep.InvitesDeleted != 1 {
		t.Errorf("relatório: %+v", rep)
	}
}
