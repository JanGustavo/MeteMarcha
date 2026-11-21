// Package stories cuida das publicações: criar, listar o feed, decidir quem pode
// ver a foto em cada fase do prazo e registrar reações.
package stories

import (
	"context"
	"database/sql"
	"encoding/json"
	"io"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/JanGustavo/MeteMarcha/backend/internal/groups"
	"github.com/JanGustavo/MeteMarcha/backend/internal/media"
	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
)

type Story struct {
	WorkoutReport    json.RawMessage `json:"workout_report,omitempty"`
	ID               string          `json:"id"`
	Author           Author          `json:"author"`
	Caption          string          `json:"caption"`
	CreatedAt        time.Time       `json:"created_at"`
	VisibleUntil     time.Time       `json:"visible_until"`     // fim da visibilidade no feed (publicação + 24 h)
	RecoverableUntil time.Time       `json:"recoverable_until"` // fim da recuperação pelo autor (publicação + 72 h)
	PhotoURL         string          `json:"photo_url"`
	Track            *TrackClip      `json:"track"` // null quando não há música
	Reactions        ReactionSummary `json:"reactions"`
	Mine             bool            `json:"mine"`
}

type Author struct {
	ID          string `json:"id"`
	DisplayName string `json:"display_name"`
}

// TrackClip referencia a faixa e o trecho. Foto e áudio ficam separados:
// o Flutter reproduz os dois juntos.
type TrackClip struct {
	ID         string `json:"id"`
	Title      string `json:"title"`
	Artist     string `json:"artist"`
	StartMS    int64  `json:"start_ms"`
	DurationMS int64  `json:"duration_ms"`
	AudioURL   string `json:"audio_url"`
}

type ReactionSummary struct {
	Counts map[string]int `json:"counts"`
	Mine   *string        `json:"mine"` // reação do usuário atual, ou null
}

type clip struct {
	TrackID             string
	StartMS, DurationMS int64
}

var (
	ErrStoryNotFound = platform.NewError(http.StatusNotFound, "not_found", "Story não encontrado.")
	ErrStoryExpired  = platform.NewError(http.StatusGone, "story_expired", "O prazo de recuperação deste story terminou e a foto não está mais disponível.")

	// Tipos de reação permitidos. O Flutter decide qual emoji mostrar para cada um.
	reactionKinds = map[string]bool{"fire": true, "muscle": true, "clap": true, "heart": true}

	requestIDRe = regexp.MustCompile(`^[A-Za-z0-9._:-]{8,100}$`)
)

const maxCaptionRunes = 300

type Service struct {
	store          *Store
	groups         *groups.Service
	media          *media.Service
	now            platform.Clock
	visibleFor     time.Duration
	recoverableFor time.Duration
	maxClip        time.Duration
}

func NewService(db *sql.DB, cfg platform.Config, now platform.Clock, g *groups.Service, m *media.Service) *Service {
	return &Service{
		store: &Store{db: db}, groups: g, media: m, now: now,
		visibleFor: cfg.StoryVisibleFor, recoverableFor: cfg.StoryRecoverableFor, maxClip: cfg.MaxClip,
	}
}

// ---- Regras de prazo --------------------------------------------------------
// Tudo é calculado em segundos inteiros a partir de created_at, a cada
// requisição. A limpeza (módulo cleanup) apaga depois, mas a autorização NUNCA
// depende de a limpeza já ter rodado.

func (s *Service) ageSeconds(created time.Time) int64 { return s.now().Unix() - created.Unix() }
func (s *Service) visibleSeconds() int64              { return int64(s.visibleFor / time.Second) }
func (s *Service) recoverableSeconds() int64          { return int64(s.recoverableFor / time.Second) }

// visibleInFeed: de 0 até (excluindo) 24 h.
func (s *Service) visibleInFeed(created time.Time) bool {
	return s.ageSeconds(created) < s.visibleSeconds()
}

// ---- Publicar -----------------------------------------------------------------

type PublishInput struct {
	Report          string
	AuthorID        string
	RequestID       string // Idempotency-Key: o mesmo valor devolve o mesmo story
	Caption         string
	TrackID         string
	TrackStartMS    *int64
	TrackDurationMS *int64
	Photo           io.Reader
}

// Publish cria o story. O segundo retorno diz se foi criado agora (true) ou se
// era uma repetição de uma publicação anterior (false).
func (s *Service) Publish(ctx context.Context, in PublishInput) (Story, bool, error) {
	if !requestIDRe.MatchString(in.RequestID) {
		return Story{}, false, platform.NewError(http.StatusBadRequest, "invalid_idempotency_key",
			"Envie o cabeçalho Idempotency-Key com 8 a 100 caracteres (letras, números, ponto, dois-pontos, hífen ou sublinhado).")
	}
	membership, ok, err := s.groups.MembershipOf(ctx, in.AuthorID)
	if err != nil {
		return Story{}, false, err
	}
	if !ok {
		return Story{}, false, groups.ErrNotInGroup
	}

	report, err := validateReport(in.Report)
	if err != nil {
		return Story{}, false, err
	}
	caption := strings.TrimSpace(in.Caption)
	if utf8.RuneCountInString(caption) > maxCaptionRunes {
		return Story{}, false, platform.NewError(http.StatusUnprocessableEntity, "invalid_caption", "A legenda pode ter no máximo 300 caracteres.")
	}
	trackClip, err := s.resolveClip(ctx, in)
	if err != nil {
		return Story{}, false, err
	}

	// Repetição (celular reenviou após falha de rede)? Devolve o original ANTES
	// de gravar outra foto.
	if existing, found, err := s.store.byAuthorRequest(ctx, in.AuthorID, in.RequestID); err != nil {
		return Story{}, false, err
	} else if found {
		story, err := s.assembleOne(ctx, existing, in.AuthorID)
		return story, false, err
	}

	mediaID, err := s.media.StorePhoto(ctx, in.AuthorID, in.Photo)
	if err != nil {
		return Story{}, false, err
	}

	err = s.store.insert(ctx, newStory{
		ID: platform.NewID(), AuthorID: in.AuthorID, GroupID: membership.GroupID, MediaID: mediaID,
		Report: report, Caption: caption, RequestID: in.RequestID, Clip: trackClip, CreatedAt: s.now().UTC(),
	})
	if err != nil {
		s.media.DiscardPhoto(ctx, mediaID) // esta foto não será usada
		if platform.IsUniqueViolation(err) {
			// Duas requisições com a mesma chave chegaram juntas; a outra venceu.
			if existing, found, qerr := s.store.byAuthorRequest(ctx, in.AuthorID, in.RequestID); qerr == nil && found {
				story, aerr := s.assembleOne(ctx, existing, in.AuthorID)
				return story, false, aerr
			}
		}
		return Story{}, false, err
	}

	row, _, err := s.store.byAuthorRequest(ctx, in.AuthorID, in.RequestID)
	if err != nil {
		return Story{}, false, err
	}
	story, err := s.assembleOne(ctx, row, in.AuthorID)
	return story, true, err
}

// resolveClip valida a faixa e o trecho escolhidos. Sem faixa, não pode haver trecho.
func (s *Service) resolveClip(ctx context.Context, in PublishInput) (*clip, error) {
	bad := func(msg string) error {
		return platform.NewError(http.StatusUnprocessableEntity, "invalid_track", msg)
	}
	if in.TrackID == "" {
		if in.TrackStartMS != nil || in.TrackDurationMS != nil {
			return nil, bad("Informe track_id para usar track_start_ms ou track_duration_ms.")
		}
		return nil, nil
	}
	track, found, err := s.media.ActiveTrack(ctx, in.TrackID)
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, bad("Faixa inexistente no catálogo.")
	}

	maxMS := s.maxClip.Milliseconds()
	var start int64
	if in.TrackStartMS != nil {
		start = *in.TrackStartMS
	}
	if start < 0 || start >= track.DurationMS {
		return nil, bad("track_start_ms deve estar dentro da duração da faixa.")
	}
	dur := min(maxMS, track.DurationMS-start)
	if in.TrackDurationMS != nil {
		dur = *in.TrackDurationMS
	}
	if dur <= 0 || dur > maxMS || start+dur > track.DurationMS {
		return nil, bad("track_duration_ms deve ser positivo, no máximo " + strconv.FormatInt(maxMS, 10) + " ms e caber na faixa.")
	}
	return &clip{TrackID: track.ID, StartMS: start, DurationMS: dur}, nil
}

// ---- Feed ----------------------------------------------------------------------

// Feed lista os stories das últimas 24 h da roda ATUAL da pessoa.
func (s *Service) Feed(ctx context.Context, userID string, limit int, beforeSeq int64) ([]Story, int64, error) {
	membership, ok, err := s.groups.MembershipOf(ctx, userID)
	if err != nil {
		return nil, 0, err
	}
	if !ok {
		return nil, 0, groups.ErrNotInGroup
	}
	newerThan := s.now().Unix() - s.visibleSeconds()
	rows, err := s.store.feed(ctx, membership.GroupID, newerThan, beforeSeq, limit)
	if err != nil {
		return nil, 0, err
	}
	stories, err := s.assemble(ctx, rows, userID)
	if err != nil {
		return nil, 0, err
	}
	var next int64
	if len(rows) == limit {
		next = rows[len(rows)-1].Seq
	}
	return stories, next, nil
}

// ---- Acesso à foto -----------------------------------------------------------

// AuthorizePhoto aplica as regras de prazo e devolve o id da mídia se o acesso
// for permitido. Esta é a ÚNICA função que decide quem baixa fotos de stories.
//
//	0 h  ≤ idade < 24 h : o autor e os participantes ATUAIS da roda do story
//	24 h ≤ idade < 72 h : somente o autor
//	idade ≥ 72 h        : ninguém (o autor recebe 410; os demais, 404)
//
// Quem não pode ver recebe 404 (e não 403) para não revelar que o story existe.
func (s *Service) AuthorizePhoto(ctx context.Context, userID, storyID string) (string, error) {
	row, found, err := s.store.byID(ctx, storyID)
	if err != nil {
		return "", err
	}
	if !found {
		return "", ErrStoryNotFound
	}
	isAuthor := row.AuthorID == userID
	age := s.ageSeconds(row.CreatedAt)

	switch {
	case age >= s.recoverableSeconds():
		if isAuthor {
			return "", ErrStoryExpired
		}
		return "", ErrStoryNotFound
	case age >= s.visibleSeconds():
		if isAuthor {
			return row.MediaID, nil
		}
		return "", ErrStoryNotFound
	default:
		if isAuthor {
			return row.MediaID, nil
		}
		member, err := s.groups.IsMember(ctx, userID, row.GroupID)
		if err != nil {
			return "", err
		}
		if !member {
			return "", ErrStoryNotFound
		}
		return row.MediaID, nil
	}
}

// ---- Reações -------------------------------------------------------------------

// React cria ou troca a reação da pessoa. Só quem pode ver o story no feed reage.
func (s *Service) React(ctx context.Context, userID, storyID, kind string) (ReactionSummary, error) {
	if !reactionKinds[kind] {
		return ReactionSummary{}, platform.NewError(http.StatusUnprocessableEntity, "invalid_reaction",
			"Reação inválida. Use: fire, muscle, clap ou heart.")
	}
	if err := s.requireVisibleInFeed(ctx, userID, storyID); err != nil {
		return ReactionSummary{}, err
	}
	if err := s.store.upsertReaction(ctx, storyID, userID, kind, s.now()); err != nil {
		return ReactionSummary{}, err
	}
	return s.summary(ctx, storyID, userID)
}

// Unreact remove a reação (é seguro repetir: sem reação, nada acontece).
func (s *Service) Unreact(ctx context.Context, userID, storyID string) (ReactionSummary, error) {
	if err := s.requireVisibleInFeed(ctx, userID, storyID); err != nil {
		return ReactionSummary{}, err
	}
	if err := s.store.deleteReaction(ctx, storyID, userID); err != nil {
		return ReactionSummary{}, err
	}
	return s.summary(ctx, storyID, userID)
}

func (s *Service) requireVisibleInFeed(ctx context.Context, userID, storyID string) error {
	row, found, err := s.store.byID(ctx, storyID)
	if err != nil {
		return err
	}
	if !found || !s.visibleInFeed(row.CreatedAt) {
		return ErrStoryNotFound
	}
	member, err := s.groups.IsMember(ctx, userID, row.GroupID)
	if err != nil {
		return err
	}
	if !member {
		return ErrStoryNotFound
	}
	return nil
}

func (s *Service) summary(ctx context.Context, storyID, viewerID string) (ReactionSummary, error) {
	m, err := s.store.reactionSummaries(ctx, []string{storyID}, viewerID)
	return m[storyID], err
}

// ---- Montagem da resposta ------------------------------------------------------

func (s *Service) assembleOne(ctx context.Context, row storyRow, viewerID string) (Story, error) {
	list, err := s.assemble(ctx, []storyRow{row}, viewerID)
	if err != nil {
		return Story{}, err
	}
	return list[0], nil
}

func (s *Service) assemble(ctx context.Context, rows []storyRow, viewerID string) ([]Story, error) {
	ids := make([]string, len(rows))
	for i, r := range rows {
		ids[i] = r.ID
	}
	reactions, err := s.store.reactionSummaries(ctx, ids, viewerID)
	if err != nil {
		return nil, err
	}

	out := make([]Story, len(rows))
	for i, r := range rows {
		st := Story{
			ID:               r.ID,
			Author:           Author{ID: r.AuthorID, DisplayName: r.AuthorName},
			Caption:          r.Caption,
			WorkoutReport:    json.RawMessage(r.Report),
			CreatedAt:        r.CreatedAt,
			VisibleUntil:     r.CreatedAt.Add(s.visibleFor),
			RecoverableUntil: r.CreatedAt.Add(s.recoverableFor),
			PhotoURL:         "/v1/stories/" + r.ID + "/photo",
			Reactions:        reactions[r.ID],
			Mine:             r.AuthorID == viewerID,
		}
		if r.TrackID.Valid {
			st.Track = &TrackClip{
				ID: r.TrackID.String, Title: r.TrackTitle.String, Artist: r.TrackArtst.String,
				StartMS: r.StartMS.Int64, DurationMS: r.DurationMS.Int64,
				AudioURL: "/v1/tracks/" + r.TrackID.String + "/audio",
			}
		}
		out[i] = st
	}
	return out, nil
}
