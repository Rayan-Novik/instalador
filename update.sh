#!/bin/bash

BASE_DIR="/www"
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}>>> Atualizando Sistema...${NC}"

update_service() {
    SERVICE_DIR=$1
    echo "Atualizando $SERVICE_DIR..."
    cd "$BASE_DIR/$SERVICE_DIR" || exit
    git pull
    docker compose down
    docker compose build --no-cache
    docker compose up -d
}

# Atualizar Backend
update_service "backend"

# Atualizar Frontend
update_service "frontend"

# Atualizar Admin
update_service "admin"

# Limpar imagens antigas para economizar espaço
docker image prune -f

echo -e "${GREEN}>>> Sistema atualizado com sucesso!${NC}"