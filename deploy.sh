#!/bin/bash
set -e

# ============================================================
# Script de Deploy - sys-fc (Elixir/Phoenix)
# Uso: bash deploy.sh
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[AVISO]${NC} $1"; }
error() { echo -e "${RED}[ERRO]${NC} $1"; exit 1; }

# ============================================================
# 1. Verificar/Instalar Docker
# ============================================================
install_docker() {
  if command -v docker &> /dev/null; then
    info "Docker já instalado: $(docker --version)"
  else
    info "Instalando Docker..."
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case "$ID" in
        amzn|amazonlinux)
          sudo yum update -y
          sudo yum install -y docker
          ;;
        ubuntu|debian)
          sudo apt update -y
          sudo apt install -y docker.io
          ;;
        *)
          error "Sistema não suportado: $ID. Instale o Docker manualmente."
          ;;
      esac
    fi
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker "$USER"
    info "Docker instalado. Se der erro de permissão, saia e reconecte (exit + ssh)."
  fi
}

install_docker_compose() {
  if docker compose version &> /dev/null; then
    info "Docker Compose já instalado."
  else
    info "Instalando Docker Compose plugin..."
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    info "Docker Compose instalado."
  fi
}

install_git() {
  if command -v git &> /dev/null; then
    info "Git já instalado."
  else
    info "Instalando Git..."
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case "$ID" in
        amzn|amazonlinux) sudo yum install -y git ;;
        ubuntu|debian) sudo apt install -y git ;;
      esac
    fi
  fi
}

# ============================================================
# 2. Clonar ou atualizar repositório
# ============================================================
setup_repo() {
  APP_DIR="$HOME/sys-fc"

  if [ -d "$APP_DIR/.git" ]; then
    info "Repositório já existe em $APP_DIR. Atualizando..."
    cd "$APP_DIR"
    git pull
  else
    echo ""
    read -rp "URL do repositório Git (ex: https://github.com/user/sys-fc.git): " REPO_URL
    if [ -z "$REPO_URL" ]; then
      error "URL do repositório é obrigatória."
    fi
    info "Clonando repositório..."
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
  fi

  info "Diretório do projeto: $APP_DIR"
}

# ============================================================
# 3. Gerar secrets e criar .env.prod
# ============================================================
setup_env() {
  cd "$HOME/sys-fc"

  if [ -f .env.prod ]; then
    warn "Arquivo .env.prod já existe."
    read -rp "Deseja recriar? (s/N): " RECREATE
    if [[ ! "$RECREATE" =~ ^[sS]$ ]]; then
      info "Mantendo .env.prod existente."
      return
    fi
  fi

  info "Gerando secrets..."
  SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n+/=' | head -c 64)
  JWT_SECRET=$(openssl rand -base64 48 | tr -d '\n+/=' | head -c 48)
  DB_PASSWORD=$(openssl rand -base64 32 | tr -d '\n+/=' | head -c 32)

  echo ""
  info "Configure as variáveis de ambiente:"
  echo ""

  # IP/Domínio
  DEFAULT_IP=$(curl -s --max-time 5 http://checkip.amazonaws.com 2>/dev/null || echo "")
  if [ -n "$DEFAULT_IP" ]; then
    read -rp "IP ou domínio público da EC2 [$DEFAULT_IP]: " PHX_HOST
    PHX_HOST=${PHX_HOST:-$DEFAULT_IP}
  else
    read -rp "IP ou domínio público da EC2: " PHX_HOST
  fi

  # CORS
  read -rp "URL do frontend para CORS (ex: http://meusite.com): " CORS_ORIGINS
  CORS_ORIGINS=${CORS_ORIGINS:-"http://localhost:3000"}

  # Porta
  read -rp "Porta da API [4000]: " PORT
  PORT=${PORT:-4000}

  # Admin
  echo ""
  info "Dados do usuário admin:"
  read -rp "Email do admin [admin@sysfc.com]: " ADMIN_EMAIL
  ADMIN_EMAIL=${ADMIN_EMAIL:-"admin@sysfc.com"}

  read -rsp "Senha do admin [Admin@2026!]: " ADMIN_PASSWORD
  echo ""
  ADMIN_PASSWORD=${ADMIN_PASSWORD:-"Admin@2026!"}

  read -rp "Nome do admin [Administrador]: " ADMIN_NAME
  ADMIN_NAME=${ADMIN_NAME:-"Administrador"}

  cat > .env.prod << EOF
# Database
POSTGRES_USER=sys_fc
POSTGRES_PASSWORD=$DB_PASSWORD
POSTGRES_DB=sys_fc_prod

# Phoenix
SECRET_KEY_BASE=$SECRET_KEY_BASE
JWT_SECRET=$JWT_SECRET
JWT_EXPIRY_SECONDS=604800
PHX_HOST=$PHX_HOST
PORT=$PORT
POOL_SIZE=10

# CORS
CORS_ORIGINS=$CORS_ORIGINS

# Admin
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD
ADMIN_NAME=$ADMIN_NAME
EOF

  chmod 600 .env.prod
  info "Arquivo .env.prod criado com permissões restritas."
}

# ============================================================
# 4. Build e start dos containers
# ============================================================
start_containers() {
  cd "$HOME/sys-fc"

  info "Fazendo build da imagem (pode demorar alguns minutos na primeira vez)..."
  docker compose -f docker-compose.prod.yml --env-file .env.prod build

  info "Subindo containers..."
  docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

  info "Aguardando banco de dados ficar pronto..."
  sleep 5

  # Aguardar o banco ficar healthy
  RETRIES=0
  MAX_RETRIES=30
  while [ $RETRIES -lt $MAX_RETRIES ]; do
    if docker compose -f docker-compose.prod.yml ps db | grep -q "healthy"; then
      info "Banco de dados pronto!"
      break
    fi
    RETRIES=$((RETRIES + 1))
    sleep 2
  done

  if [ $RETRIES -eq $MAX_RETRIES ]; then
    error "Banco de dados não ficou pronto a tempo. Verifique com: docker compose -f docker-compose.prod.yml logs db"
  fi

  # Aguardar o backend subir
  info "Aguardando backend iniciar..."
  sleep 5
}

# ============================================================
# 5. Migrations e seed do admin
# ============================================================
run_migrations() {
  cd "$HOME/sys-fc"

  info "Rodando migrations..."
  docker compose -f docker-compose.prod.yml exec -T backend bin/sys_fc eval "SysFc.Release.migrate()"
  info "Migrations concluídas!"
}

seed_admin() {
  cd "$HOME/sys-fc"

  info "Criando usuário admin..."
  docker compose -f docker-compose.prod.yml exec -T backend bin/sys_fc eval "SysFc.Release.seed_admin()"
  info "Usuário admin criado!"
}

# ============================================================
# 6. Verificar se está tudo OK
# ============================================================
verify() {
  cd "$HOME/sys-fc"

  source .env.prod
  local PORT_VAL=${PORT:-4000}

  echo ""
  info "Verificando se a API está respondendo..."
  sleep 3

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT_VAL/api/auth/login" 2>/dev/null || echo "000")

  if [ "$HTTP_CODE" != "000" ]; then
    info "API respondendo! (HTTP $HTTP_CODE)"
  else
    warn "API ainda não respondeu. Pode estar inicializando. Verifique os logs:"
    echo "  docker compose -f docker-compose.prod.yml logs -f backend"
    return
  fi

  echo ""
  echo "=========================================="
  echo -e "${GREEN} DEPLOY CONCLUÍDO COM SUCESSO!${NC}"
  echo "=========================================="
  echo ""
  echo "  API:   http://${PHX_HOST}:${PORT_VAL}/api"
  echo "  Admin: ${ADMIN_EMAIL}"
  echo ""
  echo "  Comandos úteis:"
  echo "    Logs:        docker compose -f docker-compose.prod.yml logs -f"
  echo "    Reiniciar:   docker compose -f docker-compose.prod.yml restart"
  echo "    Parar:       docker compose -f docker-compose.prod.yml down"
  echo "    Re-deploy:   bash deploy.sh"
  echo ""
}

# ============================================================
# MAIN
# ============================================================
echo ""
echo "=========================================="
echo "  Deploy sys-fc - Elixir/Phoenix + Docker"
echo "=========================================="
echo ""

install_docker
install_docker_compose
install_git
setup_repo
setup_env
start_containers
run_migrations
seed_admin
verify
