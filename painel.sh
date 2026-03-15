#!/bin/bash

# Função para pausar e voltar ao menu
pause() {
    echo ""
    read -p "Pressione [ENTER] para voltar ao menu principal..."
}

# Loop infinito do menu
while true; do
    clear
    echo "================================================================="
    echo " 🦜 PAINEL DE CONTROLE GERENCIAL - ARARINHA SAAS "
    echo "================================================================="
    echo " Bem-vindo! O que você deseja fazer no servidor hoje?"
    echo ""
    echo "  [1] 🚀 Instalar Sistema (Ambiente Zero)"
    echo "  [2] 🔄 Atualizar Sistema (Puxar versão nova do GitHub)"
    echo "  [3] ⚡ Reiniciar Sistema (MySQL, PM2, Nginx)"
    echo "  [4] 🗑️  Desinstalar Sistema (Zerar Servidor)"
    echo "  [0] ❌ Sair do Painel"
    echo ""
    echo "================================================================="
    read -p "👉 Digite o número da opção: " opcao

    case $opcao in
        1)
            echo ""
            echo "Iniciando o Instalador Automático..."
            sleep 1
            if [ -f "./install.sh" ]; then
                sudo ./install.sh
            else
                echo "⚠️ Arquivo install.sh não encontrado nesta pasta!"
            fi
            pause
            ;;
        2)
            echo ""
            echo "Iniciando a Atualização..."
            sleep 1
            if [ -f "./update.sh" ]; then
                sudo ./update.sh
            else
                echo "⚠️ Arquivo update.sh não encontrado nesta pasta!"
            fi
            pause
            ;;
        3)
            echo ""
            echo "Iniciando o Reinício dos Serviços..."
            sleep 1
            if [ -f "./restart.sh" ]; then
                sudo ./restart.sh
            else
                echo "⚠️ Arquivo restart.sh não encontrado nesta pasta!"
            fi
            pause
            ;;
        4)
            echo ""
            if [ -f "./uninstall.sh" ]; then
                sudo ./uninstall.sh
            else
                echo "⚠️ Arquivo uninstall.sh não encontrado nesta pasta!"
            fi
            pause
            ;;
        0)
            echo ""
            echo "Saindo... Bom trabalho!"
            sleep 1
            clear
            exit 0
            ;;
        *)
            echo ""
            echo "❌ Opção inválida! Digite 1, 2, 3, 4 ou 0."
            sleep 2
            ;;
    esac
done
