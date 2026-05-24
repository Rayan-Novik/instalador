#!/bin/bash

# ==============================================================================
# SCRIPT DE UPDATE - ARARINHACLOUD
# ==============================================================================

set -e

echo "========================================"
echo "🚀 INICIANDO UPDATE DO SISTEMA"
echo "========================================"

WWW_DIR="/var/www"

# ==============================================================================
# FRONTEND
# ==============================================================================

echo ""
echo "📦 Atualizando FRONTEND..."

cd $WWW_DIR/frontend

git reset --hard
git clean -fd
git pull origin main

# ==============================================================================
# ADMIN
# ==============================================================================

echo ""
echo "📦 Atualizando ADMIN..."

cd $WWW_DIR/admin

git reset --hard
git clean -fd
git pull origin main

# ==============================================================================
# BACKEND
# ==============================================================================

echo ""
echo "📦 Atualizando BACKEND..."

cd $WWW_DIR/backend

git reset --hard
git clean -fd
git pull origin main

# ==============================================================================
# DOCKER CLEANUP
# ==============================================================================

echo ""
echo "🧹 Limpando containers antigos..."

cd $WWW_DIR/backend
docker compose down

cd $WWW_DIR
docker compose down

echo ""
echo "🧹 Limpando imagens antigas..."
docker system prune -af

# ==============================================================================
# BUILD BACKEND
# ==============================================================================

echo ""
echo "🐳 Buildando BACKEND..."

cd $WWW_DIR/backend

docker compose up -d --build

# ==============================================================================
# PRISMA
# ==============================================================================

echo ""
echo "🗄️ Atualizando Prisma..."

docker exec ararinha_backend npx prisma generate
docker exec ararinha_backend npx prisma migrate deploy

# ==============================================================================
# BUILD FRONTEND + ADMIN
# ==============================================================================

echo ""
echo "🐳 Buildando FRONTEND + ADMIN..."

cd $WWW_DIR

docker compose up -d --build

# ==============================================================================
# FINALIZAÇÃO
# ==============================================================================

echo ""
echo "========================================"
echo "✅ UPDATE FINALIZADO COM SUCESSO"
echo "========================================"

echo ""
docker ps