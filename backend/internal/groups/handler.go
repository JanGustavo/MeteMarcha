package groups

import (
	"net/http"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/auth"
	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

// Register recebe "require" (o protetor de rotas do módulo auth) como parâmetro:
// assim este módulo não precisa saber como a autenticação funciona por dentro.
func (h *Handler) Register(mux *http.ServeMux, require func(http.HandlerFunc) http.HandlerFunc) {
	mux.HandleFunc("POST /v1/groups", require(h.create))
	mux.HandleFunc("GET /v1/groups/me", require(h.mine))
	mux.HandleFunc("POST /v1/groups/me/invites", require(h.invite))
	mux.HandleFunc("POST /v1/groups/join", require(h.join))
	mux.HandleFunc("POST /v1/groups/me/leave", require(h.leave))
}

type groupView struct {
	Group
	MaxMembers int `json:"max_members"`
}

func (h *Handler) view(g Group) groupView { return groupView{Group: g, MaxMembers: h.svc.MaxMembers()} }

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Name string `json:"name"`
	}
	if err := platform.ReadJSON(w, r, &req); err != nil {
		platform.WriteError(w, r, err)
		return
	}
	g, err := h.svc.Create(r.Context(), auth.UserFrom(r.Context()).ID, req.Name)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	platform.WriteJSON(w, http.StatusCreated, map[string]any{"group": h.view(g)})
}

func (h *Handler) mine(w http.ResponseWriter, r *http.Request) {
	g, members, err := h.svc.Mine(r.Context(), auth.UserFrom(r.Context()).ID)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	platform.WriteJSON(w, http.StatusOK, map[string]any{"group": h.view(g), "members": members})
}

func (h *Handler) invite(w http.ResponseWriter, r *http.Request) {
	code, expires, err := h.svc.CreateInvite(r.Context(), auth.UserFrom(r.Context()).ID)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	platform.WriteJSON(w, http.StatusCreated, map[string]any{
		"invite": struct {
			Code      string    `json:"code"`
			ExpiresAt time.Time `json:"expires_at"`
		}{code, expires},
	})
}

func (h *Handler) join(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Code string `json:"code"`
	}
	if err := platform.ReadJSON(w, r, &req); err != nil {
		platform.WriteError(w, r, err)
		return
	}
	g, err := h.svc.Join(r.Context(), auth.UserFrom(r.Context()).ID, req.Code)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	platform.WriteJSON(w, http.StatusOK, map[string]any{"group": h.view(g)})
}

func (h *Handler) leave(w http.ResponseWriter, r *http.Request) {
	if err := h.svc.Leave(r.Context(), auth.UserFrom(r.Context()).ID); err != nil {
		platform.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
