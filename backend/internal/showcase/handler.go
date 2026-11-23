// Package showcase stores optional client-reported rewards. It is not a verified ranking.
package showcase

import (
	"database/sql"
	"encoding/json"
	"github.com/JanGustavo/MeteMarcha/backend/internal/auth"
	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
	"net/http"
	"time"
	"unicode/utf8"
)

type Handler struct {
	db  *sql.DB
	now platform.Clock
}

func NewHandler(db *sql.DB, now platform.Clock) *Handler { return &Handler{db: db, now: now} }
func (h *Handler) Register(mux *http.ServeMux, require func(http.HandlerFunc) http.HandlerFunc) {
	mux.HandleFunc("GET /v1/me/rewards", require(h.mine))
	mux.HandleFunc("PUT /v1/me/rewards", require(h.save))
	mux.HandleFunc("DELETE /v1/me/rewards", require(h.remove))
	mux.HandleFunc("GET /v1/members/{userID}/showcase", require(h.member))
}

type Reward struct {
	ID     string `json:"id"`
	Title  string `json:"title"`
	Detail string `json:"detail"`
	Kind   string `json:"kind"`
	Value  string `json:"value"`
	At     string `json:"at"`
	Seen   bool   `json:"seen"`
}
type Snapshot struct {
	Records []Reward `json:"records"`
	Pinned  *string  `json:"pinned"`
	Visible bool     `json:"visible_to_squads"`
}

func valid(s Snapshot) bool {
	if len(s.Records) == 0 || len(s.Records) > 500 {
		return false
	}
	ids := map[string]bool{}
	for _, r := range s.Records {
		if r.ID == "" || len(r.ID) > 200 || ids[r.ID] || utf8.RuneCountInString(r.Title) > 200 || r.Title == "" || utf8.RuneCountInString(r.Detail) > 1500 || len(r.Value) > 100 || len(r.At) > 50 || (r.Kind != "weeks" && r.Kind != "pr" && r.Kind != "achievement") {
			return false
		}
		if _, err := time.Parse(time.RFC3339Nano, r.At); err != nil {
			return false
		}
		ids[r.ID] = true
	}
	return s.Pinned == nil || ids[*s.Pinned]
}
func (h *Handler) mine(w http.ResponseWriter, r *http.Request) {
	var raw string
	var at int64
	err := h.db.QueryRowContext(r.Context(), "SELECT snapshot,updated_at FROM profile_rewards WHERE user_id=?", auth.UserFrom(r.Context()).ID).Scan(&raw, &at)
	if err == sql.ErrNoRows {
		platform.WriteJSON(w, 200, map[string]any{"snapshot": nil})
		return
	}
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	var snapshot Snapshot
	if err = json.Unmarshal([]byte(raw), &snapshot); err != nil {
		platform.WriteError(w, r, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	platform.WriteJSON(w, 200, map[string]any{"snapshot": snapshot, "updated_at": at, "client_reported": true})
}
func (h *Handler) save(w http.ResponseWriter, r *http.Request) {
	var snapshot Snapshot
	if err := platform.ReadJSON(w, r, &snapshot); err != nil {
		platform.WriteError(w, r, err)
		return
	}
	if !valid(snapshot) {
		platform.WriteError(w, r, platform.NewError(422, "invalid_rewards", "Confira as conquistas e o destaque selecionado."))
		return
	}
	raw, err := json.Marshal(snapshot)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	if len(raw) > 512*1024 {
		platform.WriteError(w, r, platform.NewError(422, "invalid_rewards", "O histórico de conquistas é grande demais."))
		return
	}
	at := h.now().Unix()
	_, err = h.db.ExecContext(r.Context(), "INSERT INTO profile_rewards(user_id,snapshot,visible_to_squads,updated_at) VALUES(?,?,?,?) ON CONFLICT(user_id) DO UPDATE SET snapshot=excluded.snapshot,visible_to_squads=excluded.visible_to_squads,updated_at=excluded.updated_at", auth.UserFrom(r.Context()).ID, string(raw), snapshot.Visible, at)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	platform.WriteJSON(w, 200, map[string]any{"saved": true, "updated_at": at, "client_reported": true})
}
func (h *Handler) remove(w http.ResponseWriter, r *http.Request) {
	_, err := h.db.ExecContext(r.Context(), "DELETE FROM profile_rewards WHERE user_id=?", auth.UserFrom(r.Context()).ID)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
func (h *Handler) member(w http.ResponseWriter, r *http.Request) {
	var raw string
	err := h.db.QueryRowContext(r.Context(), `SELECT p.snapshot FROM profile_rewards p WHERE p.user_id=? AND p.visible_to_squads=1 AND EXISTS(SELECT 1 FROM group_members a JOIN group_members b ON a.group_id=b.group_id WHERE a.user_id=? AND b.user_id=p.user_id)`, r.PathValue("userID"), auth.UserFrom(r.Context()).ID).Scan(&raw)
	if err == sql.ErrNoRows {
		platform.WriteError(w, r, platform.NewError(404, "not_found", "Destaque não disponível."))
		return
	}
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	var snapshot Snapshot
	if err = json.Unmarshal([]byte(raw), &snapshot); err != nil {
		platform.WriteError(w, r, err)
		return
	}
	var pinned *Reward
	for _, reward := range snapshot.Records {
		if snapshot.Pinned != nil && reward.ID == *snapshot.Pinned {
			copy := reward
			pinned = &copy
			break
		}
	}
	w.Header().Set("Cache-Control", "private, no-store")
	platform.WriteJSON(w, 200, map[string]any{"pinned": pinned, "client_reported": true})
}
