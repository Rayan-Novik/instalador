#!/bin/bash

set -e

echo "========================================"
echo "🚀 ATUALIZANDO SISTEMA"
echo "========================================"

WWW_DIR="/var/www"

# ==============================================================================
# GIT UPDATE
# ==============================================================================

for repo in frontend admin backend; do

    echo ""
    echo "📦 Atualizando $repo..."

    cd $WWW_DIR/$repo

    git fetch origin
    git reset --hard origin/main
    git clean -fd

done

# ==============================================================================
# PARAR TUDO
# ==============================================================================

echo ""
echo "🛑 Parando containers WEB..."

cd $WWW_DIR

docker compose down --remove-orphans || true

echo ""
echo "🛑 Parando containers BACKEND..."

cd $WWW_DIR/backend

docker compose down --remove-orphans || true

# ==============================================================================
# LIMPEZA TOTAL
# ==============================================================================

echo ""
echo "🧹 Limpando Docker..."

docker rm -f $(docker ps -aq) 2>/dev/null || true

docker system prune -af --volumes

docker builder prune -af

# ==============================================================================
# BUILD BACKEND
# ==============================================================================

echo ""
echo "🐳 Buildando BACKEND..."

cd $WWW_DIR/backend

docker compose build --no-cache
docker compose up -d --force-recreate

# ==============================================================================
# AGUARDAR BACKEND
# ==============================================================================

echo ""
echo "⏳ Aguardando backend iniciar..."

sleep 20

# ==============================================================================
# PRISMA
# ==============================================================================

echo ""
echo "🗄️ Executando Prisma..."

docker exec ararinha_backend npx prisma generate
docker exec ararinha_backend npx prisma migrate deploy

# ==============================================================================
# BUILD WEB
# ==============================================================================

echo ""
echo "🐳 Buildando FRONTEND + ADMIN + PROXY..."

cd $WWW_DIR

docker compose build --no-cache

docker compose up -d --force-recreate

# ==============================================================================
# STATUS FINAL
# ==============================================================================

echo ""
echo "========================================"
echo "✅ UPDATE FINALIZADO"
echo "========================================"

echo ""

docker ps