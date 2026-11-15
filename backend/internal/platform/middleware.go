package platform

import (
	"log/slog"
	"net/http"
	"time"
)

// Wrap aplica, de fora para dentro: recuperação de pânico, cabeçalhos de
// segurança e log de acesso. Fica fora das regras de negócio de propósito.
func Wrap(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}

		defer func() {
			if p := recover(); p != nil {
				slog.Error("pânico na requisição", "path", r.URL.Path, "panic", p)
				if !rec.wrote {
					WriteJSON(rec, http.StatusInternalServerError, map[string]any{
						"error": NewError(http.StatusInternalServerError, "internal_error", "Erro interno. Tente novamente."),
					})
				}
			}
			slog.Info("requisição", "method", r.Method, "path", r.URL.Path, "status", rec.status, "ms", time.Since(start).Milliseconds())
		}()

		rec.Header().Set("X-Content-Type-Options", "nosniff")
		next.ServeHTTP(rec, r)
	})
}

type statusRecorder struct {
	http.ResponseWriter
	status int
	wrote  bool
}

func (s *statusRecorder) WriteHeader(code int) {
	s.status = code
	s.wrote = true
	s.ResponseWriter.WriteHeader(code)
}

func (s *statusRecorder) Write(b []byte) (int, error) {
	s.wrote = true
	return s.ResponseWriter.Write(b)
}
