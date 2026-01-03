#!/bin/bash

# Cores para logs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

BASE_DIR="/www"
NETWORK_NAME="app_network"

echo -e "${GREEN}>>> Iniciando instalador do Sistema Rayan Novik (v2 com Cloudflare) <<<${NC}"

# 1. Verificar Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Por favor, execute como root (sudo).${NC}"
  exit
fi

# 2. Instalar Dependências (Docker, Git, Compose)
echo -e "${YELLOW}>>> Instalando dependências (Docker, Git)...${NC}"
apt-get update -y
apt-get install -y git curl apt-transport-https ca-certificates software-properties-common gnupg lsb-release

# Instalar Docker se não existir
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

# 3. Criar estrutura de pastas e Rede Docker
echo -e "${YELLOW}>>> Configurando diretório /www e Rede Docker...${NC}"
mkdir -p $BASE_DIR
cd $BASE_DIR

# Cria rede para comunicação entre os containers
if ! docker network ls | grep -q "$NETWORK_NAME"; then
  docker network create $NETWORK_NAME
fi

# 4. Clonar Repositórios
echo -e "${YELLOW}>>> Baixando repositórios...${NC}"

clone_or_pull() {
    if [ -d "$2" ]; then
        echo "Atualizando $2..."
        cd $2 && git pull && cd ..
    else
        echo "Clonando $2..."
        git clone $1 $2
    fi
}

clone_or_pull "https://github.com/Rayan-Novik/admin.git" "admin"
clone_or_pull "https://github.com/Rayan-Novik/frontend.git" "frontend"
clone_or_pull "https://github.com/Rayan-Novik/backend.git" "backend"

# 5. Configurar Banco de Dados Central (MySQL + PhpMyAdmin)
echo -e "${YELLOW}>>> Configurando MySQL e PhpMyAdmin...${NC}"

# --- ATUALIZAÇÃO: Valores Padrão (root / ecommerce_db) ---
read -p "Defina uma senha ROOT para o MySQL [Padrão: root]: " INPUT_PASS
DB_ROOT_PASSWORD=${INPUT_PASS:-root}

read -p "Defina o nome do banco de dados [Padrão: ecommerce_db]: " INPUT_DB
DB_NAME=${INPUT_DB:-ecommerce_db}

echo -e "${GREEN}Usando Senha: '$DB_ROOT_PASSWORD' e Banco: '$DB_NAME'${NC}"
echo ""

# Cria docker-compose da infraestrutura
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: mysql_server
    command: --default-authentication-plugin=mysql_native_password
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_NAME}
    volumes:
      - ./mysql_data:/var/lib/mysql
    networks:
      - ${NETWORK_NAME}

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: phpmyadmin
    restart: always
    environment:
      PMA_HOST: mysql
      UPLOAD_LIMIT: 64M
    ports:
      - "8080:80"
    networks:
      - ${NETWORK_NAME}

networks:
  ${NETWORK_NAME}:
    external: true
EOF

# Sobe a infraestrutura primeiro
docker compose up -d

# 6. Configuração Interativa dos ENVs
echo -e "${GREEN}>>> CONFIGURAÇÃO DE DOMÍNIOS E VARIÁVEIS <<<${NC}"

# --- BACKEND CONFIG ---
echo -e "${YELLOW}Configurando BACKEND...${NC}"
read -p "URL do Frontend (ex: https://ecommercerpool.shop): " BE_FRONT_URL
read -p "URL do Backend (ex: https://back.ecommercerpool.shop): " BE_BACK_URL

# DATABASE_URL para o Prisma (Conectando ao container mysql_server)
DB_URL="mysql://root:${DB_ROOT_PASSWORD}@mysql_server:3306/${DB_NAME}"

# Cria arquivo .env no local esperado pelo docker-compose do backend (src/.env)
mkdir -p backend/src
cat <<EOF > backend/src/.env
NODE_ENV=production
FRONTEND_URL=${BE_FRONT_URL}
BACKEND_URL=${BE_BACK_URL}
DATABASE_URL="${DB_URL}"
PORT=5000
EOF

# Ajusta o docker-compose do backend para usar a rede externa
cat <<EOF >> backend/docker-compose.yml

networks:
  default:
    name: ${NETWORK_NAME}
    external: true
EOF

# --- FRONTEND CONFIG ---
echo -e "${YELLOW}Configurando FRONTEND...${NC}"
read -p "API URL para o Frontend (ex: https://back.ecommercerpool.shop/api): " FE_API_URL
read -p "Encryption Key (32 chars): " FE_ENC_KEY
read -p "Encryption IV (16 chars): " FE_ENC_IV

cat <<EOF > frontend/.env
REACT_APP_API_URL=${FE_API_URL}
REACT_APP_ENCRYPTION_KEY=${FE_ENC_KEY}
REACT_APP_ENCRYPTION_IV=${FE_ENC_IV}
EOF

# Ajusta o docker-compose do frontend
cat <<EOF >> frontend/docker-compose.yml

networks:
  default:
    name: ${NETWORK_NAME}
    external: true
EOF

# --- ADMIN CONFIG ---
echo -e "${YELLOW}Configurando ADMIN...${NC}"
read -p "API URL para o Admin: " ADM_API_URL
read -p "Ecommerce URL: " ADM_ECOMM_URL
read -p "JWT Secret: " ADM_JWT
# Reutilizando chaves se o usuário quiser, ou pedindo novas
read -p "Encryption Key Admin (Enter para usar a mesma do front): " ADM_ENC_KEY
[ -z "$ADM_ENC_KEY" ] && ADM_ENC_KEY=$FE_ENC_KEY
read -p "Encryption IV Admin (Enter para usar a mesma do front): " ADM_ENC_IV
[ -z "$ADM_ENC_IV" ] && ADM_ENC_IV=$FE_ENC_IV

cat <<EOF > admin/.env
REACT_APP_API_URL=${ADM_API_URL}
REACT_APP_ECOMMERCE_URL=${ADM_ECOMM_URL}
JWT_SECRET=${ADM_JWT}
ENCRYPTION_KEY=${ADM_ENC_KEY}
ENCRYPTION_IV=${ADM_ENC_IV}
REACT_APP_ENCRYPTION_KEY=${ADM_ENC_KEY}
REACT_APP_ENCRYPTION_IV=${ADM_ENC_IV}
PORT=3001
EOF

# Ajusta o docker-compose do admin
cat <<EOF >> admin/docker-compose.yml

networks:
  default:
    name: ${NETWORK_NAME}
    external: true
EOF

# 7. Build e Start
echo -e "${YELLOW}>>> Construindo e iniciando os serviços...${NC}"

# Backend
cd $BASE_DIR/backend
echo "Iniciando Backend..."
docker compose build
docker compose up -d

# Aguarda o backend subir para rodar migrations se necessário
sleep 5

# Frontend
cd $BASE_DIR/frontend
echo "Iniciando Frontend..."
docker compose build
docker compose up -d

# Admin
cd $BASE_DIR/admin
echo "Iniciando Admin..."
docker compose build
docker compose up -d

# 8. Instalação do Cloudflare Zero Trust (NOVO)
echo -e "${GREEN}>>> CLOUDFLARE ZERO TRUST SETUP <<<${NC}"
read -p "Deseja instalar e conectar o agente do Cloudflare agora? (s/n): " CF_OPT

if [ "$CF_OPT" == "s" ]; then
    echo "Baixando cloudflared..."
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i cloudflared.deb
    rm cloudflared.deb

    echo -e "${YELLOW}Vá no painel Zero Trust > Access > Tunnels, crie um túnel e copie o token.${NC}"
    read -p "Cole seu Token do Cloudflare aqui: " CF_TOKEN
    
    if [ ! -z "$CF_TOKEN" ]; then
        # Remove instalação anterior se houver e instala a nova
        cloudflared service uninstall 2>/dev/null
        cloudflared service install "$CF_TOKEN"
        echo "Cloudflare Tunnel instalado e rodando!"
    else
        echo "Token vazio, pulando etapa."
    fi
fi

echo -e "${GREEN}>>> INSTALAÇÃO CONCLUÍDA! <<<${NC}"
echo "Serviços rodando localmente (configure o Cloudflare Tunnel para expor):"
echo "Backend: 5000"
echo "Frontend: 3000"
echo "Admin: 3001"
echo "PhpMyAdmin: 8080"