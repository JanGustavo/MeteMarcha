// Comando api: inicia o servidor HTTP do MeteMarcha e a rotina de limpeza.
// Este arquivo só liga as peças; as regras vivem em internal/.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/app"
	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

func main() {
	slog.SetDefault(slog.New(slog.NewTextHandler(os.Stdout, nil)))

	cfg, err := platform.LoadConfig()
	if err != nil {
		slog.Error("configuração", "err", err)
		os.Exit(1)
	}
	application, err := app.New(cfg, platform.SystemClock)
	if err != nil {
		slog.Error("não foi possível iniciar", "err", err)
		os.Exit(1)
	}
	defer application.Close()

	// SIGINT/SIGTERM (Ctrl+C, systemctl stop) cancelam o contexto e desligam com calma.
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	srv := &http.Server{
		Addr:              cfg.Addr,
		Handler:           application.Handler,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       2 * time.Minute, // uploads de foto em rede móvel lenta
		WriteTimeout:      2 * time.Minute,
		IdleTimeout:       2 * time.Minute,
	}
	listener, err := net.Listen("tcp", cfg.Addr)
	if err != nil {
		slog.Error("não foi possível abrir a porta do servidor", "addr", cfg.Addr, "err", err)
		application.Close()
		os.Exit(1)
	}

	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		application.Cleanup.Run(ctx)
	}()

	go func() {
		slog.Info("servidor ouvindo", "addr", listener.Addr().String())
		if err := srv.Serve(listener); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("servidor", "err", err)
			stop()
		}
	}()

	<-ctx.Done()
	slog.Info("desligando...")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		slog.Error("encerramento do servidor", "err", err)
	}
	wg.Wait()
}
