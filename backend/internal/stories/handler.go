package stories

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/JanGustavo/MeteMarcha/backend/internal/auth"
	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

type Handler struct {
	svc             *Service
	maxRequestBytes int64
}

func NewHandler(svc *Service, cfg platform.Config) *Handler {
	// A requisição inclui a foto (limitada por MaxPhotoBytes) mais campos de texto.
	return &Handler{svc: svc, maxRequestBytes: cfg.MaxPhotoBytes + (1 << 20)}
}

func (h *Handler) Register(mux *http.ServeMux, require func(http.HandlerFunc) http.HandlerFunc) {
	mux.HandleFunc("POST /v1/stories", require(h.publish))
	mux.HandleFunc("GET /v1/feed", require(h.feed))
	mux.HandleFunc("PUT /v1/stories/{id}/reaction", require(h.react))
	mux.HandleFunc("DELETE /v1/stories/{id}/reaction", require(h.unreact))
}

// publish recebe multipart/form-data: photo (arquivo) + caption, track_id,
// track_start_ms, track_duration_ms (texto), e o cabeçalho Idempotency-Key.
func (h *Handler) publish(w http.ResponseWriter, r *http.Request) {
	user := auth.UserFrom(r.Context())

	// A chave é conferida antes de ler o corpo: nada de baixar uma foto grande à toa.
	requestID := r.Header.Get("Idempotency-Key")
	if !requestIDRe.MatchString(requestID) {
		platform.WriteError(w, r, platform.NewError(http.StatusBadRequest, "invalid_idempotency_key",
			"Envie o cabeçalho Idempotency-Key com 8 a 100 caracteres (letras, números, ponto, dois-pontos, hífen ou sublinhado)."))
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, h.maxRequestBytes)
	if err := r.ParseMultipartForm(1 << 20); err != nil {
		var tooBig *http.MaxBytesError
		if errors.As(err, &tooBig) {
			platform.WriteError(w, r, platform.NewError(http.StatusRequestEntityTooLarge, "request_too_large", "Requisição grande demais."))
			return
		}
		platform.WriteError(w, r, platform.NewError(http.StatusBadRequest, "invalid_multipart", "Envie multipart/form-data com o campo photo."))
		return
	}
	defer r.MultipartForm.RemoveAll() // apaga arquivos temporários do upload

	photo, _, err := r.FormFile("photo")
	if err != nil {
		platform.WriteError(w, r, platform.NewError(http.StatusBadRequest, "photo_required", "O campo photo (arquivo) é obrigatório."))
		return
	}
	defer photo.Close()

	start, err := optionalInt(r.FormValue("track_start_ms"), "track_start_ms")
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	dur, err := optionalInt(r.FormValue("track_duration_ms"), "track_duration_ms")
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}

	story, created, err := h.svc.Publish(r.Context(), PublishInput{
		AuthorID: user.ID, RequestID: requestID, Caption: r.FormValue("caption"),
		TrackID: r.FormValue("track_id"), TrackStartMS: start, TrackDurationMS: dur, Photo: photo,
	})
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	status := http.StatusCreated
	if !created {
		status = http.StatusOK
		w.Header().Set("Idempotent-Replayed", "true")
	}
	platform.WriteJSON(w, status, map[string]any{"story": story})
}

func (h *Handler) feed(w http.ResponseWriter, r *http.Request) {
	limit := 20
	if v := r.URL.Query().Get("limit"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 1 || n > 50 {
			platform.WriteError(w, r, platform.NewError(http.StatusBadRequest, "invalid_limit", "limit deve ser um número de 1 a 50."))
			return
		}
		limit = n
	}
	var before int64
	if v := r.URL.Query().Get("before"); v != "" {
		n, err := strconv.ParseInt(v, 10, 64)
		if err != nil || n < 1 {
			platform.WriteError(w, r, platform.NewError(http.StatusBadRequest, "invalid_cursor", "before deve ser o next_cursor devolvido pelo feed."))
			return
		}
		before = n
	}

	items, next, err := h.svc.Feed(r.Context(), auth.UserFrom(r.Context()).ID, limit, before)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	if items == nil {
		items = []Story{}
	}
	var nextCursor *string
	if next > 0 {
		c := strconv.FormatInt(next, 10)
		nextCursor = &c
	}
	platform.WriteJSON(w, http.StatusOK, map[string]any{"stories": items, "next_cursor": nextCursor})
}

func (h *Handler) react(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Kind string `json:"kind"`
	}
	if err := platform.ReadJSON(w, r, &req); err != nil {
		platform.WriteError(w, r, err)
		return
	}
	sum, err := h.svc.React(r.Context(), auth.UserFrom(r.Context()).ID, r.PathValue("id"), req.Kind)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	platform.WriteJSON(w, http.StatusOK, map[string]any{"reactions": sum})
}

func (h *Handler) unreact(w http.ResponseWriter, r *http.Request) {
	sum, err := h.svc.Unreact(r.Context(), auth.UserFrom(r.Context()).ID, r.PathValue("id"))
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	platform.WriteJSON(w, http.StatusOK, map[string]any{"reactions": sum})
}

func optionalInt(raw, field string) (*int64, error) {
	if raw == "" {
		return nil, nil
	}
	n, err := strconv.ParseInt(raw, 10, 64)
	if err != nil {
		return nil, platform.NewError(http.StatusBadRequest, "invalid_field", field+" deve ser um número inteiro (milissegundos).")
	}
	return &n, nil
}
