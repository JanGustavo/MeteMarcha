#!/usr/bin/env bash
# MeteMarcha: inspeção read-only ou deploy da API Go na VPS compartilhada.
# Uso: ./backend/deploy/newDeploy.sh inspect HOST SSH_KEY USER
#      ./backend/deploy/newDeploy.sh deploy HOST SSH_KEY USER DOMAIN ACME_EMAIL
# Porta local padrão: 8084 (MM_DEPLOY_PORT pode alterar).
set -euo pipefail

usage() {
  echo 'Uso: newDeploy.sh inspect HOST SSH_KEY USER' >&2
  echo '     newDeploy.sh deploy HOST SSH_KEY USER DOMAIN ACME_EMAIL' >&2
  exit 2
}

ACTION="${1:-}"
HOST="${2:-}"
KEY="${3:-}"
USER="${4:-}"
DOMAIN="${5:-}"
EMAIL="${6:-}"
PORT="${MM_DEPLOY_PORT:-8084}"

[[ "$ACTION" == inspect || "$ACTION" == deploy ]] || usage
[[ "$HOST" =~ ^[A-Za-z0-9.-]+$ && "$USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || usage
[[ -f "$KEY" && "$PORT" =~ ^[0-9]+$ ]] || usage
(( PORT >= 1024 && PORT <= 65535 )) || usage
if [[ "$ACTION" == deploy ]]; then
  [[ "$DOMAIN" =~ ^[a-z0-9][a-z0-9.-]*\.[a-z]{2,}$ && "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] || usage
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SSH=(ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10 -i "$KEY")
SCP=(scp -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10 -i "$KEY")
TARGET="$USER@$HOST"
remote() { "${SSH[@]}" "$TARGET" "$@"; }
log() { printf '[MeteMarcha] %s\n' "$*"; }

log "Conectando a $TARGET"
remote 'sudo -n true' >/dev/null

if [[ "$ACTION" == inspect ]]; then
  remote "bash -s -- $PORT" <<'REMOTE'
set -euo pipefail
port="$1"
printf '\nMáquina: '; hostname
printf 'Arquitetura: '; uname -m
printf '\nServiços relevantes:\n'
systemctl list-units --type=service --state=running --no-legend --no-pager | grep -E 'nginx|cronflow|tjpb|docker|metemarcha' || true
printf '\nPortas TCP em escuta:\n'
ss -H -lnt
printf '\nPorta candidata %s: ' "$port"
if ss -H -lnt "( sport = :$port )" | grep -q .; then echo OCUPADA; else echo LIVRE; fi
printf '\nEspaço e memória:\n'
df -h / | tail -1
free -h | head -2
printf '\nPré-requisitos:\n'
for tool in nginx certbot curl; do command -v "$tool" || true; done
printf '\nServiço existente:\n'
systemctl is-active metemarcha 2>/dev/null || true
REMOTE
  exit 0
fi

# O app guarda sessões; o deploy exige HTTPS válido e DNS apontando à VPS.
command -v getent >/dev/null || { log 'getent não encontrado'; exit 1; }
HOST_IPS="$(getent ahostsv4 "$HOST" 2>/dev/null | awk '{print $1}' | sort -u || true)"
DOMAIN_IPS="$(getent ahostsv4 "$DOMAIN" 2>/dev/null | awk '{print $1}' | sort -u || true)"
[[ -n "$DOMAIN_IPS" && -n "$HOST_IPS" ]] || { log 'DNS do host/domínio não resolve'; exit 1; }
if ! grep -Fqx -f <(printf '%s\n' "$HOST_IPS") <(printf '%s\n' "$DOMAIN_IPS"); then
  log "DNS de $DOMAIN ainda não aponta para $HOST; deploy cancelado"
  exit 1
fi

remote "bash -s -- $PORT $DOMAIN" <<'REMOTE'
set -euo pipefail
port="$1"
domain="$2"
[[ "$(uname -m)" == x86_64 ]] || { echo 'VPS precisa ser x86_64' >&2; exit 1; }
command -v nginx >/dev/null
command -v certbot >/dev/null
command -v curl >/dev/null
sudo -n nginx -t >/dev/null
if sudo -n test -e "/etc/nginx/sites-available/metemarcha"; then
  grep -Fq "server_name $domain;" /etc/nginx/sites-available/metemarcha || {
    echo 'Site MeteMarcha existente usa outro domínio' >&2; exit 1;
  }
fi
if ss -H -lnt "( sport = :$port )" | grep -q . && ! systemctl is-active --quiet metemarcha; then
  echo "Porta $port ocupada por outro serviço" >&2; exit 1
fi
REMOTE

[[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] || {
  log 'Compilação local exige Linux x86_64 com CGO'; exit 1;
}
command -v go >/dev/null
command -v gcc >/dev/null

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
log 'Testando e compilando API Go localmente'
(cd "$ROOT/backend" && go test ./... && CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -o "$TMP/api" ./cmd/api)
sed -e "s/__MM_DOMAIN__/$DOMAIN/g" -e "s/__MM_PORT__/$PORT/g" \
  "$ROOT/backend/deploy/nginx.metemarcha.conf" > "$TMP/nginx.conf"
sed -e "s/__MM_DOMAIN__/$DOMAIN/g" \
  "$ROOT/backend/deploy/nginx.metemarcha-bootstrap.conf" > "$TMP/nginx-bootstrap.conf"

STAGE="$(remote 'mktemp -d /tmp/metemarcha-deploy.XXXXXX')"
[[ "$STAGE" =~ ^/tmp/metemarcha-deploy\.[A-Za-z0-9]+$ ]] || { log 'Diretório temporário remoto inválido'; exit 1; }
"${SCP[@]}" "$TMP/api" "$ROOT/backend/deploy/metemarcha.service" \
  "$TMP/nginx.conf" "$TMP/nginx-bootstrap.conf" "$TARGET:$STAGE/"
LINK_CHECK="$(remote "ldd $STAGE/api" 2>&1)"
if grep -Eq 'not found|version .* not found' <<< "$LINK_CHECK"; then
  log "Binário incompatível com a VPS: $LINK_CHECK"
  exit 1
fi

log 'Criando backup e instalando serviço sem alterar outros aplicativos'
remote "sudo -n bash -s -- $STAGE $PORT" <<'REMOTE'
set -euo pipefail
stage="$1"
port="$2"
if ! id metemarcha >/dev/null 2>&1; then
  useradd --system --home /var/lib/metemarcha --shell /usr/sbin/nologin metemarcha
fi
install -d -o metemarcha -g metemarcha -m 750 /var/lib/metemarcha /var/lib/metemarcha/media /var/lib/metemarcha/music
install -d -o root -g root -m 755 /opt/metemarcha /etc/metemarcha
install -d -o root -g root -m 700 /opt/metemarcha/backups
if [[ -f /etc/metemarcha/metemarcha.env ]]; then
  grep -Fqx "MM_ADDR=127.0.0.1:$port" /etc/metemarcha/metemarcha.env || {
    echo 'MM_ADDR existente difere da porta escolhida' >&2; exit 1;
  }
else
  umask 077
  cat > /etc/metemarcha/metemarcha.env <<ENV
MM_ADDR=127.0.0.1:$port
MM_DB_PATH=/var/lib/metemarcha/metemarcha.db
MM_MEDIA_DIR=/var/lib/metemarcha/media
MM_MUSIC_DIR=/var/lib/metemarcha/music
ENV
fi
if systemctl is-active --quiet metemarcha; then systemctl stop metemarcha; fi
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
if [[ -f /opt/metemarcha/api ]]; then
  cp -a /opt/metemarcha/api "/opt/metemarcha/backups/api-$stamp"
fi
if [[ -f /var/lib/metemarcha/metemarcha.db ]]; then
  tar -C /var/lib -czf "/opt/metemarcha/backups/data-$stamp.tar.gz" metemarcha
fi
install -o root -g root -m 755 "$stage/api" /opt/metemarcha/api
install -o root -g root -m 644 "$stage/metemarcha.service" /etc/systemd/system/metemarcha.service
systemctl daemon-reload
systemctl enable --now metemarcha
for attempt in $(seq 1 15); do
  if curl -fsS "http://127.0.0.1:$port/healthz" >/dev/null; then break; fi
  if [[ "$attempt" == 15 ]]; then
    journalctl -u metemarcha -n 25 --no-pager >&2
    echo 'Health check local falhou; backup em /opt/metemarcha/backups' >&2
    exit 1
  fi
  sleep 2
done
echo 'API saudável em loopback'
REMOTE

log 'Emitindo certificado antes de publicar a API no Nginx'
remote "sudo -n bash -s -- $STAGE $DOMAIN $EMAIL" <<'REMOTE'
set -euo pipefail
stage="$1"
domain="$2"
email="$3"
install -d -o root -g root -m 755 /var/www/metemarcha-acme
if [[ ! -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]]; then
  install -o root -g root -m 644 "$stage/nginx-bootstrap.conf" /etc/nginx/sites-available/metemarcha
  ln -sfn /etc/nginx/sites-available/metemarcha /etc/nginx/sites-enabled/metemarcha
  nginx -t
  systemctl reload nginx
fi
certbot certonly --webroot -w /var/www/metemarcha-acme \
  --non-interactive --agree-tos --keep-until-expiring \
  --deploy-hook 'systemctl reload nginx' -m "$email" -d "$domain"
install -o root -g root -m 644 "$stage/nginx.conf" /etc/nginx/sites-available/metemarcha
ln -sfn /etc/nginx/sites-available/metemarcha /etc/nginx/sites-enabled/metemarcha
nginx -t
systemctl reload nginx
rm -rf "$stage"
REMOTE

log "Implantação concluída: https://$DOMAIN/healthz"
