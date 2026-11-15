package media

import (
	"bytes"
	"image"
	"image/jpeg"
	"testing"
)

func sample(w, h int) []byte {
	var buf bytes.Buffer
	jpeg.Encode(&buf, image.NewRGBA(image.Rect(0, 0, w, h)), nil)
	return buf.Bytes()
}

func TestPrepareJPEG(t *testing.T) {
	good := sample(40, 30)
	out, err := PrepareJPEG(bytes.NewReader(good), 1<<20, 100)
	if err != nil {
		t.Fatal(err)
	}
	cfg, format, err := image.DecodeConfig(bytes.NewReader(out))
	if err != nil || format != "jpeg" || cfg.Width != 40 || cfg.Height != 30 {
		t.Errorf("saída inesperada: %v %q %+v", err, format, cfg)
	}

	cases := []struct {
		name string
		data []byte
		max  int64
		side int
		want error
	}{
		{"maior que o limite", good, 100, 100, ErrPhotoTooLarge},
		{"vazio", nil, 1 << 20, 100, ErrUnsupportedPhoto},
		{"texto", []byte("não sou imagem"), 1 << 20, 100, ErrUnsupportedPhoto},
		{"lado acima do limite", sample(200, 10), 1 << 20, 100, ErrInvalidPhoto},
		{"corrompido", good[:len(good)/2], 1 << 20, 100, ErrInvalidPhoto},
	}
	for _, c := range cases {
		if _, err := PrepareJPEG(bytes.NewReader(c.data), c.max, c.side); err != c.want {
			t.Errorf("%s: erro %v; esperado %v", c.name, err, c.want)
		}
	}
}

func TestStorageRejectsUnsafeNames(t *testing.T) {
	s, err := NewStorage(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"../etc/passwd", "a.jpg", "", "0123456789abcdef0123456789abcdef.png", "../0123456789abcdef0123456789abcdef.jpg"} {
		if _, err := s.OpenPhoto(name); err == nil {
			t.Errorf("OpenPhoto(%q) deveria recusar", name)
		}
		if err := s.DeletePhoto(name); err == nil {
			t.Errorf("DeletePhoto(%q) deveria recusar", name)
		}
	}
	name, err := s.WritePhoto([]byte("x"))
	if err != nil {
		t.Fatal(err)
	}
	if err := s.DeletePhoto(name); err != nil {
		t.Fatal(err)
	}
	if err := s.DeletePhoto(name); err != nil {
		t.Errorf("apagar de novo deve ser seguro: %v", err)
	}
}
