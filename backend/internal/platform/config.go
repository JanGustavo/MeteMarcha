// Package platform reúne a infraestrutura compartilhada e pequena:
// configuração, banco, migrações, respostas HTTP e utilidades.
// Regras de negócio NÃO ficam aqui.
package platform

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config guarda os limites e prazos do piloto. Credenciais da IA são lidas
// separadamente pelo módulo workoutai e nunca fazem parte das respostas da API.
type Config struct {
	Addr     string // endereço de escuta, ex.: ":8080"
	DBPath   string // arquivo SQLite
	MediaDir string // fotos enviadas (privadas)
	MusicDir string // catálogo de músicas (catalog.json + arquivos)

	GroupMaxMembers int
	InviteTTL       time.Duration
	SessionTTL      time.Duration

	// Prazos contados a partir da publicação do story.
	StoryVisibleFor     time.Duration // até aqui: visível aos participantes
	StoryRecoverableFor time.Duration // até aqui: só o autor baixa a foto; depois, nada

	MaxPhotoBytes int64         // tamanho máximo do arquivo enviado
	MaxPhotoSide  int           // maior lado permitido, em pixels
	MaxClip       time.Duration // duração máxima do trecho de música

	CleanupInterval time.Duration
	OrphanGrace     time.Duration // idade mínima para um arquivo sem registro ser considerado órfão

	PasswordMemoryKiB uint32 // custo de memória do argon2id
}

// DefaultConfig devolve os valores padrão do piloto.
func DefaultConfig() Config {
	return Config{
		Addr:                ":8080",
		DBPath:              "./data/metemarcha.db",
		MediaDir:            "./data/media",
		MusicDir:            "./data/music",
		GroupMaxMembers:     10,
		InviteTTL:           7 * 24 * time.Hour,
		SessionTTL:          30 * 24 * time.Hour,
		StoryVisibleFor:     24 * time.Hour,
		StoryRecoverableFor: 72 * time.Hour,
		MaxPhotoBytes:       8 << 20,
		MaxPhotoSide:        4096,
		MaxClip:             30 * time.Second,
		CleanupInterval:     15 * time.Minute,
		OrphanGrace:         time.Hour,
		PasswordMemoryKiB:   64 * 1024,
	}
}

// LoadConfig parte dos padrões e sobrescreve com as variáveis MM_* do ambiente.
func LoadConfig() (Config, error) {
	c := DefaultConfig()
	var problems []string

	str := func(key string, dst *string) {
		if v := os.Getenv(key); v != "" {
			*dst = v
		}
	}
	integer := func(key string, dst *int) {
		if v := os.Getenv(key); v != "" {
			n, err := strconv.Atoi(v)
			if err != nil {
				problems = append(problems, fmt.Sprintf("%s: %q não é um número inteiro", key, v))
				return
			}
			*dst = n
		}
	}
	duration := func(key string, dst *time.Duration) {
		if v := os.Getenv(key); v != "" {
			d, err := time.ParseDuration(v)
			if err != nil {
				problems = append(problems, fmt.Sprintf("%s: %q não é uma duração (use, por exemplo, 24h ou 15m)", key, v))
				return
			}
			*dst = d
		}
	}

	str("MM_ADDR", &c.Addr)
	str("MM_DB_PATH", &c.DBPath)
	str("MM_MEDIA_DIR", &c.MediaDir)
	str("MM_MUSIC_DIR", &c.MusicDir)
	integer("MM_GROUP_MAX_MEMBERS", &c.GroupMaxMembers)
	duration("MM_INVITE_TTL", &c.InviteTTL)
	duration("MM_SESSION_TTL", &c.SessionTTL)
	duration("MM_STORY_VISIBLE_FOR", &c.StoryVisibleFor)
	duration("MM_STORY_RECOVERABLE_FOR", &c.StoryRecoverableFor)
	duration("MM_MAX_CLIP", &c.MaxClip)
	duration("MM_CLEANUP_INTERVAL", &c.CleanupInterval)
	duration("MM_ORPHAN_GRACE", &c.OrphanGrace)
	integer("MM_MAX_PHOTO_SIDE", &c.MaxPhotoSide)

	if v := os.Getenv("MM_MAX_PHOTO_BYTES"); v != "" {
		n, err := strconv.ParseInt(v, 10, 64)
		if err != nil {
			problems = append(problems, fmt.Sprintf("MM_MAX_PHOTO_BYTES: %q não é um número inteiro", v))
		} else {
			c.MaxPhotoBytes = n
		}
	}
	if v := os.Getenv("MM_PASSWORD_MEMORY_KIB"); v != "" {
		n, err := strconv.ParseUint(v, 10, 32)
		if err != nil {
			problems = append(problems, fmt.Sprintf("MM_PASSWORD_MEMORY_KIB: %q não é um número inteiro", v))
		} else {
			c.PasswordMemoryKiB = uint32(n)
		}
	}

	if len(problems) > 0 {
		return c, fmt.Errorf("configuração inválida:\n  %s", strings.Join(problems, "\n  "))
	}
	return c, c.Validate()
}

// Validate recusa combinações que quebrariam as regras do piloto.
func (c Config) Validate() error {
	var problems []string
	if c.GroupMaxMembers < 1 {
		problems = append(problems, "MM_GROUP_MAX_MEMBERS deve ser pelo menos 1")
	}
	if c.StoryVisibleFor <= 0 || c.StoryRecoverableFor <= c.StoryVisibleFor {
		problems = append(problems, "MM_STORY_RECOVERABLE_FOR deve ser maior que MM_STORY_VISIBLE_FOR (e ambos positivos)")
	}
	if c.MaxPhotoBytes < 1024 {
		problems = append(problems, "MM_MAX_PHOTO_BYTES deve ser pelo menos 1024")
	}
	if c.MaxPhotoSide < 16 {
		problems = append(problems, "MM_MAX_PHOTO_SIDE deve ser pelo menos 16")
	}
	if c.CleanupInterval <= 0 || c.OrphanGrace <= 0 || c.InviteTTL <= 0 || c.SessionTTL <= 0 || c.MaxClip <= 0 {
		problems = append(problems, "durações (TTL, limpeza, trecho) devem ser positivas")
	}
	if c.PasswordMemoryKiB < 8 {
		problems = append(problems, "MM_PASSWORD_MEMORY_KIB deve ser pelo menos 8")
	}
	if len(problems) > 0 {
		return fmt.Errorf("configuração inválida:\n  %s", strings.Join(problems, "\n  "))
	}
	return nil
}
