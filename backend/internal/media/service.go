// Package media recebe e entrega fotos (sempre com autenticação e autorização)
// e mantém o catálogo de músicas.
package media

import (
	"context"
	"database/sql"
	"errors"
	"io"
	"os"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

type Service struct {
	db       *sql.DB
	storage  *Storage
	now      platform.Clock
	maxBytes int64
	maxSide  int
	musicDir string
}

func NewService(db *sql.DB, storage *Storage, cfg platform.Config, now platform.Clock) *Service {
	return &Service{db: db, storage: storage, now: now, maxBytes: cfg.MaxPhotoBytes, maxSide: cfg.MaxPhotoSide, musicDir: cfg.MusicDir}
}

// Storage expõe o armazenamento para a limpeza (único outro módulo que precisa dele).
func (s *Service) Storage() *Storage { return s.storage }

// StorePhoto valida, grava no disco e registra a foto. Devolve o id do registro.
// Ordem: arquivo primeiro, linha no banco depois. Se o programa cair no meio,
// o pior caso é um arquivo sem registro — a limpeza recolhe esse órfão.
func (s *Service) StorePhoto(ctx context.Context, ownerID string, r io.Reader) (string, error) {
	data, err := PrepareJPEG(r, s.maxBytes, s.maxSide)
	if err != nil {
		return "", err
	}
	name, err := s.storage.WritePhoto(data)
	if err != nil {
		return "", err
	}
	id := platform.NewID()
	_, err = s.db.ExecContext(ctx,
		`INSERT INTO media_files (id, owner_id, file_name, content_type, size_bytes, created_at)
		 VALUES (?, ?, ?, 'image/jpeg', ?, ?)`,
		id, ownerID, name, len(data), platform.Unix(s.now()))
	if err != nil {
		s.storage.DeletePhoto(name)
		return "", err
	}
	return id, nil
}

// DiscardPhoto desfaz um StorePhoto cujo story não chegou a ser criado.
// É "melhor esforço": se algo falhar, a limpeza tenta de novo mais tarde.
func (s *Service) DiscardPhoto(ctx context.Context, mediaID string) {
	var name string
	if err := s.db.QueryRowContext(ctx, `SELECT file_name FROM media_files WHERE id = ?`, mediaID).Scan(&name); err != nil {
		return
	}
	if _, err := s.db.ExecContext(ctx, `DELETE FROM media_files WHERE id = ?`, mediaID); err != nil {
		return // ainda referenciada por um story: não apagar
	}
	s.storage.DeletePhoto(name)
}

// PhotoFile é a foto aberta, pronta para ser entregue.
type PhotoFile struct {
	File        *os.File
	ContentType string
	ModTime     time.Time
}

var ErrPhotoMissing = platform.NewError(404, "not_found", "Foto não encontrada.")

// PhotoFile NÃO verifica permissão: quem chama (o handler, depois de consultar
// stories) já autorizou o acesso.
func (s *Service) PhotoFile(ctx context.Context, mediaID string) (*PhotoFile, error) {
	var name, contentType string
	var created int64
	err := s.db.QueryRowContext(ctx,
		`SELECT file_name, content_type, created_at FROM media_files WHERE id = ?`, mediaID).Scan(&name, &contentType, &created)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrPhotoMissing
	}
	if err != nil {
		return nil, err
	}
	f, err := s.storage.OpenPhoto(name)
	if errors.Is(err, os.ErrNotExist) {
		return nil, ErrPhotoMissing
	}
	if err != nil {
		return nil, err
	}
	return &PhotoFile{File: f, ContentType: contentType, ModTime: platform.FromUnix(created)}, nil
}
