package media

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"time"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

// Storage guarda as fotos no disco da VPS, fora de qualquer pasta pública.
//
//	<MediaDir>/photos/<id>.jpg   fotos definitivas
//	<MediaDir>/tmp/              envios em andamento
//
// O nome do arquivo é SEMPRE gerado aqui (32 hex + .jpg). Nada que vem do
// cliente entra no caminho, então não há como escapar da pasta ("../").
type Storage struct {
	photosDir string
	tmpDir    string
}

var photoNameRe = regexp.MustCompile(`^[0-9a-f]{32}\.jpg$`)

func NewStorage(root string) (*Storage, error) {
	s := &Storage{photosDir: filepath.Join(root, "photos"), tmpDir: filepath.Join(root, "tmp")}
	for _, dir := range []string{s.photosDir, s.tmpDir} {
		if err := os.MkdirAll(dir, 0o750); err != nil {
			return nil, fmt.Errorf("criar pasta de mídia: %w", err)
		}
	}
	return s, nil
}

// WritePhoto grava em tmp/ e só depois "move" para photos/. Mover (rename) é
// atômico no mesmo disco: ninguém vê um arquivo pela metade. Se o programa
// morrer no meio, sobra um arquivo em tmp/ — a limpeza apaga depois.
func (s *Storage) WritePhoto(data []byte) (string, error) {
	tmp, err := os.CreateTemp(s.tmpDir, "upload-*")
	if err != nil {
		return "", err
	}
	tmpName := tmp.Name()
	cleanup := func() { os.Remove(tmpName) }

	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		cleanup()
		return "", err
	}
	if err := tmp.Sync(); err != nil {
		tmp.Close()
		cleanup()
		return "", err
	}
	if err := tmp.Close(); err != nil {
		cleanup()
		return "", err
	}

	name := platform.NewID() + ".jpg"
	if err := os.Rename(tmpName, filepath.Join(s.photosDir, name)); err != nil {
		cleanup()
		return "", err
	}
	return name, nil
}

func (s *Storage) OpenPhoto(name string) (*os.File, error) {
	if !photoNameRe.MatchString(name) {
		return nil, fmt.Errorf("nome de foto inválido: %q", name)
	}
	return os.Open(filepath.Join(s.photosDir, name))
}

// DeletePhoto apaga a foto. Arquivo que já não existe NÃO é erro: o objetivo
// ("não existir mais") já foi cumprido, e isso torna a exclusão repetível.
func (s *Storage) DeletePhoto(name string) error {
	if !photoNameRe.MatchString(name) {
		return fmt.Errorf("nome de foto inválido: %q", name)
	}
	err := os.Remove(filepath.Join(s.photosDir, name))
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	return nil
}

// StoredFile descreve um arquivo encontrado em disco (usado pela limpeza).
type StoredFile struct {
	Name    string
	ModTime time.Time
}

func (s *Storage) ListPhotos() ([]StoredFile, error) { return list(s.photosDir) }
func (s *Storage) ListTemp() ([]StoredFile, error)   { return list(s.tmpDir) }

func (s *Storage) DeleteTemp(name string) error {
	if name != filepath.Base(name) {
		return fmt.Errorf("nome inválido: %q", name)
	}
	err := os.Remove(filepath.Join(s.tmpDir, name))
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	return nil
}

func list(dir string) ([]StoredFile, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	var out []StoredFile
	for _, e := range entries {
		if !e.Type().IsRegular() {
			continue
		}
		info, err := e.Info()
		if err != nil {
			continue // sumiu entre a listagem e a leitura; ignorar
		}
		out = append(out, StoredFile{Name: e.Name(), ModTime: info.ModTime()})
	}
	return out, nil
}
