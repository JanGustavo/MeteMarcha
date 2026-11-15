package auth

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

// Store é a camada de persistência: só SQL, nenhuma regra de negócio.
type Store struct{ db *sql.DB }

type userRow struct {
	User
	passwordHash string
}

func (s *Store) insertUser(ctx context.Context, u User, passwordHash string) error {
	_, err := s.db.ExecContext(ctx,
		`INSERT INTO users (id, email, display_name, password_hash, created_at) VALUES (?, ?, ?, ?, ?)`,
		u.ID, u.Email, u.DisplayName, passwordHash, platform.Unix(u.CreatedAt))
	return err
}

func (s *Store) userByEmail(ctx context.Context, email string) (userRow, bool, error) {
	var r userRow
	var created int64
	err := s.db.QueryRowContext(ctx,
		`SELECT id, email, display_name, password_hash, created_at FROM users WHERE email = ?`, email).
		Scan(&r.ID, &r.Email, &r.DisplayName, &r.passwordHash, &created)
	if errors.Is(err, sql.ErrNoRows) {
		return userRow{}, false, nil
	}
	if err != nil {
		return userRow{}, false, err
	}
	r.CreatedAt = platform.FromUnix(created)
	return r, true, nil
}

func (s *Store) insertSession(ctx context.Context, id, userID, tokenHash string, created, expires time.Time) error {
	_, err := s.db.ExecContext(ctx,
		`INSERT INTO sessions (id, user_id, token_hash, created_at, expires_at) VALUES (?, ?, ?, ?, ?)`,
		id, userID, tokenHash, platform.Unix(created), platform.Unix(expires))
	return err
}

// userBySessionToken só devolve sessões ativas: não revogadas e não expiradas.
func (s *Store) userBySessionToken(ctx context.Context, tokenHash string, now time.Time) (User, bool, error) {
	var u User
	var created int64
	err := s.db.QueryRowContext(ctx,
		`SELECT u.id, u.email, u.display_name, u.created_at
		   FROM sessions s JOIN users u ON u.id = s.user_id
		  WHERE s.token_hash = ? AND s.revoked_at IS NULL AND s.expires_at > ?`,
		tokenHash, platform.Unix(now)).Scan(&u.ID, &u.Email, &u.DisplayName, &created)
	if errors.Is(err, sql.ErrNoRows) {
		return User{}, false, nil
	}
	if err != nil {
		return User{}, false, err
	}
	u.CreatedAt = platform.FromUnix(created)
	return u, true, nil
}

func (s *Store) revokeSession(ctx context.Context, tokenHash string, now time.Time) error {
	_, err := s.db.ExecContext(ctx,
		`UPDATE sessions SET revoked_at = ? WHERE token_hash = ? AND revoked_at IS NULL`,
		platform.Unix(now), tokenHash)
	return err
}
