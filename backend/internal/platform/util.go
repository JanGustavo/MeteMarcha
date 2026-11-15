package platform

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"time"
)

// Clock devolve "agora". Os serviços recebem um Clock em vez de chamar time.Now
// diretamente, para os testes poderem avançar o relógio (24 h, 72 h) sem esperar.
type Clock func() time.Time

func SystemClock() time.Time { return time.Now() }

// NewID gera um identificador aleatório de 128 bits (32 caracteres hex).
// Ids públicos nunca são sequenciais, então não dá para "adivinhar" o próximo.
func NewID() string {
	b := make([]byte, 16)
	mustRandom(b)
	return hex.EncodeToString(b)
}

// NewToken gera um token de sessão aleatório de 256 bits.
func NewToken() string {
	b := make([]byte, 32)
	mustRandom(b)
	return base64.RawURLEncoding.EncodeToString(b)
}

// HashToken devolve o SHA-256 (hex) de um token ou código. Só guardamos o hash:
// se o banco vazar, os tokens não vazam junto. SHA-256 basta aqui porque o
// valor original já é aleatório e longo (diferente de uma senha).
func HashToken(s string) string {
	sum := sha256.Sum256([]byte(s))
	return hex.EncodeToString(sum[:])
}

func mustRandom(b []byte) {
	if _, err := rand.Read(b); err != nil {
		// Sem fonte de aleatoriedade não há como operar com segurança.
		panic("crypto/rand indisponível: " + err.Error())
	}
}

// Unix e FromUnix convertem entre time.Time e o formato guardado no banco.
func Unix(t time.Time) int64       { return t.Unix() }
func FromUnix(sec int64) time.Time { return time.Unix(sec, 0).UTC() }
