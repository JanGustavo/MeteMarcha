// Package cleanup apaga o que expirou: stories com mais de 72 h, suas fotos,
// arquivos órfãos de envios interrompidos e sessões/convites vencidos.
//
// A limpeza roda dentro do próprio programa, em intervalos. Todo o estado
// necessário fica no banco e no disco (nada só em memória), então reiniciar o
// programa no meio não perde nada: a próxima rodada continua de onde parou.
package cleanup

import (
	"context"
	"database/sql"
	"errors"
	"log/slog"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/media"
	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

const (
	batchSize    = 100
	retryBase    = time.Minute
	retryCeiling = 6 * time.Hour
	authGrace    = 24 * time.Hour
)

// Report resume uma rodada (usado em log e nos testes).
type Report struct {
	StoriesExpired     int64
	PhotosDeleted      int
	PhotoFailures      int
	OrphanFilesDeleted int
	TempFilesDeleted   int
	SessionsDeleted    int64
	InvitesDeleted     int64
}

type Runner struct {
	store     *Store
	storage   *media.Storage
	now       platform.Clock
	log       *slog.Logger
	retention time.Duration // StoryRecoverableFor: depois disso o story deixa de existir
	grace     time.Duration
	interval  time.Duration

	// removePhoto apaga o arquivo de uma foto. É um campo (e não uma chamada
	// fixa) só para os testes simularem falhas de disco.
	removePhoto func(name string) error
}

func New(db *sql.DB, storage *media.Storage, cfg platform.Config, now platform.Clock, log *slog.Logger) *Runner {
	return &Runner{
		store: &Store{db: db}, storage: storage, now: now, log: log,
		retention: cfg.StoryRecoverableFor, grace: cfg.OrphanGrace, interval: cfg.CleanupInterval,
		removePhoto: storage.DeletePhoto,
	}
}

// SetPhotoRemover troca a função que apaga arquivos (para testes).
func (r *Runner) SetPhotoRemover(fn func(name string) error) { r.removePhoto = fn }

// Run executa uma rodada imediatamente e depois uma a cada intervalo, até o
// contexto ser cancelado (desligamento do programa).
func (r *Runner) Run(ctx context.Context) {
	r.runLogged(ctx)
	ticker := time.NewTicker(r.interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			r.runLogged(ctx)
		}
	}
}

func (r *Runner) runLogged(ctx context.Context) {
	defer func() {
		if p := recover(); p != nil {
			r.log.Error("pânico na limpeza", "panic", p) // a próxima rodada tenta de novo
		}
	}()
	report, err := r.RunOnce(ctx)
	if err != nil {
		r.log.Error("limpeza terminou com erros", "err", err)
	}
	r.log.Info("limpeza", "report", report)
}

// RunOnce faz uma rodada completa. Um passo que falha não impede os seguintes.
func (r *Runner) RunOnce(ctx context.Context) (Report, error) {
	var rep Report
	var errs []error
	now := r.now()

	// 1) Stories com 72 h ou mais deixam de existir.
	n, err := r.store.deleteExpiredStories(ctx, now.Add(-r.retention))
	rep.StoriesExpired = n
	errs = append(errs, err)

	// 2) Fotos sem story: apaga o arquivo e, SÓ SE deu certo, a linha do banco.
	//    Se falhar, registra e espera cada vez mais antes de tentar de novo.
	errs = append(errs, r.deleteUnreferencedPhotos(ctx, now, &rep))

	// 3) Arquivos que existem em disco mas não têm registro (queda no meio de
	//    um envio) e restos na pasta tmp.
	errs = append(errs, r.deleteOrphanFiles(ctx, now, &rep))

	// 4) Sessões e convites vencidos.
	rep.SessionsDeleted, rep.InvitesDeleted, err = r.store.purgeExpiredAuth(ctx, now.Add(-authGrace))
	errs = append(errs, err)

	return rep, errors.Join(errs...)
}

func (r *Runner) deleteUnreferencedPhotos(ctx context.Context, now time.Time, rep *Report) error {
	list, err := r.store.deletableMedia(ctx, now.Add(-r.grace), now, batchSize)
	if err != nil {
		return err
	}
	for _, m := range list {
		if err := r.removePhoto(m.FileName); err != nil {
			attempts := m.Attempts + 1
			rep.PhotoFailures++
			r.log.Warn("falha ao apagar foto; nova tentativa agendada", "media", m.ID, "attempts", attempts, "err", err)
			if ferr := r.store.recordFailure(ctx, m.ID, attempts, now.Add(backoff(attempts)), err.Error()); ferr != nil {
				return ferr
			}
			continue
		}
		if err := r.store.deleteMediaRow(ctx, m.ID); err != nil {
			return err
		}
		rep.PhotosDeleted++
	}
	return nil
}

func (r *Runner) deleteOrphanFiles(ctx context.Context, now time.Time, rep *Report) error {
	photos, err := r.storage.ListPhotos()
	if err != nil {
		return err
	}
	for _, f := range photos {
		if now.Sub(f.ModTime) < r.grace {
			continue // pode ser um envio em andamento
		}
		known, err := r.store.knownFile(ctx, f.Name)
		if err != nil {
			return err
		}
		if known {
			continue
		}
		if err := r.removePhoto(f.Name); err != nil {
			r.log.Warn("falha ao apagar arquivo órfão; será tentado na próxima rodada", "file", f.Name, "err", err)
			continue
		}
		rep.OrphanFilesDeleted++
	}

	temps, err := r.storage.ListTemp()
	if err != nil {
		return err
	}
	for _, f := range temps {
		if now.Sub(f.ModTime) < r.grace {
			continue
		}
		if err := r.storage.DeleteTemp(f.Name); err != nil {
			r.log.Warn("falha ao apagar arquivo temporário", "file", f.Name, "err", err)
			continue
		}
		rep.TempFilesDeleted++
	}
	return nil
}

// backoff: 1 min, 2 min, 4 min... limitado a 6 h.
func backoff(attempts int) time.Duration {
	d := retryBase
	for i := 1; i < attempts && d < retryCeiling; i++ {
		d *= 2
	}
	return min(d, retryCeiling)
}
