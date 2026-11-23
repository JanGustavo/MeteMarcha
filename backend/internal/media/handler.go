package media

import (
	"context"
	"net/http"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/auth"
	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

// PhotoAuthorizer decide se este usuário pode baixar a foto deste story e, se
// puder, devolve o id da mídia. As regras de 24 h / 72 h pertencem ao módulo
// stories; media só recebe a função e a chama. Assim a regra mora num lugar só.
type PhotoAuthorizer func(ctx context.Context, userID, storyID string) (mediaID string, err error)

type Handler struct {
	svc            *Service
	authorizePhoto PhotoAuthorizer
}

func NewHandler(svc *Service, authorizePhoto PhotoAuthorizer) *Handler {
	return &Handler{svc: svc, authorizePhoto: authorizePhoto}
}

func (h *Handler) Register(mux *http.ServeMux, require func(http.HandlerFunc) http.HandlerFunc) {
	mux.HandleFunc("POST /v1/tracks/upload", require(h.uploadTrack))
	mux.HandleFunc("GET /v1/tracks", require(h.listTracks))
	mux.HandleFunc("GET /v1/tracks/{id}/audio", require(h.trackAudio))
	mux.HandleFunc("GET /v1/stories/{id}/photo", require(h.storyPhoto))
}

func (h *Handler) listTracks(w http.ResponseWriter, r *http.Request) {
	tracks, err := h.svc.ListTracks(r.Context())
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	own, err := h.svc.UserTracks(r.Context(), auth.UserFrom(r.Context()).ID)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	tracks = append(tracks, own...)
	platform.WriteJSON(w, http.StatusOK, map[string]any{"tracks": tracks})
}

func (h *Handler) trackAudio(w http.ResponseWriter, r *http.Request) {
	allowed, err := h.svc.CanReadTrack(r.Context(), r.PathValue("id"), auth.UserFrom(r.Context()).ID)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	if !allowed {
		platform.WriteError(w, r, ErrTrackNotFound)
		return
	}

	f, contentType, err := h.svc.OpenTrackAudio(r.Context(), r.PathValue("id"))
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	defer f.Close()
	info, err := f.Stat()
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Cache-Control", "private, max-age=3600") // catálogo compartilhado, mas só para logados
	http.ServeContent(w, r, "", info.ModTime(), f)           // suporta Range (tocar a partir de um instante)
}

// storyPhoto: 1) autentica (Require), 2) autoriza pela regra do story, 3) entrega.
func (h *Handler) storyPhoto(w http.ResponseWriter, r *http.Request) {
	user := auth.UserFrom(r.Context())
	mediaID, err := h.authorizePhoto(r.Context(), user.ID, r.PathValue("id"))
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	photo, err := h.svc.PhotoFile(r.Context(), mediaID)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	defer photo.File.Close()

	w.Header().Set("Content-Type", photo.ContentType)
	// Fotos privadas: nada de cache compartilhado nem armazenamento pelo navegador/proxy.
	w.Header().Set("Cache-Control", "private, no-store")
	w.Header().Set("Content-Disposition", "inline")
	http.ServeContent(w, r, "", time.Time{}, photo.File)
}

func (h *Handler) uploadTrack(w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, maxAudioUpload+(1<<20))
	if err := r.ParseMultipartForm(1 << 20); err != nil {
		platform.WriteError(w, r, platform.NewError(413, "invalid_upload", "Envie um áudio de até 15 MB."))
		return
	}
	defer r.MultipartForm.RemoveAll()
	file, _, err := r.FormFile("audio")
	if err != nil {
		platform.WriteError(w, r, platform.NewError(422, "audio_required", "Selecione um arquivo de áudio."))
		return
	}
	defer file.Close()
	track, err := h.svc.StoreUserAudio(r.Context(), auth.UserFrom(r.Context()).ID, r.FormValue("title"), r.FormValue("license"), file)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	platform.WriteJSON(w, 201, map[string]any{"track": track})
}
