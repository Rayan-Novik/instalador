#!/bin/bash

BASE_DIR="/www"
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}!!! ATENÇÃO !!!${NC}"
echo "Isso irá parar todos os serviços e APAGAR a pasta /www e todos os dados."
read -p "Tem certeza absoluta? (digite 'sim' para confirmar): " CONFIRM

if [ "$CONFIRM" != "sim" ]; then
    echo "Cancelado."
    exit
fi

echo "Parando containers..."
cd $BASE_DIR/backend && docker compose down
cd $BASE_DIR/frontend && docker compose down
cd $BASE_DIR/admin && docker compose down
cd $BASE_DIR && docker compose down # Para o MySQL

echo "Removendo rede..."
docker network rm app_network

echo "Removendo arquivos..."
cd /
rm -rf $BASE_DIR

echo "Desinstalação completa."