# Arquitetura

## Decisões e dependências

O backend é um **monólito simples**: um programa Go, uma API HTTP, um banco SQLite, arquivos no disco.
Para um piloto com poucas rodas de até dez pessoas, uma instância basta, e menos peças significam
menos coisas para entender e operar.

| Escolha | Por quê |
|---|---|
| `net/http` (Go 1.22) | O roteador padrão já aceita método e parâmetros no padrão da rota (`GET /v1/stories/{id}/photo`, `r.PathValue("id")`). Não precisamos de framework. |
| SQL explícito (`database/sql`) | O SQL fica visível nos arquivos `store.go`. Sem ORM, sem "mágica". |
| SQLite | Um arquivo, sem servidor para administrar, ótimo para uma instância. Transações imediatas dão a consistência de que precisamos (ver `dados-e-regras.md`). |
| `github.com/mattn/go-sqlite3` | **Dependência 1.** Driver SQLite. Usa cgo (exige `gcc` ao compilar). Foi escolhido por poder ser compilado e testado no ambiente desta entrega. Está isolado em `internal/platform/db.go`: trocar por um driver sem cgo é mudar uma importação. |
| `golang.org/x/crypto/argon2` | **Dependência 2.** Hash de senha com **argon2id**, usando os parâmetros recomendados pela documentação oficial do pacote (1 passada, 64 MiB, 4 threads). Nada de criptografia inventada. |
| Migrações próprias | ~40 linhas em `platform/migrate.go` + arquivos `.sql` embutidos (`go:embed`). Uma biblioteca de migrações seria mais código a aprender do que o problema pede. |
| Sem interfaces "de enfeite" | Os serviços são structs concretas. A única "troca" feita por função é onde os testes precisam: o relógio (`platform.Clock`) e o removedor de arquivos da limpeza. |

## Mapa dos módulos

| Módulo | Responsabilidade | Arquivos |
|---|---|---|
| `auth` | cadastro, login, logout, sessões, "quem é o usuário desta requisição" | `handler.go` (HTTP + `Require`), `service.go` (regras), `store.go` (SQL), `password.go` (argon2id) |
| `groups` | rodas, participantes, convites, "esta pessoa pertence a esta roda?" | `handler.go`, `service.go`, `store.go` (transações de criar/entrar/sair) |
| `stories` | publicar, feed, reações, **regras de prazo e acesso às fotos** | `handler.go`, `service.go`, `store.go` |
| `media` | validar/gravar/entregar fotos, catálogo e áudio das músicas | `service.go` (fotos), `storage.go` (disco), `validate.go` (imagem), `catalog.go` (músicas), `handler.go` |
| `cleanup` | expirar stories, apagar fotos e órfãos, tentar de novo se falhar | `job.go` (rodadas e repetição), `store.go` (SQL) |
| `platform` | configuração, banco, migrações, respostas HTTP, relógio, ids | pequenos arquivos sem regra de negócio |
| `app` | cria os serviços na ordem certa e registra as rotas | `app.go` (+ testes de integração) |

`cmd/api/main.go` só carrega a configuração, chama `app.New`, inicia a limpeza e o servidor HTTP e trata o
desligamento (Ctrl+C / `systemctl stop`). **Nenhuma regra de negócio vive nele.**

### Quem depende de quem

```
platform  ◄── auth
platform  ◄── groups  ──► auth      (só para ler o usuário do contexto)
platform  ◄── media   ──► auth
platform  ◄── stories ──► groups, media, auth
platform  ◄── cleanup ──► media     (só o Storage, para apagar arquivos)
app       ──► todos (único lugar que conhece o programa inteiro)
```

Não há ciclos. As dependências são passadas ao criar cada serviço (`app.New`), nunca por variável global.
Duas conexões merecem atenção:

- `stories` pergunta a `groups` **quem é participante agora** (`MembershipOf`, `IsMember`). Há uma fonte única da verdade.
- `media` entrega a foto de um story **sem conhecer stories**: o handler recebe de `app` a função
  `stories.Service.AuthorizePhoto` e a chama antes de abrir o arquivo. A regra de 24 h / 72 h mora num
  único lugar.

## Como uma requisição percorre o código

Camadas em cada módulo (só quando trazem clareza):

- **handler** — traduz HTTP: lê parâmetros/JSON/multipart, chama o serviço, escreve a resposta. Sem regra de negócio.
- **service** — as regras (quem pode, quanto, em que ordem). Devolve erros `*platform.APIError` quando a falha é "esperada" (roda cheia, convite inválido...), que já carregam status HTTP e um `code` estável.
- **store** — só SQL. Cada função faz uma pergunta ao banco.

### Exemplo 1: `POST /v1/stories` (publicar)

1. `platform.Wrap` (em volta de tudo): recupera pânicos, registra o log da requisição.
2. O roteador (montado em `app.New`) encontra `POST /v1/stories` → `stories.Handler.publish`, que foi registrado **protegido por** `auth.Handler.Require`.
3. `Require` lê `Authorization: Bearer <token>` → `auth.Service.Authenticate` → `auth.Store.userBySessionToken` (SQL com o *hash* do token, só sessão ativa e não expirada). Em caso de falha: 401 e a requisição para aqui. Em caso de sucesso, o usuário vai no contexto.
4. `publish` confere o cabeçalho `Idempotency-Key` **antes de ler o corpo**, limita o tamanho com `http.MaxBytesReader` e lê o multipart. O `user.ID` vem do contexto, **nunca do corpo**.
5. `stories.Service.Publish` (as regras):
   1. `groups.Service.MembershipOf` — a pessoa está numa roda? A roda vem do banco.
   2. valida legenda e trecho (`resolveClip`, que consulta `media.Service.ActiveTrack`);
   3. `Store.byAuthorRequest` — essa publicação já foi feita? Se sim, devolve a original (200);
   4. `media.Service.StorePhoto` → `PrepareJPEG` (tamanho, tipo real, dimensões, decodificação, regrava sem EXIF) → `Storage.WritePhoto` (arquivo em `tmp/`, depois *rename*) → `INSERT` em `media_files`;
   5. `Store.insert` — o `INSERT` do story. Se outra requisição idêntica venceu a corrida, a restrição `UNIQUE (author_id, client_request_id)` falha: a foto recém-gravada é descartada e o story original é devolvido.
6. De volta ao handler: `platform.WriteJSON` com 201 (novo) ou 200 + `Idempotent-Replayed: true`. Qualquer erro passa por `platform.WriteError`.

### Exemplo 2: `GET /v1/feed`

`Require` → `stories.Handler.feed` (lê `limit` e `before`) → `Service.Feed` → `groups.MembershipOf` (roda **atual**)
→ `Store.feed` (um `SELECT` com `JOIN` em `users` e `tracks`, filtrando `created_at` pelo prazo de 24 h)
→ `assemble` (busca as reações de todos os stories do lote em duas consultas) → JSON.

## Convenções do código

- **Erros esperados** são variáveis do pacote (`groups.ErrGroupFull`, `stories.ErrStoryNotFound`...), criadas com `platform.NewError(status, code, mensagem)`. Erros inesperados viram 500 genérico e o detalhe vai só para o log.
- **Tempo**: serviços recebem `platform.Clock`, nunca chamam `time.Now()` direto. Datas no banco são segundos Unix; na API, RFC 3339 em UTC.
- **Ids públicos**: `platform.NewID()` (128 bits aleatórios). Nada sequencial na API.
- **Nunca confiar no cliente**: ids de usuário, roda e permissões são sempre derivados da sessão e do banco.
- **SQL só em `store.go`** (uma exceção consciente: `stories` lê `users` e `tracks` num `JOIN` para montar o feed numa consulta só).

## Como adicionar uma funcionalidade sem engordar o `main.go`

Regra de ouro: **uma funcionalidade nova entra no módulo dono dela; `cmd/api/main.go` não muda.**

1. **Escolha o módulo** pela responsabilidade (pergunte: de quem são os dados e as regras?).
2. **Se precisar de tabela/coluna**: crie `migrations/0005_nome.sql` (nunca edite um arquivo antigo; ele já rodou em algum banco).
3. **`store.go`**: escreva a(s) consulta(s) SQL.
4. **`service.go`**: escreva a regra (autorização, validação, ordem das operações).
5. **`handler.go`**: leia a requisição, chame o serviço, escreva a resposta e adicione **uma linha** em `Register`.
6. **Teste** em `internal/app/*_test.go` com `newEnv(t)` (programa inteiro + relógio falso).
7. **Documente** o endpoint em `docs/api.md`.

### Exemplo ilustrativo (não implementado): `GET /v1/stories/mine`

"Listar meus stories que ainda posso recuperar (até 72 h)". Tudo dentro de `internal/stories/`:

```go
// store.go — a pergunta ao banco
func (s *Store) byAuthor(ctx context.Context, authorID string, newerThan int64) ([]storyRow, error) {
	rows, err := s.db.QueryContext(ctx,
		selectStory+`WHERE s.author_id = ? AND s.created_at > ? ORDER BY s.seq DESC`, authorID, newerThan)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []storyRow
	for rows.Next() {
		r, err := scanStory(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

// service.go — a regra: só os do próprio usuário, dentro do prazo de recuperação
func (s *Service) Mine(ctx context.Context, userID string) ([]Story, error) {
	rows, err := s.store.byAuthor(ctx, userID, s.now().Unix()-s.recoverableSeconds())
	if err != nil {
		return nil, err
	}
	return s.assemble(ctx, rows, userID)
}

// handler.go — traduz HTTP e registra a rota
func (h *Handler) mine(w http.ResponseWriter, r *http.Request) {
	items, err := h.svc.Mine(r.Context(), auth.UserFrom(r.Context()).ID)
	if err != nil {
		platform.WriteError(w, r, err)
		return
	}
	platform.WriteJSON(w, http.StatusOK, map[string]any{"stories": items})
}
// ... e em Register:  mux.HandleFunc("GET /v1/stories/mine", require(h.mine))
```

### Criar um módulo novo

Crie `internal/<nome>/` com `service.go` (+ `store.go`, `handler.go` se fizer sentido), um construtor
`NewService(...)` e `Handler.Register(mux, require)`. Em `internal/app/app.go`, acrescente as 2–3 linhas que
criam o serviço e registram o handler. Só o `app.go` muda; o `main.go` continua igual.

## Testes

`go test ./...` roda tudo. Os testes de integração (`internal/app`) sobem o programa inteiro com banco e pastas
temporários e um **relógio falso** (`fakeClock`): avançam 24 h e 72 h instantaneamente. Cobrem isolamento
entre rodas, janelas de 24/72 h *sem a limpeza ter rodado*, publicação repetida (inclusive corrida
determinística), limite de participantes sob concorrência e a limpeza com falhas e reinício.
