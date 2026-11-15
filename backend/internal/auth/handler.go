package auth

import (
	"context"
	"net/http"
	"strings"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

// Handler traduz HTTP <-> Service. Não tem regra de negócio.
type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("POST /v1/auth/register", h.register)
	mux.HandleFunc("POST /v1/auth/login", h.login)
	mux.HandleFunc("POST /v1/auth/logout", h.Require(h.logout))
	mux.HandleFunc("GET /v1/me", h.Require(h.me))
}

type ctxKey struct{}

// UserFrom devolve o usuário autenticado dentro de um handler protegido por Require.
func UserFrom(ctx context.Context) User {
	u, _ := ctx.Value(ctxKey{}).(User)
	return u
}

// Require protege um handler: lê "Authorization: Bearer <token>", identifica o
// usuário e o coloca no contexto. O resto do programa NUNCA confia em ids de
// usuário vindos do corpo ou da URL — sempre usa UserFrom(r.Context()).
func (h *Handler) Require(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user, err := h.svc.Authenticate(r.Context(), bearerToken(r))
		if err != nil {
			w.Header().Set("WWW-Authenticate", "Bearer")
			platform.WriteError(w, r, err)
			return
		}
		next(w, r.WithContext(context.WithValue(r.Context(), ctxKey{}, user)))
	}
}

func bearerToken(r *http.Request) string {
	h := r.Header.Get("Authorization")
	if len(h) > 7 && strings.EqualFold(h[:7], "Bearer ") {
		return strings.TrimSpace(h[7:])
	}
	return ""
}

type registerRequest struct {
	Email       string `json:"email"`
	DisplayName string `json:"display_name"`
	Password    string `json:"password"`
}

type sessionResponse struct {
	User    User    `json:"user"`
	Session Session `json:"session"`
}

func (h *Handler) register(w http.ResponseWriter, r *http.Request) {
	var req registerRequest
	if err := platform.ReadJSON(w, r, &req); err != nil {
		platform.WriteError(w, r, err)
		return
	}
	user, session, err := h.svc.Register(r.Context(), req.Email, req.DisplayName, req.Password)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	platform.WriteJSON(w, http.StatusCreated, sessionResponse{User: user, Session: session})
}

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *Handler) login(w http.ResponseWriter, r *http.Request) {
	var req loginRequest
	if err := platform.ReadJSON(w, r, &req); err != nil {
		platform.WriteError(w, r, err)
		return
	}
	user, session, err := h.svc.Login(r.Context(), req.Email, req.Password)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	platform.WriteJSON(w, http.StatusOK, sessionResponse{User: user, Session: session})
}

func (h *Handler) logout(w http.ResponseWriter, r *http.Request) {
	if err := h.svc.Logout(r.Context(), bearerToken(r)); err != nil {
		platform.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) me(w http.ResponseWriter, r *http.Request) {
	platform.WriteJSON(w, http.StatusOK, map[string]any{"user": UserFrom(r.Context())})
}
