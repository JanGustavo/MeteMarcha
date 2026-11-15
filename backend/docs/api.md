# Contrato HTTP (API v1)

Este é o contrato para o app Flutter. Os exemplos foram obtidos executando o programa de verdade
(`curl` contra o servidor local); ids e tokens mudam a cada execução. Nos exemplos, `$B` é a URL base
(`http://127.0.0.1:8080` localmente; em produção, sempre `https://`).

## Convenções

- Todas as rotas ficam sob `/v1` (exceto `GET /healthz`). Corpos JSON usam UTF-8 e `Content-Type: application/json`.
- **Datas**: texto RFC 3339 em UTC, com segundos (`2026-11-15T12:07:13Z`).
- **Ids**: textos hexadecimais de 32 caracteres. Trate como opacos.
- **Autenticação**: `Authorization: Bearer <token>` em toda rota, exceto cadastro, login e `/healthz`.
- **Erros** têm sempre este formato; o app deve decidir pelo `code` (estável), não pela `message`:
  ```json
  { "error": { "code": "not_in_group", "message": "Você não participa de nenhuma roda." } }
  ```
- `GET` de fotos e áudios devolvem bytes (não JSON); os erros delas continuam em JSON.

### Contrato do token de sessão

| Tópico | Regra |
|---|---|
| Obtenção | `register` ou `login` devolvem `session.token` e `session.expires_at`. É a **única** vez que o token aparece. |
| Formato | texto aleatório de 256 bits (base64url). O servidor guarda só o hash. |
| Validade | 30 dias (configurável). Não há refresh: ao expirar, o app faz login de novo. |
| Armazenamento no app | Use o **armazenamento seguro do sistema** (no Android, o Keystore; por exemplo, via o pacote `flutter_secure_storage`). Nunca em `SharedPreferences` comum, em arquivo do app, em log ou em URL. |
| Uso | cabeçalho `Authorization: Bearer <token>` em toda requisição. |
| Falha | `401` com `code: "unauthorized"` → apague o token guardado e leve a pessoa ao login. |
| Saída | `POST /v1/auth/logout` revoga **aquela** sessão imediatamente (outros aparelhos continuam logados). |
| Transporte | só HTTPS. O token no cabeçalho equivale a uma senha enquanto for válido. |

### Fotos e áudios exigem o cabeçalho

`photo_url` e `audio_url` são **caminhos relativos** (`/v1/stories/{id}/photo`), não links públicos. Para
exibir, o app precisa enviar `Authorization` (por exemplo, `Image.network(url, headers: {...})` ou baixar os
bytes e usar `Image.memory`). Um link copiado para o navegador não funciona.

---

## Autenticação

### `POST /v1/auth/register` — criar conta

O cadastro é aberto (não há convite de cadastro; só existe convite de *roda*). Já abre uma sessão.

| Campo | Regra |
|---|---|
| `email` | endereço válido, até 254 caracteres; guardado em minúsculas |
| `display_name` | 1 a 40 caracteres |
| `password` | 8 a 128 caracteres |

```bash
curl -X POST $B/v1/auth/register -H 'Content-Type: application/json' \
  -d '{"email":"ana@example.com","display_name":"Ana","password":"senha-segura-123"}'
```
`201 Created`
```json
{
  "user": {
    "id": "79c3fbcef78c609aebd90db5068b13d5",
    "email": "ana@example.com",
    "display_name": "Ana",
    "created_at": "2026-11-15T12:07:13Z"
  },
  "session": {
    "token": "HIC9HXiOIC3a7NSFEqUAQs8UT9i5f1gk5fq5A15rbGk",
    "expires_at": "2026-12-15T12:07:13Z"
  }
}
```
Erros: `409 email_taken`, `422 invalid_email | invalid_display_name | invalid_password`, `400 invalid_json`.
```json
{ "error": { "code": "email_taken", "message": "Já existe uma conta com este e-mail." } }
```

### `POST /v1/auth/login`

```bash
curl -X POST $B/v1/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"ana@example.com","password":"senha-segura-123"}'
```
`200 OK` — mesmo formato do cadastro. Cada login cria uma sessão nova.
Erro: `401 invalid_credentials` (a mesma resposta para senha errada e e-mail inexistente).
```json
{ "error": { "code": "invalid_credentials", "message": "E-mail ou senha incorretos." } }
```

### `POST /v1/auth/logout`

```bash
curl -X POST $B/v1/auth/logout -H "Authorization: Bearer $TOKEN"
```
`204 No Content`. A partir daí o token devolve `401`.

### `GET /v1/me`

```bash
curl $B/v1/me -H "Authorization: Bearer $TOKEN"
```
`200 OK`
```json
{ "user": { "id": "79c3fbcef78c609aebd90db5068b13d5", "email": "ana@example.com",
            "display_name": "Ana", "created_at": "2026-11-15T12:07:13Z" } }
```
Erro (qualquer rota protegida, sem token, token inventado, expirado ou revogado): `401 unauthorized`
```json
{ "error": { "code": "unauthorized", "message": "Sessão ausente, inválida ou expirada. Entre novamente." } }
```

---

## Rodas

Cada pessoa pode participar de várias rodas; cada roda tem até 10 participantes (`max_members`).
Os endpoints antigos `/v1/groups/me`, `/v1/groups/me/invites`, `/v1/groups/me/leave`,
`/v1/stories` e `/v1/feed` usam a **roda ativa**. Criar ou entrar em uma roda a seleciona.

### `GET /v1/groups` — minhas rodas

`200 OK`: `{ "groups": [{ "id": "...", "name": "Cohort A", "created_at": "...", "max_members": 10 }], "active_group_id": "..." }`.
Sem grupos, `groups` é `[]` e `active_group_id` é `""`.

### `PUT /v1/groups/active` — selecionar roda

Corpo: `{ "group_id": "..." }`. `200 OK`: `{ "group": { ... } }`.
`404 group_not_found` se a pessoa não participa da roda, inclusive se o ID não existe.

### `POST /v1/groups` — criar roda (quem cria vira dona)

```bash
curl -X POST $B/v1/groups -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"Roda da Perna"}'
```
`201 Created`
```json
{ "group": { "id": "b32509dea206ac372ad7cf322c43dda7", "name": "Roda da Perna",
             "created_at": "2026-11-15T12:07:13Z", "max_members": 10 } }
```
Erro: `422 invalid_name` (1 a 40 caracteres).

### `GET /v1/groups/me` — roda ativa e participantes

```bash
curl $B/v1/groups/me -H "Authorization: Bearer $TOKEN"
```
`200 OK`
```json
{
  "group": { "id": "9577e16eba3ac8a2c24ead468d9a67fc", "name": "Roda da Perna",
             "created_at": "2026-11-15T12:15:46Z", "max_members": 10 },
  "members": [
    { "user_id": "23905f697704254adb2bf22d16325d17", "display_name": "Ana",
      "role": "owner",  "joined_at": "2026-11-15T12:15:46Z" },
    { "user_id": "2c4f0570b07eb18e45d22a3fe5719348", "display_name": "Bia",
      "role": "member", "joined_at": "2026-11-15T12:15:46Z" }
  ]
}
```
Erro: `403 not_in_group` (estado "ainda não tenho roda").

### `POST /v1/groups/me/invites` — gerar convite de roda

Qualquer participante pode convidar. O código é de **uso único**, vale 7 dias (padrão) e só é mostrado agora.

```bash
curl -X POST $B/v1/groups/me/invites -H "Authorization: Bearer $TOKEN"
```
`201 Created`
```json
{ "invite": { "code": "QMS5X-UZ638", "expires_at": "2026-11-22T12:07:13Z" } }
```
Erro: `403 not_in_group`.

### `POST /v1/groups/join` — entrar com um convite

O código aceita minúsculas e com ou sem hífen.

```bash
curl -X POST $B/v1/groups/join -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"code":"QMS5X-UZ638"}'
```
`200 OK` — `{ "group": { ... } }` (mesmo formato de criar).
Erros: `404 invite_invalid` (inexistente, expirado **ou** já usado; a mesma resposta para os três),
`409 group_full`, `409 already_in_group` (já participa **daquela** roda).
```json
{ "error": { "code": "invite_invalid", "message": "Convite inválido, expirado ou já utilizado." } }
```
```json
{ "error": { "code": "group_full", "message": "Esta roda já atingiu o limite de participantes." } }
```

### `POST /v1/groups/me/leave` — sair da roda

`204 No Content`. Se era a dona, a pessoa mais antiga da roda vira dona. Erro: `403 not_in_group`.
Depois de sair, a pessoa perde o acesso aos stories da roda na hora. Se participa
de outra roda, a mais antiga vira a ativa.

---

## Stories

### `POST /v1/stories` — publicar

`multipart/form-data`. **Obrigatório** o cabeçalho `Idempotency-Key` (veja abaixo).
Pode ser publicado antes, durante ou depois do treino: o story não representa um treino concluído.

| Campo | Obrigatório | Regra |
|---|---|---|
| `photo` | sim | arquivo JPEG ou PNG (até 8 MiB e 4096 px por lado, por padrão). Envie **já rotacionada** (o servidor remove o EXIF, inclusive a orientação). |
| `caption` | não | até 300 caracteres |
| `track_id` | não | id de uma faixa de `GET /v1/tracks` |
| `track_start_ms` | não | só com `track_id`; instante inicial do trecho (padrão `0`) |
| `track_duration_ms` | não | só com `track_id`; padrão: o que couber, até 30000 |

`Idempotency-Key`: texto de 8 a 100 caracteres (letras, números, `.`, `:`, `-`, `_`). **Gere um valor novo por
publicação** (por exemplo, um UUID) **e reutilize o mesmo valor ao repetir a requisição** depois de uma falha
de conexão.

```bash
curl -X POST $B/v1/stories -H "Authorization: Bearer $TOKEN" \
  -H "Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7" \
  -F photo=@foto.jpg -F caption="Dia de perna 🔥" \
  -F track_id=forca-total -F track_start_ms=45000 -F track_duration_ms=15000
```
`201 Created`
```json
{
  "story": {
    "id": "7f7e42cf4ac383edec390f54949f8851",
    "author": { "id": "79c3fbcef78c609aebd90db5068b13d5", "display_name": "Ana" },
    "caption": "Dia de perna 🔥",
    "created_at": "2026-11-15T12:07:13Z",
    "visible_until": "2026-11-16T12:07:13Z",
    "recoverable_until": "2026-11-18T12:07:13Z",
    "photo_url": "/v1/stories/7f7e42cf4ac383edec390f54949f8851/photo",
    "track": {
      "id": "forca-total",
      "title": "Força Total",
      "artist": "Banda Própria",
      "start_ms": 45000,
      "duration_ms": 15000,
      "audio_url": "/v1/tracks/forca-total/audio"
    },
    "reactions": { "counts": {}, "mine": null },
    "mine": true
  }
}
```
Sem música, `"track": null`.

**Repetir a mesma requisição** (mesmo usuário e mesmo `Idempotency-Key`) devolve `200 OK` com o **mesmo** story e o
cabeçalho `Idempotent-Replayed: true`. Nada é duplicado e nenhuma foto extra fica guardada. O servidor não compara o
conteúdo: uma chave já usada devolve o story original, mesmo que os campos sejam diferentes.

Erros:

| Status | `code` | Quando |
|---|---|---|
| 400 | `invalid_idempotency_key` | cabeçalho ausente ou fora do formato |
| 400 | `invalid_multipart` / `photo_required` / `invalid_field` | corpo não é multipart; falta `photo`; número inválido em `track_*_ms` |
| 403 | `not_in_group` | a pessoa não tem roda |
| 413 | `photo_too_large` / `request_too_large` | foto ou requisição acima do limite |
| 415 | `unsupported_photo_type` | o conteúdo não é JPEG nem PNG |
| 422 | `invalid_photo` | imagem corrompida ou com lado acima do limite |
| 422 | `invalid_caption` | legenda com mais de 300 caracteres |
| 422 | `invalid_track` | faixa inexistente, trecho fora da faixa, maior que 30 s, ou `track_*` sem `track_id` |

```json
{ "error": { "code": "unsupported_photo_type", "message": "Formato não suportado. Envie uma foto JPEG ou PNG." } }
```
```json
{ "error": { "code": "invalid_track", "message": "track_duration_ms deve ser positivo, no máximo 30000 ms e caber na faixa." } }
```
```json
{ "error": { "code": "invalid_idempotency_key", "message": "Envie o cabeçalho Idempotency-Key com 8 a 100 caracteres (letras, números, ponto, dois-pontos, hífen ou sublinhado)." } }
```

### `GET /v1/feed` — feed da minha roda

Stories com **menos de 24 h**, do mais novo para o mais antigo, só da roda atual da pessoa.

| Parâmetro | Padrão | Regra |
|---|---|---|
| `limit` | 20 | de 1 a 50 |
| `before` | — | o `next_cursor` da página anterior |

```bash
curl "$B/v1/feed?limit=20" -H "Authorization: Bearer $TOKEN"
```
`200 OK`
```json
{
  "next_cursor": null,
  "stories": [
    {
      "id": "7f7e42cf4ac383edec390f54949f8851",
      "author": { "id": "79c3fbcef78c609aebd90db5068b13d5", "display_name": "Ana" },
      "caption": "Dia de perna 🔥",
      "created_at": "2026-11-15T12:07:13Z",
      "visible_until": "2026-11-16T12:07:13Z",
      "recoverable_until": "2026-11-18T12:07:13Z",
      "photo_url": "/v1/stories/7f7e42cf4ac383edec390f54949f8851/photo",
      "track": { "id": "forca-total", "title": "Força Total", "artist": "Banda Própria",
                 "start_ms": 45000, "duration_ms": 15000, "audio_url": "/v1/tracks/forca-total/audio" },
      "reactions": { "counts": { "fire": 1 }, "mine": "fire" },
      "mine": false
    }
  ]
}
```
`next_cursor` vem preenchido quando a página veio cheia (`limit` itens); a página seguinte pode vir vazia. É `null`
quando acabou. Erros: `403 not_in_group`, `400 invalid_limit | invalid_cursor`.

### `GET /v1/stories/{id}/photo` — baixar a foto

Responde com os **bytes** da imagem (`Content-Type: image/jpeg`, `Cache-Control: private, no-store`). Aceita
`Range`. Este mesmo endpoint serve a **recuperação** pelo autor.

| Idade do story | Participantes atuais da roda | Autor | Outras pessoas |
|---|---|---|---|
| menos de 24 h | `200` | `200` | `404` |
| de 24 h a menos de 72 h | `404` | `200` (recuperação) | `404` |
| 72 h ou mais | `404` | `410 story_expired` | `404` |

```bash
curl -H "Authorization: Bearer $TOKEN" $B/v1/stories/7f7e42cf4ac383edec390f54949f8851/photo -o treino.jpg
```
```
HTTP/1.1 200 OK
Cache-Control: private, no-store
Content-Disposition: inline
Content-Type: image/jpeg
X-Content-Type-Options: nosniff
```
Erros (JSON): `401 unauthorized`; `404 not_found` (não existe **ou** você não pode ver; indistinguível de propósito);
`410 story_expired` (só para o autor, depois de 72 h).
```json
{ "error": { "code": "not_found", "message": "Story não encontrado." } }
```
```json
{ "error": { "code": "story_expired", "message": "O prazo de recuperação deste story terminou e a foto não está mais disponível." } }
```

### `PUT /v1/stories/{id}/reaction` — reagir ou trocar a reação

Uma reação por pessoa por story; repetir o `PUT` com outro `kind` **troca** a reação. Tipos: `fire`, `muscle`,
`clap`, `heart` (o app escolhe o emoji de cada um). Só vale enquanto o story está no feed (menos de 24 h) e por
quem pode vê-lo.

```bash
curl -X PUT $B/v1/stories/7f7e42cf4ac383edec390f54949f8851/reaction \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"kind":"fire"}'
```
`200 OK`
```json
{ "reactions": { "counts": { "fire": 1 }, "mine": "fire" } }
```
Erros: `404 not_found`, `422 invalid_reaction`.
```json
{ "error": { "code": "invalid_reaction", "message": "Reação inválida. Use: fire, muscle, clap ou heart." } }
```

### `DELETE /v1/stories/{id}/reaction` — remover minha reação

Seguro repetir (sem reação, nada acontece).
`200 OK`
```json
{ "reactions": { "counts": {}, "mine": null } }
```

---

## Músicas

Catálogo pequeno de arquivos próprios ou autorizados. **O servidor não processa áudio nem gera vídeo**: foto e áudio
ficam separados, e o app toca os dois juntos (começando em `start_ms`, por `duration_ms`).

### `GET /v1/tracks`

```bash
curl $B/v1/tracks -H "Authorization: Bearer $TOKEN"
```
`200 OK`
```json
{ "tracks": [ { "id": "forca-total", "title": "Força Total", "artist": "Banda Própria",
                "duration_ms": 120000, "audio_url": "/v1/tracks/forca-total/audio" } ] }
```

### `GET /v1/tracks/{id}/audio`

Bytes do áudio (`audio/mpeg`, `audio/mp4`, `audio/ogg` ou `audio/wav`), com suporte a `Range` (o app pode começar
do instante escolhido). Exige `Authorization`. Erro: `404 not_found`.
```
HTTP/1.1 206 Partial Content        (com o cabeçalho Range: bytes=0-99)
Accept-Ranges: bytes
Cache-Control: private, max-age=3600
Content-Range: bytes 0-99/4096
Content-Type: audio/mpeg
```

---

## Saúde

`GET /healthz` (sem autenticação) → `200 {"status":"ok"}` se o banco responde. Útil para monitoramento.

## Resumo de códigos de erro

| Status | `code` |
|---|---|
| 400 | `invalid_json`, `invalid_idempotency_key`, `invalid_multipart`, `photo_required`, `invalid_field`, `invalid_limit`, `invalid_cursor` |
| 401 | `unauthorized`, `invalid_credentials` |
| 403 | `not_in_group` |
| 404 | `not_found`, `invite_invalid`, `group_not_found` |
| 409 | `email_taken`, `already_in_group`, `group_full` |
| 410 | `story_expired` |
| 413 | `photo_too_large`, `request_too_large` |
| 415 | `unsupported_photo_type` |
| 422 | `invalid_email`, `invalid_display_name`, `invalid_password`, `invalid_name`, `invalid_caption`, `invalid_photo`, `invalid_track`, `invalid_reaction` |
| 500 | `internal_error` (o detalhe vai só para o log do servidor) |

## Fluxo sugerido no Flutter para publicar

1. Gere `Idempotency-Key` (UUID) e guarde junto da foto escolhida, **antes** de enviar.
2. Envie `POST /v1/stories`. Se a conexão cair ou der timeout, **reenvie com a mesma chave**: o resultado é o mesmo
   story, sem duplicar.
3. Ao receber `201` ou `200`, guarde `story.id` e `story.recoverable_until` (para a recuperação depois das 24 h) e
   descarte a chave.
4. Em `4xx` (exceto `401`), corrija o dado; em `401`, refaça o login.
