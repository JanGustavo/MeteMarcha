package groups

import (
	"html/template"
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
	mux.HandleFunc("GET /.well-known/assetlinks.json", func(w http.ResponseWriter, r *http.Request) {
		platform.WriteJSON(w, 200, []any{map[string]any{"relation": []string{"delegate_permission/common.handle_all_urls"}, "target": map[string]any{"namespace": "android_app", "package_name": "dev.jangustavo.metemarcha", "sha256_cert_fingerprints": []string{"4A:4C:02:74:A1:FE:2C:2F:DF:23:A7:7E:A9:82:4D:BF:21:2D:BA:E1:21:D1:54:2E:C6:CA:01:20:E8:99:13:BC"}}}})
	})
	mux.HandleFunc("GET /invite", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.Header().Set("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'")
		template.Must(template.New("invite").Parse(`<!doctype html><html lang="pt-BR"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Convite · Mete Marcha</title><body style="background:#111827;color:#fff;font:18px system-ui;padding:32px;max-width:540px;margin:auto"><h1>Bora treinar juntos?</h1><p>Abra o Mete Marcha, entre na sua conta e vá a <b>Squads → Tenho um convite</b>.</p><p>Copie e cole este código:</p><p style="overflow-wrap:anywhere;padding:20px;background:#273449">{{.}}</p><p>O convite tem prazo e vale para uma pessoa. O app confirma se ele ainda está disponível.</p></body></html>`)).Execute(w, r.URL.Query().Get("code"))
	})
	mux.HandleFunc("PATCH /v1/groups/me", require(h.update))
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
	platform.WriteJSON(w, http.StatusOK, map[string]any{"group": h.view(g), "members": members, "can_edit": func() bool {
		for _, member := range members {
			if member.UserID == auth.UserFrom(r.Context()).ID {
				return member.Role == "owner"
			}
		}
		return false
	}()})
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

func (h *Handler) update(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Name   string `json:"name"`
		Color  string `json:"color"`
		Theme  string `json:"theme"`
		Avatar string `json:"avatar"`
	}
	if err := platform.ReadJSON(w, r, &req); err != nil {
		platform.WriteError(w, r, err)
		return
	}
	g, err := h.svc.UpdateStyle(r.Context(), auth.UserFrom(r.Context()).ID, req.Name, req.Color, req.Theme, req.Avatar)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	platform.WriteJSON(w, 200, map[string]any{"group": h.view(g)})
}
