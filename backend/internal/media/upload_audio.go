package media

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

const maxAudioUpload = 15 << 20

func (s *Service) StoreUserAudio(ctx context.Context, userID, title, license string, reader io.Reader) (Track, error) {
	title = strings.TrimSpace(title)
	if title == "" || len(title) > 200 || license != "open-or-owned" {
		return Track{}, platform.NewError(422, "invalid_audio", "Informe o título e confirme a licença aberta ou autoria própria do áudio.")
	}
	var member int
	if err := s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM group_members WHERE user_id=?`, userID).Scan(&member); err != nil {
		return Track{}, err
	}
	if member == 0 {
		return Track{}, platform.NewError(403, "not_in_group", "Entre em um squad antes de enviar áudio.")
	}
	if _, err := exec.LookPath("ffprobe"); err != nil {
		return Track{}, platform.NewError(503, "audio_upload_unavailable", "O servidor ainda não está preparado para receber áudios do celular.")
	}
	data, err := io.ReadAll(io.LimitReader(reader, maxAudioUpload+1))
	if err != nil {
		return Track{}, err
	}
	if len(data) == 0 || len(data) > maxAudioUpload {
		return Track{}, platform.NewError(413, "audio_too_large", "Escolha um áudio de até 15 MB.")
	}
	hash := sha256.Sum256(append([]byte(userID), data...))
	id := fmt.Sprintf("user-%x", hash[:16])
	if track, ok, err := s.ActiveTrackForUser(ctx, id, userID); err != nil {
		return Track{}, err
	} else if ok {
		return track, nil
	}
	var count int
	if err := s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM tracks WHERE owner_id=?`, userID).Scan(&count); err != nil {
		return Track{}, err
	}
	if count >= 20 {
		return Track{}, platform.NewError(422, "audio_quota", "Você já tem 20 áudios enviados. Use uma faixa existente ou o catálogo.")
	}
	if err := os.MkdirAll(s.musicDir, 0750); err != nil {
		return Track{}, err
	}
	file, err := os.CreateTemp(s.musicDir, "upload-*")
	if err != nil {
		return Track{}, err
	}
	name := file.Name()
	defer os.Remove(name)
	if _, err = file.Write(data); err != nil {
		file.Close()
		return Track{}, err
	}
	file.Close()
	probeCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	output, err := exec.CommandContext(probeCtx, "ffprobe", "-v", "error", "-protocol_whitelist", "file", "-show_entries", "format=format_name,duration:stream=codec_type", "-of", "json", name).Output()
	if err != nil {
		return Track{}, platform.NewError(422, "invalid_audio", "Não foi possível ler esse áudio. Use MP3, M4A, OGG ou WAV.")
	}
	var probe struct {
		Format struct {
			Name     string `json:"format_name"`
			Duration string `json:"duration"`
		} `json:"format"`
		Streams []struct {
			Type string `json:"codec_type"`
		} `json:"streams"`
	}
	if json.Unmarshal(output, &probe) != nil {
		return Track{}, platform.NewError(422, "invalid_audio", "Áudio inválido.")
	}
	duration, err := strconv.ParseFloat(probe.Format.Duration, 64)
	if err != nil || duration <= 0 || duration > 600 {
		return Track{}, platform.NewError(422, "invalid_audio", "Use um áudio com duração de até dez minutos.")
	}
	audio := false
	for _, stream := range probe.Streams {
		if stream.Type == "audio" {
			audio = true
		}
		if stream.Type == "video" {
			return Track{}, platform.NewError(422, "invalid_audio", "Escolha um arquivo de áudio, sem vídeo.")
		}
	}
	if !audio {
		return Track{}, platform.NewError(422, "invalid_audio", "Arquivo sem áudio.")
	}
	extension := ""
	contentType := ""
	switch {
	case probe.Format.Name == "mp3":
		extension = ".mp3"
		contentType = "audio/mpeg"
	case strings.Contains(probe.Format.Name, "mp4"):
		extension = ".m4a"
		contentType = "audio/mp4"
	case probe.Format.Name == "ogg":
		extension = ".ogg"
		contentType = "audio/ogg"
	case probe.Format.Name == "wav":
		extension = ".wav"
		contentType = "audio/wav"
	}
	if extension == "" {
		return Track{}, platform.NewError(422, "invalid_audio", "Use MP3, M4A, OGG ou WAV.")
	}
	filename := id + extension
	// A content-derived filename makes retries safe, including simultaneous uploads.
	destination := filepath.Join(s.musicDir, filename)
	if err := os.Rename(name, destination); err != nil {
		return Track{}, err
	}
	_, err = s.db.ExecContext(ctx, `INSERT INTO tracks(id,title,artist,file_name,content_type,duration_ms,license_note,active,owner_id) VALUES(?,?,?,?,?,?,?,1,?) ON CONFLICT(id) DO NOTHING`, id, title, "Áudio do celular", filename, contentType, int64(duration*1000), "Licença aberta ou autoria própria declarada pelo usuário", userID)
	if err != nil {
		return Track{}, err
	}
	return Track{ID: id, Title: title, Artist: "Áudio do celular", DurationMS: int64(duration * 1000), AudioURL: "/v1/tracks/" + id + "/audio"}, nil
}
func (s *Service) ActiveTrackForUser(ctx context.Context, id, userID string) (Track, bool, error) {
	var allowed int
	err := s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM tracks WHERE id=? AND (owner_id IS NULL OR owner_id=?)`, id, userID).Scan(&allowed)
	if err != nil || allowed == 0 {
		return Track{}, false, err
	}
	return s.ActiveTrack(ctx, id)
}
func (s *Service) CanReadTrack(ctx context.Context, id, userID string) (bool, error) {
	var allowed int
	err := s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM tracks t WHERE t.id=? AND (t.owner_id IS NULL OR t.owner_id=? OR EXISTS(SELECT 1 FROM stories s JOIN group_members m ON m.group_id=s.group_id WHERE s.track_id=t.id AND m.user_id=? AND s.created_at>?))`, id, userID, userID, platform.Unix(s.now().Add(-24*time.Hour))).Scan(&allowed)
	return allowed > 0, err
}

func (s *Service) UserTracks(ctx context.Context, userID string) ([]Track, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT id,title,artist,duration_ms FROM tracks WHERE active=1 AND owner_id=? ORDER BY title,id`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Track{}
	for rows.Next() {
		var t Track
		if err := rows.Scan(&t.ID, &t.Title, &t.Artist, &t.DurationMS); err != nil {
			return nil, err
		}
		t.AudioURL = "/v1/tracks/" + t.ID + "/audio"
		out = append(out, t)
	}
	return out, rows.Err()
}
