package media

import (
	"bytes"
	"image"
	"image/color"
	"image/draw"
	"image/jpeg"
	_ "image/png" // registra o decodificador de PNG para image.Decode
	"io"
	"net/http"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

var (
	ErrPhotoTooLarge    = platform.NewError(http.StatusRequestEntityTooLarge, "photo_too_large", "A foto excede o tamanho máximo permitido.")
	ErrUnsupportedPhoto = platform.NewError(http.StatusUnsupportedMediaType, "unsupported_photo_type", "Formato não suportado. Envie uma foto JPEG ou PNG.")
	ErrInvalidPhoto     = platform.NewError(http.StatusUnprocessableEntity, "invalid_photo", "O arquivo enviado não é uma imagem válida ou tem dimensões acima do permitido.")
)

// PrepareJPEG valida o upload e devolve uma foto JPEG "limpa".
//
// Validações (nesta ordem, da mais barata para a mais cara):
//  1. tamanho em bytes;
//  2. tipo REAL do conteúdo (olha os primeiros bytes; ignora nome e Content-Type do cliente);
//  3. dimensões, lidas do cabeçalho ANTES de decodificar (evita imagens-bomba);
//  4. decodificação completa, para garantir que o arquivo não está corrompido.
//
// Depois a imagem é regravada como JPEG. Isso tem um efeito de privacidade
// importante: todos os metadados (EXIF, incluindo GPS e modelo do aparelho) são
// descartados. Consequência para o Flutter: a orientação EXIF também some, então
// o app deve enviar a foto já com a rotação aplicada nos pixels.
func PrepareJPEG(r io.Reader, maxBytes int64, maxSide int) ([]byte, error) {
	data, err := io.ReadAll(io.LimitReader(r, maxBytes+1))
	if err != nil {
		return nil, err
	}
	if int64(len(data)) > maxBytes {
		return nil, ErrPhotoTooLarge
	}

	switch http.DetectContentType(data) {
	case "image/jpeg", "image/png":
	default:
		return nil, ErrUnsupportedPhoto
	}

	cfg, _, err := image.DecodeConfig(bytes.NewReader(data))
	if err != nil || cfg.Width < 1 || cfg.Height < 1 || cfg.Width > maxSide || cfg.Height > maxSide {
		return nil, ErrInvalidPhoto
	}

	img, _, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		return nil, ErrInvalidPhoto
	}

	// Desenha sobre fundo branco: PNG com transparência não vira preto no JPEG.
	b := img.Bounds()
	canvas := image.NewRGBA(image.Rect(0, 0, b.Dx(), b.Dy()))
	draw.Draw(canvas, canvas.Bounds(), image.NewUniform(color.White), image.Point{}, draw.Src)
	draw.Draw(canvas, canvas.Bounds(), img, b.Min, draw.Over)

	var out bytes.Buffer
	if err := jpeg.Encode(&out, canvas, &jpeg.Options{Quality: 85}); err != nil {
		return nil, err
	}
	return out.Bytes(), nil
}
