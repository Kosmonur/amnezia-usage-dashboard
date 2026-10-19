#!/usr/bin/env bash
# Ensure PUBLIC_HOSTNAME is in .env and recreate Caddy (public installs).
set -euo pipefail
cd "$(dirname "$0")/.."

HOST="${1:-awg-stats.int-cloud.net}"

if grep -qE '^PUBLIC_HOSTNAME=' .env 2>/dev/null; then
  sed -i "s/^PUBLIC_HOSTNAME=.*/PUBLIC_HOSTNAME=${HOST}/" .env
else
  printf '\nPUBLIC_HOSTNAME=%s\n' "$HOST" >>.env
fi

echo "PUBLIC_HOSTNAME=$(grep -E '^PUBLIC_HOSTNAME=' .env | cut -d= -f2-)"

if command -v docker >/dev/null && docker compose version >/dev/null 2>&1; then
  docker compose up -d --force-recreate caddy
elif command -v docker-compose >/dev/null; then
  docker-compose up -d --force-recreate caddy
else
  echo "error: docker compose not found" >&2
  exit 1
fi

sleep 2
docker inspect -f '{{.State.Status}} exit={{.State.ExitCode}}' awg-stats-caddy
docker logs awg-stats-caddy --tail 20
curl -skS -o /dev/null -w "local_https=%{http_code}\n" \
  --resolve "${HOST}:443:127.0.0.1" "https://${HOST}/login"
