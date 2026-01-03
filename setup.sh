#!/bin/bash

# Cores
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verifica se é root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Por favor, execute como root (sudo).${NC}"
  exit
fi

# Garante permissão de execução em todos os scripts .sh na pasta
chmod +x install.sh update.sh backup.sh uninstall.sh 2>/dev/null

show_menu() {
    clear
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}    GERENCIADOR DO SISTEMA RAYAN NOVIK      ${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo -e "${GREEN}1.${NC} Instalar Sistema (Primeira vez)"
    echo -e "${GREEN}2.${NC} Atualizar Sistema (Git Pull + Rebuild)"
    echo -e "${GREEN}3.${NC} Fazer Backup (Database + Arquivos)"
    echo -e "${RED}4.${NC} Desinstalar Tudo"
    echo -e "${YELLOW}0.${NC} Sair"
    echo -e "${CYAN}============================================${NC}"
    echo -n "Escolha uma opção: "
}

while true; do
    show_menu
    read option

    case $option in
        1)
            if [ -f "./install.sh" ]; then
                ./install.sh
            else
                echo -e "${RED}Erro: install.sh não encontrado!${NC}"
            fi
            ;;
        2)
            if [ -f "./update.sh" ]; then
                ./update.sh
            else
                echo -e "${RED}Erro: update.sh não encontrado!${NC}"
            fi
            ;;
        3)
            if [ -f "./backup.sh" ]; then
                ./backup.sh
            else
                echo -e "${RED}Erro: backup.sh não encontrado!${NC}"
            fi
            ;;
        4)
            if [ -f "./uninstall.sh" ]; then
                ./uninstall.sh
            else
                echo -e "${RED}Erro: uninstall.sh não encontrado!${NC}"
            fi
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac

    echo ""
    read -p "Pressione [Enter] para voltar ao menu..."
done