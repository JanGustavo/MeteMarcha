# MeteMarcha — backend das rodas (piloto)

Backend mínimo em Go para o piloto de **rodas**: pequenos grupos privados de amigos que
publicam *stories* de treino (foto + legenda opcional + trecho opcional de uma música do
catálogo) e reagem às publicações.

O aplicativo Flutter continua registrando treinos **offline**, sem depender deste servidor.
O servidor só conhece o que a pessoa **publica explicitamente** (conta, roda, stories). Treinos,
medidas e fotos locais nunca são enviados.

| Documento | Para quê |
|---|---|
| este README | rodar localmente, configurar a VPS, visão geral |
| [`docs/arquitetura.md`](docs/arquitetura.md) | módulos, caminho de uma requisição, como adicionar funcionalidades |
| [`docs/dados-e-regras.md`](docs/dados-e-regras.md) | modelo de dados, migrações, regras de horário/acesso/exclusão |
| [`docs/api.md`](docs/api.md) | contrato HTTP com exemplos completos (para o Flutter) |

## Visão geral

Um único programa Go (monólito), uma API HTTP, um banco **SQLite** e arquivos de mídia no disco da VPS.
Sem Redis, filas, microsserviços ou serviços externos.

```
backend/
├── cmd/api/main.go        inicia o servidor e a limpeza (só liga as peças)
├── internal/
│   ├── auth/              cadastro, login, logout, sessões
│   ├── groups/            rodas, participantes, convites
│   ├── stories/           publicações, feed, reações, regras de prazo
│   ├── media/             upload/entrega protegida de fotos, catálogo de músicas
│   ├── cleanup/           expiração e exclusão (rodando dentro do programa)
│   ├── platform/          config, banco, migrações, respostas HTTP (infraestrutura pequena)
│   └── app/               monta tudo (cria os serviços e registra as rotas) + testes de integração
├── migrations/            esquema SQL, um arquivo por módulo (embutido no binário)
└── deploy/                exemplos: systemd, proxy HTTPS, catálogo de músicas
```

## Executar localmente

Pré-requisitos: **Go 1.22 ou mais novo** e um compilador C (`gcc`). O driver SQLite
(`mattn/go-sqlite3`) usa cgo; no Ubuntu/Debian, `sudo apt install build-essential`.

```bash
cd backend
go mod download             # baixa as dependências verificadas pelo go.sum
go test ./...               # roda toda a suíte (usa bancos e pastas temporários)

cp .env.example .env        # ajuste se quiser; os padrões já funcionam
set -a; source .env; set +a # carrega as variáveis no terminal
go run ./cmd/api

curl http://127.0.0.1:8080/healthz      # {"status":"ok"}
```

O banco, as pastas de fotos e as migrações são criados sozinhos na primeira execução.
Para ver o fluxo completo (cadastro → roda → publicação → feed), siga os exemplos de
[`docs/api.md`](docs/api.md).

### Catálogo de músicas (opcional)

O piloto funciona sem músicas. Para ter um catálogo, coloque **arquivos próprios ou
autorizados** em `MM_MUSIC_DIR` (padrão `./data/music`) e crie ali um `catalog.json`
(modelo em [`deploy/catalog.example.json`](deploy/catalog.example.json)). O campo `license`
é **obrigatório**: registre de onde vem a autorização de uso. O catálogo é lido ao iniciar o
programa, então reinicie depois de alterá-lo. Se algo estiver errado (arquivo faltando, `license`
vazio, id repetido), o programa **não inicia** e lista todos os problemas.
Formatos aceitos: `.mp3`, `.m4a`, `.ogg`, `.wav`.

## Configuração

Tudo por variáveis de ambiente `MM_*`, todas opcionais (veja [`.env.example`](.env.example)).

| Variável | Padrão | O que controla |
|---|---|---|
| `MM_ADDR` | `:8080` | endereço de escuta (na VPS use `127.0.0.1:8080` atrás do proxy) |
| `MM_DB_PATH` | `./data/metemarcha.db` | arquivo SQLite |
| `MM_MEDIA_DIR` | `./data/media` | fotos enviadas |
| `MM_MUSIC_DIR` | `./data/music` | `catalog.json` e áudios |
| `MM_GROUP_MAX_MEMBERS` | `10` | participantes por roda |
| `MM_INVITE_TTL` | `168h` | validade do convite de roda |
| `MM_SESSION_TTL` | `720h` | validade da sessão (30 dias) |
| `MM_STORY_VISIBLE_FOR` | `24h` | tempo no feed |
| `MM_STORY_RECOVERABLE_FOR` | `72h` | limite total (depois disso: apagado) |
| `MM_MAX_CLIP` | `30s` | duração máxima do trecho de música |
| `MM_MAX_PHOTO_BYTES` | `8388608` | tamanho máximo da foto (8 MiB) |
| `MM_MAX_PHOTO_SIDE` | `4096` | maior lado da imagem, em pixels |
| `MM_CLEANUP_INTERVAL` | `15m` | intervalo da limpeza |
| `MM_ORPHAN_GRACE` | `1h` | carência antes de apagar arquivos sem registro |
| `MM_PASSWORD_MEMORY_KIB` | `65536` | custo de memória do argon2id (64 MiB) |

Valores inválidos (por exemplo, `72h` menor que `24h`) impedem o início, com mensagem clara.

## Configurar a VPS

Exemplo para Ubuntu/Debian. Os arquivos em [`deploy/`](deploy/) são pontos de partida:
adapte domínio e caminhos. **Não foram testados em uma VPS real** nesta entrega (veja "Verificações").

1. **Compilar na própria VPS** (o driver usa cgo, então compilar em outro sistema exige toolchain cruzada):
   ```bash
   sudo apt install build-essential golang-go   # confira que o Go instalado é 1.22+ (go version)
   git clone <repo> && cd MeteMarcha/backend && git checkout feature/backend-rodas
   go mod download && go test ./...
   CGO_ENABLED=1 go build -o api ./cmd/api
   ```
2. **Usuário e pastas** (o programa não roda como root):
   ```bash
   sudo useradd --system --home /var/lib/metemarcha --shell /usr/sbin/nologin metemarcha
   sudo install -d -o metemarcha -g metemarcha -m 750 /var/lib/metemarcha
   sudo install -d /opt/metemarcha /etc/metemarcha
   sudo install -m 755 api /opt/metemarcha/api
   ```
3. **Configuração**: copie `.env.example` para `/etc/metemarcha/metemarcha.env` e use caminhos absolutos:
   `MM_ADDR=127.0.0.1:8080`, `MM_DB_PATH=/var/lib/metemarcha/metemarcha.db`,
   `MM_MEDIA_DIR=/var/lib/metemarcha/media`, `MM_MUSIC_DIR=/var/lib/metemarcha/music`.
   Coloque suas músicas e o `catalog.json` em `/var/lib/metemarcha/music` (dono `metemarcha`).
4. **Serviço**: copie `deploy/metemarcha.service` para `/etc/systemd/system/` e rode
   `sudo systemctl daemon-reload && sudo systemctl enable --now metemarcha`.
   Acompanhe com `journalctl -u metemarcha -f`.
5. **HTTPS (obrigatório)**: o token de sessão trafega no cabeçalho `Authorization`, então **nunca
   exponha o programa em HTTP puro**. Use um proxy com certificado (exemplo com Caddy em
   [`deploy/Caddyfile.example`](deploy/Caddyfile.example)) e libere no firewall só as portas 80 e 443
   (`sudo ufw allow 80,443/tcp`). A porta 8080 fica fechada para fora.
6. **Backup**: guarde `MM_DB_PATH` e `MM_MEDIA_DIR`. Para o banco, prefira cópia consistente:
   `sqlite3 /var/lib/metemarcha/metemarcha.db ".backup '/caminho/backup.db'"` (pacote `sqlite3`).
7. **Atualizar**: compile o novo binário, `sudo systemctl stop metemarcha`, substitua
   `/opt/metemarcha/api`, `sudo systemctl start metemarcha`. Migrações novas rodam sozinhas ao iniciar.
   Reiniciar é seguro: a limpeza retoma de onde parou.

## Limites conhecidos do piloto

- **Sem limite de tentativas de login/cadastro.** O cadastro é aberto (só o convite de *roda* existe);
  coloque limitação de taxa no proxy (por exemplo `limit_req` no nginx) antes de divulgar o endereço.
- Cadastro revela se um e-mail já existe (`email_taken`). Aceitável num piloto fechado.
- Uma instância apenas (SQLite). Sem recuperação de senha, sem verificação de e-mail.
- O servidor remove os metadados EXIF das fotos, **inclusive a orientação**. O app precisa enviar
  a imagem já rotacionada (veja `docs/api.md`).
