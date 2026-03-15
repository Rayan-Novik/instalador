#!/bin/bash

# ==============================================================================
# INSTALADOR AUTOMATIZADO - ARARINHA SAAS
# ==============================================================================

echo "========================================================"
echo "🚀 INICIANDO INSTALAÇÃO DO ARARINHA SAAS..."
echo "========================================================"

# 1. Coletando Domínios do Usuário
read -p "🌐 Digite o domínio do BACKEND (ex: back.ararinhacloud.shop): " DOMINIO_BACKEND
read -p "🌐 Digite o domínio do ADMIN (ex: admin.ararinhacloud.shop): " DOMINIO_ADMIN
read -p "🌐 Digite o domínio da LOJA FRONTEND (ex: www.ararinhacloud.shop): " DOMINIO_FRONTEND

# Verifica se o docker e docker-compose estão instalados
if ! command -v docker &> /dev/null; then
    echo "🐳 Instalando Docker..."
    apt update && apt install docker.io docker-compose -y
    systemctl start docker
    systemctl enable docker
fi

# Diretório base
BASE_DIR="/var/www"
mkdir -p $BASE_DIR
cd $BASE_DIR

# ==============================================================================
# 2. CLONANDO REPOSITÓRIOS
# ==============================================================================
echo "⬇️ Clonando repositórios do GitHub para $BASE_DIR..."
# Remove as pastas caso o script seja rodado mais de uma vez para evitar erro de clone
rm -rf backend admin frontend 

git clone https://github.com/Rayan-Novik/backend.git
git clone https://github.com/Rayan-Novik/admin.git
git clone https://github.com/Rayan-Novik/frontend.git

# ==============================================================================
# 3. DOCKER MYSQL (Configurado dentro da pasta backend)
# ==============================================================================
echo "🗄️ Configurando Banco de Dados MySQL via Docker..."
cd $BASE_DIR/backend

cat <<EOF > docker-compose.yml
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    container_name: ararinha_mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: ecommerce_db
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
volumes:
  mysql_data:
EOF

docker-compose up -d

echo "⏳ Aguardando o MySQL iniciar (15 segundos)..."
sleep 15

# ==============================================================================
# 4. CONFIGURANDO BACKEND
# ==============================================================================
echo "⚙️ Configurando Backend..."

cat <<EOF > .env
# --- CONFIGURAÇÕES DO SERVIDOR ---
SERVER_PORT=5000
FRONTEND_URL=https://$DOMINIO_FRONTEND
BACKEND_URL=https://$DOMINIO_BACKEND

# --- BANCO DE DADOS (PRISMA) ---
# O Prisma usa apenas esta linha para conectar. 
# As variaveis DB_HOST, DB_USER, etc, foram removidas pois estão embutidas aqui.
DATABASE_URL="mysql://root:root@127.0.0.1:3306/ecommerce_db"

# --- SEGURANÇA ---
JWT_SECRET=umasenhasupersecretadificildeadivinhar12345
ENCRYPTION_KEY=a1b2c3d4e5f6a7b8a1b2c3d4e5f6a7b8
ENCRYPTION_IV=a1b2c3d4e5f6a7b8

# --- INTEGRAÇÕES ---
MERCADOPAGO_API_URL=https://api.mercadopago.com
MERCADO_LIVRE_ACCESS_TOKEN=your_ml_api_key_here
GOOGLE_API_KEY=your_google_api_key_here
GROQ_API_KEY=gsk_your_groq_api_key_here
ABACATEPAY_API_KEY=your_abacatepay_api_key_here
EOF

npm install

# Prisma (Sincroniza Banco de Dados)
echo "🗃️ Sincronizando Schema Prisma..."
npx prisma generate
npx prisma db push

# Criando Script temporário para injetar o primeiro Tenant
cat <<EOF > seed_tenant.js
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const tenantExists = await prisma.tenants.findUnique({ where: { slug: 'admin' } });
  
  if (!tenantExists) {
    await prisma.tenants.create({
      data: {
        slug: 'admin',
        nome_fantasia: 'Ararinha Matriz',
        plano: 'PRO',
        status_assinatura: 'ATIVO',
        dominio_customizado: '$DOMINIO_FRONTEND'
      }
    });
    console.log('✅ Tenant inicial criado!');
  } else {
    console.log('⚠️ Tenant já existe.');
  }
}
main().catch(e => console.error(e)).finally(async () => await prisma.\$disconnect());
EOF

# Executa o seed e apaga o arquivo
node seed_tenant.js
rm seed_tenant.js

# PM2
echo "🚀 Iniciando Backend no PM2..."
pm2 start server.js --name "ararinha-backend"
pm2 save

# ==============================================================================
# 5. CONFIGURANDO ADMIN
# ==============================================================================
echo "⚙️ Configurando Admin (Painel)..."
cd $BASE_DIR/admin

cat <<EOF > .env
REACT_APP_API_URL=https://$DOMINIO_BACKEND/api
REACT_APP_ECOMMERCE_URL=https://$DOMINIO_FRONTEND

PORT=3001

JWT_SECRET=umasenhasupersecretadificildeadivinhar12345

ENCRYPTION_KEY=a1b2c3d4e5f6a7b8a1b2c3d4e5f6a7b8
ENCRYPTION_IV=a1b2c3d4e5f6a7b8

REACT_APP_ENCRYPTION_KEY=a1b2c3d4e5f6a7b8a1b2c3d4e5f6a7b8
REACT_APP_ENCRYPTION_IV=a1b2c3d4e5f6a7b8
EOF

npm install
npm run build

# ==============================================================================
# 6. CONFIGURANDO FRONTEND
# ==============================================================================
echo "⚙️ Configurando Frontend (Loja)..."
cd $BASE_DIR/frontend

cat <<EOF > .env
# ==========================================
# VARIÁVEIS DO FRONTEND (Vite)
# Tudo que começa com VITE_ fica visível no navegador
# ==========================================
VITE_API_URL=https://$DOMINIO_BACKEND/api
VITE_ECOMMERCE_URL=https://$DOMINIO_FRONTEND

VITE_ENCRYPTION_KEY=a1b2c3d4e5f6a7b8a1b2c3d4e5f6a7b8
VITE_ENCRYPTION_IV=a1b2c3d4e5f6a7b8

# ==========================================
# ⚠️ VARIÁVEIS DO BACKEND (Ignoradas pelo Vite)
# ==========================================
PORT=3001
JWT_SECRET=umasenhasupersecretadificildeadivinhar12345
ENCRYPTION_KEY=a1b2c3d4e5f6a7b8a1b2c3d4e5f6a7b8
ENCRYPTION_IV=a1b2c3d4e5f6a7b8
EOF

npm install
npm run build

# ==============================================================================
# 7. CONFIGURANDO NGINX
# ==============================================================================
echo "🌐 Configurando Nginx..."

# Nginx BACKEND
cat <<EOF > /etc/nginx/sites-available/backend
server {
    listen 80;
    server_name $DOMINIO_BACKEND;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Nginx ADMIN
cat <<EOF > /etc/nginx/sites-available/admin
server {
    listen 80;
    server_name $DOMINIO_ADMIN;
    root $BASE_DIR/admin/build; # CRA padrao
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

# Nginx FRONTEND
cat <<EOF > /etc/nginx/sites-available/frontend
server {
    listen 80;
    server_name $DOMINIO_FRONTEND;
    root $BASE_DIR/frontend/dist; # Vite padrao
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

# Ativando e reiniciando Nginx
ln -sf /etc/nginx/sites-available/backend /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/admin /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/frontend /etc/nginx/sites-enabled/

nginx -t && systemctl restart nginx

echo "========================================================"
echo "🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "========================================================"
echo "Pastas criadas em: /var/www/admin | /var/www/backend | /var/www/frontend"
echo "Back-end rodando na porta 5000 via PM2."
echo "Front-end e Admin preparados no Nginx."
echo "⚠️ Lembrete: Configure as rotas desses 3 domínios apontando para o seu localhost:80 no Cloudflare Zero Trust!"