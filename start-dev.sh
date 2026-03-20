#!/bin/bash
# Inicia o ambiente de desenvolvimento do sys-fc
# Uso: ./start-dev.sh

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔄 Iniciando banco de dados..."
docker compose -f "$PROJECT_DIR/docker-compose.yml" up -d db

echo "⏳ Aguardando banco ficar saudável..."
until docker compose -f "$PROJECT_DIR/docker-compose.yml" exec db pg_isready -U postgres -q 2>/dev/null; do
  sleep 1
done

echo "🚀 Iniciando backend Phoenix..."
docker stop sys_fc_dev 2>/dev/null || true

docker run --rm -d \
  --name sys_fc_dev \
  --network sys-fc_default \
  -v "$PROJECT_DIR:/app" \
  -w /app \
  -e MIX_ENV=dev \
  -e HOME=/root \
  -e DB_HOST=db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=sys_fc_dev \
  -p 4000:4000 \
  elixir:1.17.3-alpine \
  sh -c "apk add --no-cache build-base libsodium-dev -q 2>/dev/null && \
         mix local.hex --force -q && \
         mix local.rebar --force -q && \
         mix phx.server"

echo "⏳ Aguardando Phoenix iniciar..."
until curl -s http://localhost:4000/api/auth/login -X POST \
  -H 'Content-Type: application/json' -d '{}' > /dev/null 2>&1; do
  sleep 2
done

echo ""
echo "✅ Backend rodando em http://localhost:4000"
echo "   Logs: docker logs -f sys_fc_dev"
echo "   Parar: docker stop sys_fc_dev"
