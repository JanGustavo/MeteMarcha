// Package groups cuida das rodas: criação, participantes, convites e a
// pergunta "esta pessoa pertence a esta roda?", usada pelos outros módulos.
package groups

import (
	"context"
	"crypto/rand"
	"database/sql"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

type Group struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

type Member struct {
	UserID      string    `json:"user_id"`
	DisplayName string    `json:"display_name"`
	Role        string    `json:"role"` // "owner" ou "member"
	JoinedAt    time.Time `json:"joined_at"`
}

// Membership diz a qual roda a pessoa pertence (no piloto, no máximo uma).
type Membership struct {
	GroupID string
	Role    string
}

var (
	ErrNotInGroup     = platform.NewError(http.StatusForbidden, "not_in_group", "Você não participa de nenhuma roda.")
	ErrAlreadyInGroup = platform.NewError(http.StatusConflict, "already_in_group", "Você já participa de uma roda. Saia dela antes de entrar em outra.")
	ErrGroupFull      = platform.NewError(http.StatusConflict, "group_full", "Esta roda já atingiu o limite de participantes.")
	// Convite inexistente, expirado ou já usado respondem igual: quem tenta
	// adivinhar códigos não descobre nada.
	ErrInviteInvalid = platform.NewError(http.StatusNotFound, "invite_invalid", "Convite inválido, expirado ou já utilizado.")
)

type Service struct {
	store      *Store
	now        platform.Clock
	maxMembers int
	inviteTTL  time.Duration
}

func NewService(db *sql.DB, cfg platform.Config, now platform.Clock) *Service {
	return &Service{store: &Store{db: db}, now: now, maxMembers: cfg.GroupMaxMembers, inviteTTL: cfg.InviteTTL}
}

func (s *Service) MaxMembers() int { return s.maxMembers }

func (s *Service) Create(ctx context.Context, userID, name string) (Group, error) {
	name = strings.TrimSpace(name)
	if n := utf8.RuneCountInString(name); n < 1 || n > 40 {
		return Group{}, platform.NewError(http.StatusUnprocessableEntity, "invalid_name", "O nome da roda deve ter de 1 a 40 caracteres.")
	}
	now := s.now().UTC()
	g := Group{ID: platform.NewID(), Name: name, CreatedAt: now}
	if err := s.store.createGroup(ctx, g, userID, now); err != nil {
		if platform.IsUniqueViolation(err) {
			return Group{}, ErrAlreadyInGroup
		}
		return Group{}, err
	}
	g.CreatedAt = platform.FromUnix(platform.Unix(now))
	return g, nil
}

// Mine devolve a roda da pessoa e seus participantes.
func (s *Service) Mine(ctx context.Context, userID string) (Group, []Member, error) {
	m, ok, err := s.store.membership(ctx, userID)
	if err != nil {
		return Group{}, nil, err
	}
	if !ok {
		return Group{}, nil, ErrNotInGroup
	}
	g, err := s.store.group(ctx, m.GroupID)
	if err != nil {
		return Group{}, nil, err
	}
	members, err := s.store.members(ctx, m.GroupID)
	return g, members, err
}

// MembershipOf é usada pelo módulo stories. Fonte única da verdade sobre
// "quem está em qual roda agora".
func (s *Service) MembershipOf(ctx context.Context, userID string) (Membership, bool, error) {
	return s.store.membership(ctx, userID)
}

// IsMember pergunta se a pessoa participa AGORA daquela roda.
func (s *Service) IsMember(ctx context.Context, userID, groupID string) (bool, error) {
	return s.store.isMember(ctx, userID, groupID)
}

// CreateInvite gera um código de uso único. Qualquer participante pode convidar
// (é um grupo de amigos). O código só é devolvido agora; no banco fica o hash.
func (s *Service) CreateInvite(ctx context.Context, userID string) (string, time.Time, error) {
	m, ok, err := s.store.membership(ctx, userID)
	if err != nil {
		return "", time.Time{}, err
	}
	if !ok {
		return "", time.Time{}, ErrNotInGroup
	}
	code, err := newInviteCode()
	if err != nil {
		return "", time.Time{}, err
	}
	now := s.now().UTC()
	expires := now.Add(s.inviteTTL)
	if err := s.store.insertInvite(ctx, platform.NewID(), m.GroupID, platform.HashToken(normalizeCode(code)), userID, now, expires); err != nil {
		return "", time.Time{}, err
	}
	return code, platform.FromUnix(platform.Unix(expires)), nil
}

func (s *Service) Join(ctx context.Context, userID, code string) (Group, error) {
	groupID, err := s.store.joinWithInvite(ctx, userID, platform.HashToken(normalizeCode(code)), s.now(), s.maxMembers)
	if err != nil {
		return Group{}, err
	}
	return s.store.group(ctx, groupID)
}

func (s *Service) Leave(ctx context.Context, userID string) error {
	return s.store.leave(ctx, userID)
}

// Alfabeto sem 0/O/1/I/L: evita erros ao digitar o código ditado por um amigo.
const inviteAlphabet = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"

// newInviteCode gera algo como "K7M2P-9QXAB" (10 símbolos ≈ 49 bits).
func newInviteCode() (string, error) {
	b := make([]byte, 10)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	out := make([]byte, 0, 11)
	for i, v := range b {
		if i == 5 {
			out = append(out, '-')
		}
		out = append(out, inviteAlphabet[int(v)%len(inviteAlphabet)])
	}
	return string(out), nil
}

// normalizeCode aceita o código em minúsculas, com ou sem hífen/espaços.
func normalizeCode(code string) string {
	code = strings.ToUpper(strings.TrimSpace(code))
	code = strings.ReplaceAll(code, "-", "")
	return strings.ReplaceAll(code, " ", "")
}
