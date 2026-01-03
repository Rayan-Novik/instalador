#!/bin/bash

BASE_DIR="/www"
BACKUP_DIR="/root/backups" # Salva fora do /www
DATE=$(date +%Y-%m-%d_%H-%M-%S)
MYSQL_CONTAINER="mysql_server"

# Senha precisa ser pega do setup ou hardcoded aqui se for automatizado.
# Para segurança, tentamos ler do docker-compose ou pedimos.
# Neste exemplo, vamos assumir que o usuário configurou o ~/.my.cnf ou passaremos vazia
# O ideal é extrair a senha do docker-compose.yml principal
DB_PASS=$(grep MYSQL_ROOT_PASSWORD $BASE_DIR/docker-compose.yml | awk -F ': ' '{print $2}')

mkdir -p $BACKUP_DIR

echo ">>> Iniciando Backup do Banco de Dados..."
# Executa mysqldump de dentro do container
docker exec $MYSQL_CONTAINER /usr/bin/mysqldump -u root --password="$DB_PASS" --all-databases > "$BACKUP_DIR/db_backup_$DATE.sql"

echo ">>> Compactando arquivos do sistema..."
tar -czf "$BACKUP_DIR/system_backup_$DATE.tar.gz" -C / www

# Opcional: Remover SQL puro após compactar (se quiser incluir o sql dentro do tar, mude a ordem)
# Aqui mantemos separado por segurança.

echo "Backup concluído em: $BACKUP_DIR"