#!/bin/bash

# Cores para logs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

BASE_DIR="/www"
NETWORK_NAME="app_network"

# === VARIÁVEIS FIXAS (SEGURANÇA E BANCO) ===
DB_ROOT_PASSWORD="root"
DB_NAME="ecommerce_db"
DB_HOST="mysql_server" # Nome do container na rede interna
ENCRYPTION_KEY="a1b2c3d4e5f6a7b8a1b2c3d4e5f6a7b8"
ENCRYPTION_IV="a1b2c3d4e5f6a7b8"
JWT_SECRET="umasenhasupersecretadificildeadivinhar12345"

echo -e "${GREEN}>>> Iniciando instalador do Sistema Rayan Novik (Automação Total) <<<${NC}"

# 1. Verificar Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Por favor, execute como root (sudo).${NC}"
  exit
fi

# 2. Instalar Dependências
echo -e "${YELLOW}>>> Instalando dependências...${NC}"
apt-get update -y
apt-get install -y git curl apt-transport-https ca-certificates software-properties-common gnupg lsb-release

# Instalar Docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

# 3. Criar estrutura e Rede
echo -e "${YELLOW}>>> Configurando pastas e rede...${NC}"
mkdir -p $BASE_DIR
cd $BASE_DIR

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

# 5. Subir MySQL e PhpMyAdmin (Configuração Fixa)
echo -e "${YELLOW}>>> Subindo Banco de Dados...${NC}"

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

docker compose up -d

# 6. CONFIGURAÇÃO DE DOMÍNIOS (A única parte interativa)
echo -e "${GREEN}>>> CONFIGURAÇÃO DE DOMÍNIOS <<<${NC}"
echo "Informe apenas a URL base (sem /api). O script ajusta o resto."

read -p "URL do Frontend (ex: https://ecommercerpool.shop): " USER_FRONT_URL
read -p "URL do Backend (ex: https://back.ecommercerpool.shop): " USER_BACK_URL

# Remove barra no final se o usuário digitar (para evitar erros tipo //.api)
FRONT_URL=${USER_FRONT_URL%/}
BACK_URL=${USER_BACK_URL%/}
API_URL="${BACK_URL}/api"

echo -e "${YELLOW}Configurando automaticamente:${NC}"
echo "Frontend: $FRONT_URL"
echo "Backend:  $BACK_URL"
echo "API URL:  $API_URL"

# --- GERAR .ENV DO BACKEND ---
echo -e "${YELLOW}Gerando env Backend...${NC}"
mkdir -p backend/src
cat <<EOF > backend/src/.env
# CONFIGURAÇÕES DO SERVIDOR
SERVER_PORT=5000

# CONFIGURAÇÕES DO BANCO DE DADOS (Docker Internal)
DB_HOST=${DB_HOST}
DB_USER=root
DB_PASSWORD=${DB_ROOT_PASSWORD}
DB_NAME=${DB_NAME}
DB_PORT=3306

# Prisma
DATABASE_URL="mysql://root:${DB_ROOT_PASSWORD}@${DB_HOST}:3306/${DB_NAME}"

# === INTEGRAÇÃO SQL SERVER (LEGADO) ===
SYNC_ENABLED=false
EXTERNAL_DB_HOST=localhost
EXTERNAL_DB_PORT=1433
EXTERNAL_DB_USER=sa
EXTERNAL_DB_PASSWORD=senha
EXTERNAL_DB_NAME=NomeDoBancoDeles

# URLs DO SISTEMA
FRONTEND_URL=${FRONT_URL}
BACKEND_URL=${BACK_URL}

# EMAIL
SMTP_HOST=smtp.gmail.com
SMTP_PORT=465
SMTP_USER=rayanschaveshotmail@gmail.com
SMTP_PASS=jfdoqendlzyatjlu
EMAIL_FROM=rayanschaveshotmail@gmail.com

# SEGURANÇA
JWT_SECRET=${JWT_SECRET}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
ENCRYPTION_IV=${ENCRYPTION_IV}

# --- MAPEAMENTO DO BANCO DE DADOS ---
TABLE_PRODUTOS_NOME=produtos
TABLE_PRODUTOS_COL_ID=id_produto
TABLE_PRODUTOS_COL_NOME=nome
TABLE_PRODUTOS_COL_DESCRICAO=descricao
TABLE_PRODUTOS_COL_PRECO=preco
TABLE_PRODUTOS_COL_ESTOQUE=estoque
TABLE_PRODUTOS_COL_IMAGEM_URL=imagem_url

TABLE_USUARIOS_NOME=usuarios
TABLE_USUARIOS_COL_ID=id_usuario
TABLE_USUARIOS_COL_NOME=nome_completo
TABLE_USUARIOS_COL_EMAIL=email
TABLE_USUARIOS_COL_SENHA=hash_senha
TABLE_USUARIOS_COL_TELEFONE=telefone_criptografado
TABLE_USUARIOS_COL_CPF=cpf_criptografado
TABLE_USUARIOS_COL_DATA_NASCIMENTO=data_nascimento_criptografada
TABLE_USUARIOS_COL_ASAAS_ID=asaas_customer_id

TABLE_ENDERECOS_NOME=enderecos
TABLE_ENDERECOS_COL_ID=id_endereco
TABLE_ENDERECOS_COL_ID_USUARIO=id_usuario
TABLE_ENDERECOS_COL_CEP=cep
TABLE_ENDERECOS_COL_LOGRADOURO=logradouro
TABLE_ENDERECOS_COL_NUMERO=numero
TABLE_ENDERECOS_COL_COMPLEMENTO=complemento
TABLE_ENDERECOS_COL_BAIRRO=bairro
TABLE_ENDERECOS_COL_CIDADE=cidade
TABLE_ENDERECOS_COL_ESTADO=estado
TABLE_ENDERECOS_COL_PRINCIPAL=is_principal

TABLE_CARRINHOS_NOME=carrinhos
TABLE_CARRINHOS_COL_ID=id_carrinho
TABLE_CARRINHOS_COL_ID_USUARIO=id_usuario
TABLE_CARRINHOS_COL_ID_PRODUTO=id_produto
TABLE_CARRINHOS_COL_QUANTIDADE=quantidade

TABLE_PEDIDOS_NOME=pedidos
TABLE_PEDIDOS_COL_ID=id_pedido
TABLE_PEDIDOS_COL_ID_USUARIO=id_usuario
TABLE_PEDIDOS_COL_ID_ENDERECO=id_endereco_entrega
TABLE_PEDIDOS_COL_METODO_PAGAMENTO=metodo_pagamento
TABLE_PEDIDOS_COL_PRECO_ITENS=preco_itens
TABLE_PEDIDOS_COL_PRECO_FRETE=preco_frete
TABLE_PEDIDOS_COL_PRECO_TOTAL=preco_total
TABLE_PEDIDOS_COL_STATUS_PAGAMENTO=status_pagamento
TABLE_PEDIDOS_COL_STATUS_ENTREGA=status_entrega
TABLE_PEDIDOS_COL_ID_GATEWAY=id_pagamento_gateway
TABLE_PEDIDOS_COL_PIX_URL=pix_qrcode_url
TABLE_PEDIDOS_COL_PIX_COPIA_COLA=pix_copia_cola
TABLE_PEDIDOS_COL_DATA=data_pedido

TABLE_PEDIDO_ITEMS_NOME=pedido_items
TABLE_PEDIDO_ITEMS_COL_ID=id_item
TABLE_PEDIDO_ITEMS_COL_ID_PEDIDO=id_pedido
TABLE_PEDIDO_ITEMS_COL_ID_PRODUTO=id_produto
TABLE_PEDIDO_ITEMS_COL_NOME=nome
TABLE_PEDIDO_ITEMS_COL_QUANTIDADE=quantidade
TABLE_PEDIDO_ITEMS_COL_PRECO=preco
TABLE_PEDIDO_ITEMS_COL_IMAGEM_URL=imagem_url

TABLE_PAGAMENTO_NOME=formas_pagamento
TABLE_PAGAMENTO_COL_ID=id_pagamento
TABLE_PAGAMENTO_COL_ID_USUARIO=id_usuario
TABLE_PAGAMENTO_COL_GATEWAY=gateway
TABLE_PAGAMENTO_COL_TOKEN=token_cartao
TABLE_PAGAMENTO_COL_ULTIMOS_4=ultimos_4_digitos
TABLE_PAGAMENTO_COL_BANDEIRA=bandeira
TABLE_PAGAMENTO_COL_MES_EXP=mes_expiracao
TABLE_PAGAMENTO_COL_ANO_EXP=ano_expiracao
TABLE_PAGAMENTO_COL_PRINCIPAL=is_principal

# INTEGRAÇÕES
MERCADOPAGO_API_URL=https://api.mercadopago.com
MERCADO_LIVRE_ACCESS_TOKEN=L8x5E9FSiRKcG0n7rOYy85KAQTbLeXvi
GOOGLE_API_KEY=AIzaSyDparsThXqzpy3gj2ULjMXZaD1W2RGyEEA
EOF

# Ajusta Rede Backend
cat <<EOF >> backend/docker-compose.yml

networks:
  default:
    name: ${NETWORK_NAME}
    external: true
EOF


# --- GERAR ENV FRONTEND ---
echo -e "${YELLOW}Gerando env Frontend...${NC}"
cat <<EOF > frontend/.env
REACT_APP_API_URL=${API_URL}
REACT_APP_ENCRYPTION_KEY=${ENCRYPTION_KEY}
REACT_APP_ENCRYPTION_IV=${ENCRYPTION_IV}
EOF

# Ajusta Rede Frontend
cat <<EOF >> frontend/docker-compose.yml

networks:
  default:
    name: ${NETWORK_NAME}
    external: true
EOF


# --- GERAR ENV ADMIN ---
echo -e "${YELLOW}Gerando env Admin...${NC}"
cat <<EOF > admin/.env
REACT_APP_API_URL=${API_URL}
REACT_APP_ECOMMERCE_URL=${FRONT_URL}
JWT_SECRET=${JWT_SECRET}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
ENCRYPTION_IV=${ENCRYPTION_IV}
REACT_APP_ENCRYPTION_KEY=${ENCRYPTION_KEY}
REACT_APP_ENCRYPTION_IV=${ENCRYPTION_IV}
PORT=3001
EOF

# Ajusta Rede Admin
cat <<EOF >> admin/docker-compose.yml

networks:
  default:
    name: ${NETWORK_NAME}
    external: true
EOF

# 7. Build e Start
echo -e "${YELLOW}>>> Construindo e iniciando serviços...${NC}"

# Backend
cd $BASE_DIR/backend
echo "Iniciando Backend..."
docker compose build
docker compose up -d
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

# 8. Cloudflare Zero Trust
echo -e "${GREEN}>>> CLOUDFLARE ZERO TRUST SETUP <<<${NC}"
read -p "Deseja instalar e conectar o Cloudflare Tunnel? (s/n): " CF_OPT

if [ "$CF_OPT" == "s" ]; then
    echo "Baixando cloudflared..."
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i cloudflared.deb
    rm cloudflared.deb

    echo -e "${YELLOW}Crie o túnel no painel Zero Trust e copie o Token.${NC}"
    read -p "Cole seu Token do Cloudflare: " CF_TOKEN
    
    if [ ! -z "$CF_TOKEN" ]; then
        cloudflared service uninstall 2>/dev/null
        cloudflared service install "$CF_TOKEN"
        echo "Túnel ativo!"
    fi
fi

echo -e "${GREEN}>>> INSTALAÇÃO COMPLETA! <<<${NC}"
echo "Configure seus Public Hostnames no Cloudflare para:"
echo "Frontend -> localhost:3000"
echo "Backend  -> localhost:5000"
echo "Admin    -> localhost:3001"