#!/bin/bash
# ==============================================================================
# Script de Instalação Automatizada - ArarinhaCloud
# ==============================================================================

set -e # Para o script se algum comando falhar

echo "========================================"
echo "🚀 Iniciando a instalação do sistema..."
echo "========================================"

# 1. Atualizar sistema e instalar dependências básicas
echo "📦 Instalando dependências (Git, Curl)..."
apt-get update -y
apt-get install -y git curl sudo

# 2. Instalar Docker e Docker Compose (se não estiver instalado)
if ! command -v docker &> /dev/null; then
    echo "🐳 Instalando o Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
else
    echo "✅ Docker já está instalado."
fi

# 3. Criar estrutura de diretórios
echo "📂 Criando a estrutura de pastas em /var/www..."
mkdir -p /var/www/proxy

cd /var/www

# 4. Clonar os repositórios (Se a pasta já existir, apaga e clona de novo)
echo "📥 Clonando os repositórios do GitHub..."

for repo in admin frontend backend; do
    if [ -d "$repo" ]; then
        echo "⚠️ Pasta $repo já existe. Removendo para baixar a versão mais recente..."
        rm -rf "$repo"
    fi
    git clone https://github.com/Rayan-Novik/$repo
done

# ==============================================================================
# INJETAR ARQUIVOS DE CONFIGURAÇÃO
# Nota: Usamos 'EOF' com aspas simples para impedir que o bash expanda variáveis como $host
# ==============================================================================

echo "⚙️ Configurando arquivos do Proxy Principal..."
cat << 'EOF' > /var/www/proxy/nginx.conf
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    # =========================
    # ADMIN
    # =========================
    server {
        listen 80;
        server_name admin.ararinhacloud.shop;

        location / {
            proxy_pass http://admin-app:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }

    # =========================
    # ROOT DOMAIN
    # =========================
    server {
        listen 80;
        server_name ararinhacloud.shop;

        location / {
            proxy_pass http://frontend-app:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }

    # =========================
    # TENANTS
    # =========================
    server {
        listen 80;
        server_name ~^(?!admin\.)(?<subdomain>.+)\.ararinhacloud\.shop$;

        location / {
            error_page 418 = @bot;

            if ($http_user_agent ~* "whatsapp|facebookexternalhit|twitterbot|linkedinbot|telegrambot|discordbot|bot|crawler|spider|scraper|preview") {
                return 418;
            }

            proxy_pass http://frontend-app:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location @bot {
            rewrite ^ /api/public/render-og break;
            proxy_pass http://host.docker.internal:5000;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
EOF

echo "⚙️ Configurando arquivos do Admin..."
cat << 'EOF' > /var/www/admin/Dockerfile
# ETAPA 1: Build do React usando o Node
FROM node:18 AS build

WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .
RUN npm run build 

# ETAPA 2: Servidor Nginx para rodar a aplicação
FROM nginx:alpine
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cat << 'EOF' > /var/www/admin/nginx.conf
server {
    listen 80;
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }
}
EOF

echo "⚙️ Configurando arquivos do Frontend..."
cat << 'EOF' > /var/www/frontend/Dockerfile
FROM node:22-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# --------- NGINX ---------
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cat << 'EOF' > /var/www/frontend/nginx.conf
server {
    listen 80;
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }
}
EOF

echo "⚙️ Configurando docker-compose principal (Frontend, Admin e Proxy)..."
cat << 'EOF' > /var/www/docker-compose.yml
version: '3.8'

services:
  proxy:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./proxy/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - admin-app
      - frontend-app

  admin-app:
    build: 
      context: ./admin
    expose:
      - "80"

  frontend-app:
    build: 
      context: ./frontend
    expose:
      - "80"
EOF

echo "⚙️ Configurando docker-compose do Backend..."
cat << 'EOF' > /var/www/backend/docker-compose.yml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: ararinha_mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: Gd1700al@@
      MYSQL_DATABASE: ecommerce_db
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: ararinha_phpmyadmin
    restart: always
    ports:
      - "8080:80"
    environment:
      PMA_HOST: mysql
      PMA_USER: root
      PMA_PASSWORD: Gd1700al@@
    depends_on:
      - mysql

  backend:
    build: .
    container_name: ararinha_backend
    restart: always
    ports:
      - "5000:5000"
    depends_on:
      - mysql
    env_file:
      - .env

volumes:
  mysql_data:
EOF

# Garante que um arquivo .env vazio exista para o docker não reclamar
touch /var/www/backend/.env

# ==============================================================================
# CLOUDFLARED INSTALLATION
# ==============================================================================

echo "☁️ Instalando o Cloudflared Tunnel..."

sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | sudo tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null

echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list

sudo apt-get update
sudo apt-get install cloudflared -y

echo ""
echo "==================================================================="
echo "🔑 POR FAVOR, INSIRA SEU TOKEN DO CLOUDFLARE TUNNEL:"
echo "(Cole o código que começa com eyJ... e aperte ENTER)"
echo "==================================================================="
read CF_TOKEN

if [ -n "$CF_TOKEN" ]; then
    echo "⏳ Configurando o serviço do Cloudflared..."
    sudo cloudflared service install $CF_TOKEN || echo "⚠️ Aviso: O cloudflared pode já estar instalado ou o token é inválido."
else
    echo "❌ Nenhum token fornecido. O Cloudflared não foi configurado."
fi

# ==============================================================================
# SUBINDO OS CONTAINERS
# ==============================================================================

echo "🐳 Subindo o ambiente de Backend (MySQL, PHPMyAdmin, API)..."
cd /var/www/backend
docker compose up -d --build

echo "🐳 Subindo o ambiente Web (Admin, Frontend, Nginx Proxy)..."
cd /var/www
docker compose up -d --build

echo ""
echo "==================================================================="
echo "✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "==================================================================="
echo "-> Verifique se os containers do backend estão rodando: 'cd /var/www/backend && docker compose ps'"
echo "-> Verifique se os containers web estão rodando: 'cd /var/www && docker compose ps'"
echo "⚠️ Lembre-se de configurar o arquivo /var/www/backend/.env com as variáveis do backend."