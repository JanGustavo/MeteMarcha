package media

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

// Track é uma faixa do catálogo. O app baixa o áudio por AudioURL e reproduz
// junto da foto; o servidor não processa áudio nem gera vídeo.
type Track struct {
	ID         string `json:"id"`
	Title      string `json:"title"`
	Artist     string `json:"artist"`
	DurationMS int64  `json:"duration_ms"`
	AudioURL   string `json:"audio_url"`
}

type catalogEntry struct {
	ID         string `json:"id"`
	Title      string `json:"title"`
	Artist     string `json:"artist"`
	File       string `json:"file"`
	DurationMS int64  `json:"duration_ms"`
	License    string `json:"license"` // de onde vem a autorização de uso (obrigatório)
}

var (
	trackIDRe        = regexp.MustCompile(`^[a-z0-9][a-z0-9-]{0,39}$`)
	audioTypes       = map[string]string{".mp3": "audio/mpeg", ".m4a": "audio/mp4", ".ogg": "audio/ogg", ".wav": "audio/wav"}
	ErrTrackNotFound = platform.NewError(http.StatusNotFound, "not_found", "Faixa não encontrada.")
)

// SyncCatalog lê <MusicDir>/catalog.json e atualiza a tabela tracks.
// O JSON é a fonte da verdade. Faixas que saem do JSON ficam inativas (e não
// apagadas), porque stories antigos ainda podem apontar para elas.
// Se o catálogo tiver qualquer problema, nada é alterado e o erro explica tudo.
func (s *Service) SyncCatalog(ctx context.Context) (int, error) {
	raw, err := os.ReadFile(filepath.Join(s.musicDir, "catalog.json"))
	var entries []catalogEntry
	switch {
	case errors.Is(err, os.ErrNotExist):
		// Sem catálogo: nenhuma faixa disponível (o piloto funciona sem música).
	case err != nil:
		return 0, err
	default:
		var file struct {
			Tracks []catalogEntry `json:"tracks"`
		}
		if err := json.Unmarshal(raw, &file); err != nil {
			return 0, fmt.Errorf("catalog.json inválido: %w", err)
		}
		entries = file.Tracks
	}

	contentTypes, err := s.validateCatalog(entries)
	if err != nil {
		return 0, err
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback()

	if _, err := tx.ExecContext(ctx, `UPDATE tracks SET active = 0`); err != nil {
		return 0, err
	}
	for _, e := range entries {
		if _, err := tx.ExecContext(ctx,
			`INSERT INTO tracks (id, title, artist, file_name, content_type, duration_ms, license_note, active)
			 VALUES (?, ?, ?, ?, ?, ?, ?, 1)
			 ON CONFLICT(id) DO UPDATE SET title = excluded.title, artist = excluded.artist,
			   file_name = excluded.file_name, content_type = excluded.content_type,
			   duration_ms = excluded.duration_ms, license_note = excluded.license_note, active = 1`,
			e.ID, e.Title, e.Artist, e.File, contentTypes[e.ID], e.DurationMS, e.License); err != nil {
			return 0, err
		}
	}
	return len(entries), tx.Commit()
}

func (s *Service) validateCatalog(entries []catalogEntry) (map[string]string, error) {
	var problems []string
	seen := map[string]bool{}
	types := map[string]string{}

	for i, e := range entries {
		where := fmt.Sprintf("faixa #%d (%q)", i+1, e.ID)
		if !trackIDRe.MatchString(e.ID) {
			problems = append(problems, where+": id deve usar a-z, 0-9 e hífen (até 40 caracteres)")
		}
		if seen[e.ID] {
			problems = append(problems, where+": id repetido")
		}
		seen[e.ID] = true
		if strings.TrimSpace(e.Title) == "" || strings.TrimSpace(e.Artist) == "" {
			problems = append(problems, where+": title e artist são obrigatórios")
		}
		if strings.TrimSpace(e.License) == "" {
			problems = append(problems, where+": license é obrigatório (registre de onde vem a autorização de uso)")
		}
		if e.DurationMS <= 0 {
			problems = append(problems, where+": duration_ms deve ser positivo")
		}
		ct, ok := audioTypes[strings.ToLower(filepath.Ext(e.File))]
		if !ok || filepath.Base(e.File) != e.File {
			problems = append(problems, where+": file deve ser só o nome de um arquivo .mp3, .m4a, .ogg ou .wav dentro da pasta de músicas")
		} else if info, err := os.Stat(filepath.Join(s.musicDir, e.File)); err != nil || !info.Mode().IsRegular() {
			problems = append(problems, where+": arquivo "+e.File+" não encontrado")
		}
		types[e.ID] = ct
	}
	if len(problems) > 0 {
		return nil, fmt.Errorf("catálogo de músicas inválido:\n  %s", strings.Join(problems, "\n  "))
	}
	return types, nil
}

func (s *Service) ListTracks(ctx context.Context) ([]Track, error) {
	rows, err := s.db.QueryContext(ctx,
		`SELECT id, title, artist, duration_ms FROM tracks WHERE active = 1 ORDER BY title, id`)
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

// ActiveTrack é usada ao publicar: só faixas ativas do catálogo podem ser escolhidas.
func (s *Service) ActiveTrack(ctx context.Context, id string) (Track, bool, error) {
	var t Track
	err := s.db.QueryRowContext(ctx,
		`SELECT id, title, artist, duration_ms FROM tracks WHERE id = ? AND active = 1`, id).
		Scan(&t.ID, &t.Title, &t.Artist, &t.DurationMS)
	if errors.Is(err, sql.ErrNoRows) {
		return Track{}, false, nil
	}
	t.AudioURL = "/v1/tracks/" + t.ID + "/audio"
	return t, err == nil, err
}

// OpenTrackAudio abre o arquivo de uma faixa (mesmo inativa: stories ainda
// dentro do prazo podem usá-la).
func (s *Service) OpenTrackAudio(ctx context.Context, id string) (*os.File, string, error) {
	var name, contentType string
	err := s.db.QueryRowContext(ctx, `SELECT file_name, content_type FROM tracks WHERE id = ?`, id).Scan(&name, &contentType)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, "", ErrTrackNotFound
	}
	if err != nil {
		return nil, "", err
	}
	if filepath.Base(name) != name {
		return nil, "", fmt.Errorf("nome de arquivo de faixa inválido: %q", name)
	}
	f, err := os.Open(filepath.Join(s.musicDir, name))
	if errors.Is(err, os.ErrNotExist) {
		return nil, "", ErrTrackNotFound
	}
	return f, contentType, err
}
