#!/bin/bash

# ==============================================================================
# ATUALIZADOR AUTOMATIZADO - ARARINHA SAAS
# ==============================================================================

echo "========================================================"
echo "🔄 INICIANDO ATUALIZAÇÃO DO SISTEMA..."
echo "========================================================"

BASE_DIR="/var/www"

# 1. ATUALIZANDO BACKEND
echo "⚙️ [1/4] Atualizando Backend..."
cd $BASE_DIR/backend
# Descarta qualquer mudança local acidental e puxa do Github
git reset --hard
git pull
# Instala pacotes novos, se houver
npm install
# Atualiza o Prisma (caso você tenha criado tabelas novas no schema)
npx prisma generate
npx prisma db push
# Reinicia a API para rodar o código novo
pm2 restart ararinha-backend

# 2. ATUALIZANDO ADMIN (PAINEL)
echo "💻 [2/4] Atualizando Painel Admin..."
cd $BASE_DIR/admin
git reset --hard
git pull
npm install
npm run build

# 3. ATUALIZANDO FRONTEND (LOJA)
echo "🛒 [3/4] Atualizando Frontend (Loja)..."
cd $BASE_DIR/frontend
git reset --hard
git pull
npm install
npm run build

# 4. REINICIANDO NGINX
echo "🌐 [4/4] Limpando cache e reiniciando Nginx..."
systemctl restart nginx

echo "========================================================"
echo "✨ ATUALIZAÇÃO CONCLUÍDA COM SUCESSO! ✨"
echo "========================================================"
echo "Dica: Lembre-se de limpar o cache do navegador (Ctrl + Shift + R) para ver as mudanças no Front-end!"

