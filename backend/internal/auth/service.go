// Package auth cuida de cadastro, login, logout, sessões e da identificação
// do usuário em cada requisição.
package auth

import (
	"context"
	"database/sql"
	"net/http"
	"net/mail"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

type User struct {
	ID          string    `json:"id"`
	Email       string    `json:"email"`
	DisplayName string    `json:"display_name"`
	CreatedAt   time.Time `json:"created_at"`
}

// Session é o que o celular recebe ao entrar. O Token só aparece aqui, uma vez.
type Session struct {
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
}

var (
	ErrInvalidCredentials = platform.NewError(http.StatusUnauthorized, "invalid_credentials", "E-mail ou senha incorretos.")
	ErrUnauthorized       = platform.NewError(http.StatusUnauthorized, "unauthorized", "Sessão ausente, inválida ou expirada. Entre novamente.")
	ErrEmailTaken         = platform.NewError(http.StatusConflict, "email_taken", "Já existe uma conta com este e-mail.")
)

type Service struct {
	store      *Store
	now        platform.Clock
	sessionTTL time.Duration
	memoryKiB  uint32
	// decoyHash é usado quando o e-mail não existe, para o login gastar o mesmo
	// tempo e não revelar quais e-mails têm conta.
	decoyHash string
}

func NewService(db *sql.DB, cfg platform.Config, now platform.Clock) (*Service, error) {
	decoy, err := hashPassword("decoy-password", cfg.PasswordMemoryKiB)
	if err != nil {
		return nil, err
	}
	return &Service{
		store:      &Store{db: db},
		now:        now,
		sessionTTL: cfg.SessionTTL,
		memoryKiB:  cfg.PasswordMemoryKiB,
		decoyHash:  decoy,
	}, nil
}

// Register cria a conta e já abre uma sessão. O cadastro é aberto neste piloto:
// quem não está numa roda não consegue publicar nem ver nada.
func (s *Service) Register(ctx context.Context, email, displayName, password string) (User, Session, error) {
	email, err := normalizeEmail(email)
	if err != nil {
		return User{}, Session{}, err
	}
	displayName = strings.TrimSpace(displayName)
	if n := utf8.RuneCountInString(displayName); n < 1 || n > 40 {
		return User{}, Session{}, invalid("invalid_display_name", "O nome deve ter de 1 a 40 caracteres.")
	}
	if n := utf8.RuneCountInString(password); n < 8 || len(password) > 128 {
		return User{}, Session{}, invalid("invalid_password", "A senha deve ter de 8 a 128 caracteres.")
	}

	hash, err := hashPassword(password, s.memoryKiB)
	if err != nil {
		return User{}, Session{}, err
	}
	user := User{ID: platform.NewID(), Email: email, DisplayName: displayName, CreatedAt: platform.FromUnix(platform.Unix(s.now()))}
	if err := s.store.insertUser(ctx, user, hash); err != nil {
		if platform.IsUniqueViolation(err) {
			return User{}, Session{}, ErrEmailTaken
		}
		return User{}, Session{}, err
	}
	session, err := s.openSession(ctx, user.ID)
	return user, session, err
}

func (s *Service) Login(ctx context.Context, email, password string) (User, Session, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	row, found, err := s.store.userByEmail(ctx, email)
	if err != nil {
		return User{}, Session{}, err
	}
	hash := s.decoyHash
	if found {
		hash = row.passwordHash
	}
	ok, verr := verifyPassword(password, hash)
	if verr != nil {
		return User{}, Session{}, verr
	}
	if !found || !ok {
		return User{}, Session{}, ErrInvalidCredentials
	}
	session, err := s.openSession(ctx, row.ID)
	return row.User, session, err
}

// Logout revoga a sessão do token informado (o token deixa de funcionar na hora).
func (s *Service) Logout(ctx context.Context, token string) error {
	return s.store.revokeSession(ctx, platform.HashToken(token), s.now())
}

// Authenticate transforma um token em usuário, ou devolve ErrUnauthorized.
func (s *Service) Authenticate(ctx context.Context, token string) (User, error) {
	if token == "" {
		return User{}, ErrUnauthorized
	}
	user, found, err := s.store.userBySessionToken(ctx, platform.HashToken(token), s.now())
	if err != nil {
		return User{}, err
	}
	if !found {
		return User{}, ErrUnauthorized
	}
	return user, nil
}

func (s *Service) openSession(ctx context.Context, userID string) (Session, error) {
	token := platform.NewToken()
	now := platform.FromUnix(platform.Unix(s.now()))
	expires := now.Add(s.sessionTTL)
	if err := s.store.insertSession(ctx, platform.NewID(), userID, platform.HashToken(token), now, expires); err != nil {
		return Session{}, err
	}
	return Session{Token: token, ExpiresAt: expires}, nil
}

func normalizeEmail(raw string) (string, error) {
	email := strings.ToLower(strings.TrimSpace(raw))
	addr, err := mail.ParseAddress(email)
	// ParseAddress aceita "Nome <a@b.c>"; exigimos só o endereço puro.
	if err != nil || addr.Address != email || len(email) > 254 {
		return "", invalid("invalid_email", "Informe um e-mail válido.")
	}
	return email, nil
}

func invalid(code, msg string) *platform.APIError {
	return platform.NewError(http.StatusUnprocessableEntity, code, msg)
}
