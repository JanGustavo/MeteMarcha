package stories

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

// Store é só SQL. Lê usuários e faixas apenas para montar o feed numa consulta
// (nome do autor, título da música); não altera tabelas de outros módulos.
type Store struct{ db *sql.DB }

// storyRow é uma linha do banco, já com nome do autor e dados da faixa.
type storyRow struct {
	Seq        int64
	ID         string
	AuthorID   string
	AuthorName string
	GroupID    string
	MediaID    string
	Report     string
	Caption    string
	CreatedAt  time.Time
	TrackID    sql.NullString
	TrackTitle sql.NullString
	TrackArtst sql.NullString
	StartMS    sql.NullInt64
	DurationMS sql.NullInt64
}

const selectStory = `
SELECT s.seq, s.id, s.author_id, u.display_name, s.group_id, s.photo_media_id, s.caption, s.created_at,
       s.track_id, t.title, t.artist, s.track_start_ms, s.track_duration_ms, s.workout_report
  FROM stories s
  JOIN users u ON u.id = s.author_id
  LEFT JOIN tracks t ON t.id = s.track_id `

type rowScanner interface{ Scan(dest ...any) error }

func scanStory(sc rowScanner) (storyRow, error) {
	var r storyRow
	var created int64
	err := sc.Scan(&r.Seq, &r.ID, &r.AuthorID, &r.AuthorName, &r.GroupID, &r.MediaID, &r.Caption, &created,
		&r.TrackID, &r.TrackTitle, &r.TrackArtst, &r.StartMS, &r.DurationMS, &r.Report)
	r.CreatedAt = platform.FromUnix(created)
	return r, err
}

type newStory struct {
	ID, AuthorID, GroupID, MediaID, Caption, RequestID, Report string
	Clip                                                       *clip
	CreatedAt                                                  time.Time
}

// insert grava o story. Se (autor, request_id) já existir, a restrição UNIQUE
// falha — quem chama trata isso como "publicação repetida".
func (s *Store) insert(ctx context.Context, n newStory) error {
	var trackID, start, dur any // NULL quando não há música
	if n.Clip != nil {
		trackID, start, dur = n.Clip.TrackID, n.Clip.StartMS, n.Clip.DurationMS
	}
	_, err := s.db.ExecContext(ctx,
		`INSERT INTO stories (id, author_id, group_id, photo_media_id, caption, track_id, track_start_ms,
		                      track_duration_ms, client_request_id, created_at, workout_report)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		n.ID, n.AuthorID, n.GroupID, n.MediaID, n.Caption, trackID, start, dur, n.RequestID, platform.Unix(n.CreatedAt), n.Report)
	return err
}

func (s *Store) byAuthorRequest(ctx context.Context, authorID, requestID string) (storyRow, bool, error) {
	return s.one(ctx, selectStory+`WHERE s.author_id = ? AND s.client_request_id = ?`, authorID, requestID)
}

func (s *Store) byID(ctx context.Context, id string) (storyRow, bool, error) {
	return s.one(ctx, selectStory+`WHERE s.id = ?`, id)
}

func (s *Store) one(ctx context.Context, query string, args ...any) (storyRow, bool, error) {
	r, err := scanStory(s.db.QueryRowContext(ctx, query, args...))
	if errors.Is(err, sql.ErrNoRows) {
		return storyRow{}, false, nil
	}
	return r, err == nil, err
}

// feed devolve stories da roda criados DEPOIS de newerThan (segundos Unix),
// do mais novo para o mais antigo. beforeSeq > 0 continua de onde parou.
func (s *Store) feed(ctx context.Context, groupID string, newerThan, beforeSeq int64, limit int) ([]storyRow, error) {
	query := selectStory + `WHERE s.group_id = ? AND s.created_at > ?`
	args := []any{groupID, newerThan}
	if beforeSeq > 0 {
		query += ` AND s.seq < ?`
		args = append(args, beforeSeq)
	}
	query += ` ORDER BY s.seq DESC LIMIT ?`
	args = append(args, limit)

	rows, err := s.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []storyRow
	for rows.Next() {
		r, err := scanStory(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

// reactionSummaries conta reações por story e descobre qual é a do espectador.
func (s *Store) reactionSummaries(ctx context.Context, storyIDs []string, viewerID string) (map[string]ReactionSummary, error) {
	out := make(map[string]ReactionSummary, len(storyIDs))
	for _, id := range storyIDs {
		out[id] = ReactionSummary{Counts: map[string]int{}}
	}
	if len(storyIDs) == 0 {
		return out, nil
	}
	marks := strings.TrimSuffix(strings.Repeat("?,", len(storyIDs)), ",")
	args := make([]any, len(storyIDs))
	for i, id := range storyIDs {
		args[i] = id
	}

	rows, err := s.db.QueryContext(ctx,
		`SELECT story_id, kind, COUNT(*) FROM reactions WHERE story_id IN (`+marks+`) GROUP BY story_id, kind`, args...)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var id, kind string
		var n int
		if err := rows.Scan(&id, &kind, &n); err != nil {
			rows.Close()
			return nil, err
		}
		out[id].Counts[kind] = n
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}

	mine, err := s.db.QueryContext(ctx,
		`SELECT story_id, kind FROM reactions WHERE user_id = ? AND story_id IN (`+marks+`)`, append([]any{viewerID}, args...)...)
	if err != nil {
		return nil, err
	}
	defer mine.Close()
	for mine.Next() {
		var id, kind string
		if err := mine.Scan(&id, &kind); err != nil {
			return nil, err
		}
		sum := out[id]
		k := kind
		sum.Mine = &k
		out[id] = sum
	}
	return out, mine.Err()
}

// upsertReaction cria a reação ou troca o tipo. A chave primária
// (story_id, user_id) garante no máximo UMA reação por pessoa por story.
func (s *Store) upsertReaction(ctx context.Context, storyID, userID, kind string, now time.Time) error {
	_, err := s.db.ExecContext(ctx,
		`INSERT INTO reactions (story_id, user_id, kind, created_at, updated_at) VALUES (?, ?, ?, ?, ?)
		 ON CONFLICT(story_id, user_id) DO UPDATE SET kind = excluded.kind, updated_at = excluded.updated_at`,
		storyID, userID, kind, platform.Unix(now), platform.Unix(now))
	return err
}

func (s *Store) deleteReaction(ctx context.Context, storyID, userID string) error {
	_, err := s.db.ExecContext(ctx, `DELETE FROM reactions WHERE story_id = ? AND user_id = ?`, storyID, userID)
	return err
}
