package groups

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

// Store é só SQL. As transações (create/join/leave) ficam aqui porque são o que
// garante a consistência: o banco está configurado com _txlock=immediate, então
// cada transação reserva a escrita ao começar e as demais esperam a sua vez.
type Store struct{ db *sql.DB }

func (s *Store) membership(ctx context.Context, userID string) (Membership, bool, error) {
	var m Membership
	err := s.db.QueryRowContext(ctx,
		`SELECT group_id, role FROM group_members WHERE user_id = ?`, userID).Scan(&m.GroupID, &m.Role)
	if errors.Is(err, sql.ErrNoRows) {
		return Membership{}, false, nil
	}
	return m, err == nil, err
}

func (s *Store) isMember(ctx context.Context, userID, groupID string) (bool, error) {
	var n int
	err := s.db.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM group_members WHERE user_id = ? AND group_id = ?`, userID, groupID).Scan(&n)
	return n > 0, err
}

func (s *Store) group(ctx context.Context, groupID string) (Group, error) {
	var g Group
	var created int64
	err := s.db.QueryRowContext(ctx,
		`SELECT id, name, created_at, color, theme, avatar FROM groups WHERE id = ?`, groupID).Scan(&g.ID, &g.Name, &created, &g.Color, &g.Theme, &g.Avatar)
	g.CreatedAt = platform.FromUnix(created)
	return g, err
}

func (s *Store) members(ctx context.Context, groupID string) ([]Member, error) {
	rows, err := s.db.QueryContext(ctx,
		`SELECT m.user_id, u.display_name, m.role, m.joined_at
		   FROM group_members m JOIN users u ON u.id = m.user_id
		  WHERE m.group_id = ?
		  ORDER BY m.joined_at, m.user_id`, groupID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Member{}
	for rows.Next() {
		var m Member
		var joined int64
		if err := rows.Scan(&m.UserID, &m.DisplayName, &m.Role, &joined); err != nil {
			return nil, err
		}
		m.JoinedAt = platform.FromUnix(joined)
		out = append(out, m)
	}
	return out, rows.Err()
}

// createGroup cria a roda e já coloca o criador como dono, na mesma transação.
// Se a pessoa já estiver em uma roda, a chave primária de group_members recusa.
func (s *Store) createGroup(ctx context.Context, g Group, ownerID string, now time.Time) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	if _, err := tx.ExecContext(ctx,
		`INSERT INTO groups (id, name, created_by, created_at) VALUES (?, ?, ?, ?)`,
		g.ID, g.Name, ownerID, platform.Unix(now)); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx,
		`INSERT INTO group_members (user_id, group_id, role, joined_at) VALUES (?, ?, 'owner', ?)`,
		ownerID, g.ID, platform.Unix(now)); err != nil {
		return err
	}
	return tx.Commit()
}

func (s *Store) insertInvite(ctx context.Context, id, groupID, codeHash, createdBy string, created, expires time.Time) error {
	_, err := s.db.ExecContext(ctx,
		`INSERT INTO group_invites (id, group_id, code_hash, created_by, created_at, expires_at)
		 VALUES (?, ?, ?, ?, ?, ?)`,
		id, groupID, codeHash, createdBy, platform.Unix(created), platform.Unix(expires))
	return err
}

// joinWithInvite faz TUDO numa transação: validar o convite, conferir se a
// pessoa já está em roda, contar participantes, inserir e consumir o convite.
// Como a transação já começa reservando a escrita, duas entradas simultâneas
// não conseguem passar juntas pela contagem — o limite de participantes vale
// mesmo sob concorrência.
func (s *Store) joinWithInvite(ctx context.Context, userID, codeHash string, now time.Time, maxMembers int) (string, error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return "", err
	}
	defer tx.Rollback()

	var inviteID, groupID string
	var expires int64
	var usedAt sql.NullInt64
	err = tx.QueryRowContext(ctx,
		`SELECT id, group_id, expires_at, used_at FROM group_invites WHERE code_hash = ?`, codeHash).
		Scan(&inviteID, &groupID, &expires, &usedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return "", ErrInviteInvalid
	}
	if err != nil {
		return "", err
	}
	if usedAt.Valid || expires <= platform.Unix(now) {
		return "", ErrInviteInvalid
	}

	var already int
	if err := tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM group_members WHERE user_id = ?`, userID).Scan(&already); err != nil {
		return "", err
	}
	if already > 0 {
		return "", ErrAlreadyInGroup
	}

	var count int
	if err := tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM group_members WHERE group_id = ?`, groupID).Scan(&count); err != nil {
		return "", err
	}
	if count >= maxMembers {
		return "", ErrGroupFull
	}

	if _, err := tx.ExecContext(ctx,
		`INSERT INTO group_members (user_id, group_id, role, joined_at) VALUES (?, ?, 'member', ?)`,
		userID, groupID, platform.Unix(now)); err != nil {
		return "", err
	}
	if _, err := tx.ExecContext(ctx,
		`UPDATE group_invites SET used_by = ?, used_at = ? WHERE id = ?`,
		userID, platform.Unix(now), inviteID); err != nil {
		return "", err
	}
	return groupID, tx.Commit()
}

// leave remove a pessoa da roda. Se era a dona, o participante mais antigo vira
// dono; se ninguém sobra, os convites pendentes da roda são apagados.
func (s *Store) leave(ctx context.Context, userID string) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	var groupID, role string
	err = tx.QueryRowContext(ctx, `SELECT group_id, role FROM group_members WHERE user_id = ?`, userID).Scan(&groupID, &role)
	if errors.Is(err, sql.ErrNoRows) {
		return ErrNotInGroup
	}
	if err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM group_members WHERE user_id = ?`, userID); err != nil {
		return err
	}

	var successor string
	err = tx.QueryRowContext(ctx,
		`SELECT user_id FROM group_members WHERE group_id = ? ORDER BY joined_at, user_id LIMIT 1`, groupID).Scan(&successor)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		if _, err := tx.ExecContext(ctx, `DELETE FROM group_invites WHERE group_id = ?`, groupID); err != nil {
			return err
		}
	case err != nil:
		return err
	case role == "owner":
		if _, err := tx.ExecContext(ctx, `UPDATE group_members SET role = 'owner' WHERE user_id = ?`, successor); err != nil {
			return err
		}
	}
	return tx.Commit()
}
