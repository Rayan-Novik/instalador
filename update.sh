#!/bin/bash

set -e

WWW_DIR="/var/www"

FRONTEND_REPO="https://github.com/Rayan-Novik/frontend.git"
ADMIN_REPO="https://github.com/Rayan-Novik/admin.git"
BACKEND_REPO="https://github.com/Rayan-Novik/backend.git"

update_project() {
    PROJECT_NAME=$1
    PROJECT_PATH=$2
    PROJECT_REPO=$3

    echo "==============================="
    echo "Atualizando $PROJECT_NAME"
    echo "==============================="

    if [ ! -d "$PROJECT_PATH/.git" ]; then
        git clone $PROJECT_REPO $PROJECT_PATH
    else
        cd $PROJECT_PATH

        cp .env /tmp/${PROJECT_NAME}.env 2>/dev/null || true

        git fetch origin
        git reset --hard origin/main
        git clean -fd

        cp /tmp/${PROJECT_NAME}.env .env 2>/dev/null || true
    fi
}

rebuild_frontend_admin() {
    echo "==============================="
    echo "Rebuild FRONTEND + ADMIN"
    echo "==============================="

    cd $WWW_DIR

    docker compose build frontend-app admin-app
    docker compose up -d frontend-app admin-app
}

rebuild_backend() {
    echo "==============================="
    echo "Rebuild BACKEND"
    echo "==============================="

    cd $WWW_DIR/backend

    docker compose build backend
    docker compose up -d backend
}

clear

echo "=================================="
echo "        INSTALADOR UPDATE"
echo "=================================="
echo ""
echo "1 - Atualizar TUDO"
echo "2 - Atualizar BACKEND"
echo "3 - Atualizar FRONTEND"
echo "4 - Atualizar ADMIN"
echo "5 - Atualizar FRONTEND + ADMIN"
echo "0 - Sair"
echo ""

read -p "Escolha uma opção: " opcao

case $opcao in

1)
    update_project "frontend" "$WWW_DIR/frontend" "$FRONTEND_REPO"
    update_project "admin" "$WWW_DIR/admin" "$ADMIN_REPO"
    update_project "backend" "$WWW_DIR/backend" "$BACKEND_REPO"

    rebuild_frontend_admin
    rebuild_backend
    ;;

2)
    update_project "backend" "$WWW_DIR/backend" "$BACKEND_REPO"
    rebuild_backend
    ;;

3)
    update_project "frontend" "$WWW_DIR/frontend" "$FRONTEND_REPO"

    cd $WWW_DIR

    docker compose build frontend-app
    docker compose up -d frontend-app
    ;;

4)
    update_project "admin" "$WWW_DIR/admin" "$ADMIN_REPO"

    cd $WWW_DIR

    docker compose build admin-app
    docker compose up -d admin-app
    ;;

5)
    update_project "frontend" "$WWW_DIR/frontend" "$FRONTEND_REPO"
    update_project "admin" "$WWW_DIR/admin" "$ADMIN_REPO"

    rebuild_frontend_admin
    ;;

0)
    echo "Saindo..."
    exit 0
    ;;

*)
    echo "Opção inválida"
    exit 1
    ;;

esac

echo ""
echo "==============================="
echo "Atualização concluída"
echo "==============================="