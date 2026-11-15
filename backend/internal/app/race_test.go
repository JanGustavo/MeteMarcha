package app

import (
	"bytes"
	"context"
	"io"
	"sync"
	"testing"

	"github.com/JanGustavo/MeteMarcha/backend/internal/groups"
	"github.com/JanGustavo/MeteMarcha/backend/internal/media"
	"github.com/JanGustavo/MeteMarcha/backend/internal/stories"
)

// hookReader executa uma função na primeira leitura. A foto só é lida DEPOIS da
// pré-checagem de repetição, então isso nos deixa encaixar uma publicação
// "vencedora" exatamente entre a checagem e o INSERT da "perdedora": a corrida
// acontece sempre, sem depender de sorte de tempo.
type hookReader struct {
	once   sync.Once
	onRead func()
	r      io.Reader
}

func (h *hookReader) Read(p []byte) (int, error) {
	h.once.Do(h.onRead)
	return h.r.Read(p)
}

func TestPublishLosingTheRaceReturnsOriginalAndDiscardsPhoto(t *testing.T) {
	e := newEnv(t)
	u := e.register("ana")
	e.newGroup("Roda", u)

	storage, err := media.NewStorage(e.cfg.MediaDir)
	if err != nil {
		t.Fatal(err)
	}
	svc := stories.NewService(e.app.DB, e.cfg, e.clock.Now, groups.NewService(e.app.DB, e.cfg, e.clock.Now), media.NewService(e.app.DB, storage, e.cfg, e.clock.Now))

	ctx := context.Background()
	const key = "corrida-0001"
	var winner stories.Story
	var winnerCreated bool
	loserPhoto := &hookReader{r: bytes.NewReader(jpegBytes(32, 32))}
	loserPhoto.onRead = func() {
		var err error
		winner, winnerCreated, err = svc.Publish(ctx, stories.PublishInput{
			AuthorID: u.id, RequestID: key, Caption: "vencedora", Photo: bytes.NewReader(jpegBytes(32, 32)),
		})
		if err != nil {
			t.Errorf("publicação vencedora: %v", err)
		}
	}

	loser, created, err := svc.Publish(ctx, stories.PublishInput{AuthorID: u.id, RequestID: key, Caption: "perdedora", Photo: loserPhoto})
	if err != nil {
		t.Fatalf("a perdedora deveria receber o story original, não erro: %v", err)
	}
	if !winnerCreated || created {
		t.Errorf("vencedora criou=%v, perdedora criou=%v (esperado true/false)", winnerCreated, created)
	}
	if loser.ID != winner.ID || loser.Caption != "vencedora" {
		t.Errorf("a perdedora deve devolver o story da vencedora: %+v", loser)
	}
	if e.count(`SELECT COUNT(*) FROM stories`) != 1 || e.count(`SELECT COUNT(*) FROM media_files`) != 1 || len(e.photoFiles()) != 1 {
		t.Errorf("a foto da perdedora deveria ter sido descartada: %d stories, %d registros, %d arquivos",
			e.count(`SELECT COUNT(*) FROM stories`), e.count(`SELECT COUNT(*) FROM media_files`), len(e.photoFiles()))
	}
}
