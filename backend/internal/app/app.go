// Package app monta o programa: abre o banco, roda as migrações, cria os
// serviços dos cinco módulos e registra as rotas. É o único lugar que conhece
// todos os módulos; cada módulo só conhece o que realmente usa.
package app

import (
	"context"
	"database/sql"
	"log/slog"
	"net/http"

	"github.com/JanGustavo/MeteMarcha/backend/internal/auth"
	"github.com/JanGustavo/MeteMarcha/backend/internal/cleanup"
	"github.com/JanGustavo/MeteMarcha/backend/internal/groups"
	"github.com/JanGustavo/MeteMarcha/backend/internal/media"
	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
	"github.com/JanGustavo/MeteMarcha/backend/internal/showcase"
	"github.com/JanGustavo/MeteMarcha/backend/internal/stories"
	"github.com/JanGustavo/MeteMarcha/backend/internal/workoutai"
	"github.com/JanGustavo/MeteMarcha/backend/migrations"
)

type App struct {
	Handler http.Handler
	Cleanup *cleanup.Runner
	DB      *sql.DB
}

// New liga as peças. O relógio (now) é injetado para os testes poderem
// avançar o tempo; em produção é platform.SystemClock.
func New(cfg platform.Config, now platform.Clock) (*App, error) {
	db, err := platform.OpenDB(cfg.DBPath)
	if err != nil {
		return nil, err
	}
	// Em qualquer falha daqui para baixo, fecha o banco antes de devolver o erro.
	ok := false
	defer func() {
		if !ok {
			db.Close()
		}
	}()

	if err := platform.Migrate(db, migrations.FS); err != nil {
		return nil, err
	}
	storage, err := media.NewStorage(cfg.MediaDir)
	if err != nil {
		return nil, err
	}

	// Ordem de criação = ordem das dependências: auth e groups não dependem de
	// ninguém; media precisa só do banco; stories usa groups e media.
	authSvc, err := auth.NewService(db, cfg, now)
	if err != nil {
		return nil, err
	}
	groupsSvc := groups.NewService(db, cfg, now)
	mediaSvc := media.NewService(db, storage, cfg, now)
	if n, err := mediaSvc.SyncCatalog(context.Background()); err != nil {
		return nil, err
	} else {
		slog.Info("catálogo de músicas carregado", "faixas", n)
	}
	storiesSvc := stories.NewService(db, cfg, now, groupsSvc, mediaSvc)

	authH := auth.NewHandler(authSvc)
	mux := http.NewServeMux()
	authH.Register(mux)
	showcase.NewHandler(db, now).Register(mux, authH.Require)
	workoutai.NewHandler().Register(mux, authH.Require)
	groups.NewHandler(groupsSvc).Register(mux, authH.Require)
	stories.NewHandler(storiesSvc, cfg).Register(mux, authH.Require)
	// media recebe a regra de acesso a fotos de stories como função.
	media.NewHandler(mediaSvc, storiesSvc.AuthorizePhoto).Register(mux, authH.Require)
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		if err := db.PingContext(r.Context()); err != nil {
			platform.WriteError(w, r, err)
			return
		}
		platform.WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})

	ok = true
	return &App{
		Handler: platform.Wrap(mux),
		Cleanup: cleanup.New(db, storage, cfg, now, slog.Default()),
		DB:      db,
	}, nil
}

func (a *App) Close() error { return a.DB.Close() }
