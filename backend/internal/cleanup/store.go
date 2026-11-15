package cleanup

import (
	"context"
	"database/sql"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

// Store é só SQL da limpeza. Repare que NENHUMA consulta aqui toca na tabela
// tracks: músicas do catálogo são compartilhadas e nunca são apagadas junto
// dos stories.
type Store struct{ db *sql.DB }

type mediaRow struct {
	ID       string
	FileName string
	Attempts int
}

// deleteExpiredStories apaga stories com idade >= prazo de recuperação (72 h).
// As reações vão junto (ON DELETE CASCADE). A foto fica sem story e passa a
// ser candidata em deletableMedia.
func (s *Store) deleteExpiredStories(ctx context.Context, cutoff time.Time) (int64, error) {
	res, err := s.db.ExecContext(ctx, `DELETE FROM stories WHERE created_at <= ?`, platform.Unix(cutoff))
	if err != nil {
		return 0, err
	}
	return res.RowsAffected()
}

// deletableMedia lista fotos que ninguém referencia mais (story expirado, envio
// que não virou story, publicação duplicada descartada...), já passadas da
// "carência" para não atropelar um envio em andamento, e cuja próxima tentativa
// já venceu (espera crescente após falhas).
func (s *Store) deletableMedia(ctx context.Context, createdBefore, now time.Time, limit int) ([]mediaRow, error) {
	rows, err := s.db.QueryContext(ctx,
		`SELECT m.id, m.file_name, m.delete_attempts
		   FROM media_files m
		  WHERE m.created_at <= ? AND m.next_attempt_at <= ?
		    AND NOT EXISTS (SELECT 1 FROM stories s WHERE s.photo_media_id = m.id)
		  ORDER BY m.created_at
		  LIMIT ?`, platform.Unix(createdBefore), platform.Unix(now), limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []mediaRow
	for rows.Next() {
		var m mediaRow
		if err := rows.Scan(&m.ID, &m.FileName, &m.Attempts); err != nil {
			return nil, err
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

func (s *Store) deleteMediaRow(ctx context.Context, id string) error {
	_, err := s.db.ExecContext(ctx, `DELETE FROM media_files WHERE id = ?`, id)
	return err
}

// recordFailure guarda a falha e agenda a próxima tentativa. Fica no banco,
// então sobrevive a reinícios do programa.
func (s *Store) recordFailure(ctx context.Context, id string, attempts int, next time.Time, msg string) error {
	_, err := s.db.ExecContext(ctx,
		`UPDATE media_files SET delete_attempts = ?, next_attempt_at = ?, last_error = ? WHERE id = ?`,
		attempts, platform.Unix(next), msg, id)
	return err
}

func (s *Store) knownFile(ctx context.Context, fileName string) (bool, error) {
	var n int
	err := s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM media_files WHERE file_name = ?`, fileName).Scan(&n)
	return n > 0, err
}

// purgeExpiredAuth remove sessões e convites vencidos há mais de um dia.
func (s *Store) purgeExpiredAuth(ctx context.Context, cutoff time.Time) (sessions, invites int64, err error) {
	c := platform.Unix(cutoff)
	res, err := s.db.ExecContext(ctx,
		`DELETE FROM sessions WHERE expires_at <= ? OR (revoked_at IS NOT NULL AND revoked_at <= ?)`, c, c)
	if err != nil {
		return 0, 0, err
	}
	sessions, _ = res.RowsAffected()
	res, err = s.db.ExecContext(ctx,
		`DELETE FROM group_invites WHERE expires_at <= ? OR (used_at IS NOT NULL AND used_at <= ?)`, c, c)
	if err != nil {
		return sessions, 0, err
	}
	invites, _ = res.RowsAffected()
	return sessions, invites, nil
}
