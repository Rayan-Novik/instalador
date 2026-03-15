#!/bin/bash

# ==============================================================================
# DESINSTALADOR DO ARARINHA SAAS
# ==============================================================================

clear
echo "================================================================="
echo " 🚨 ATENÇÃO: ZONA DE PERIGO 🚨 "
echo "================================================================="
echo "Você está prestes a DESINSTALAR o Ararinha SaaS."
echo "Isso vai apagar TODOS os arquivos, deletar o banco de dados MySQL"
echo "e remover as configurações do Nginx. Essa ação NÃO tem volta!"
echo "================================================================="
echo ""
read -p "Você tem CERTEZA ABSOLUTA? Digite 'SIM' para destruir o sistema: " confirmacao

if [ "$confirmacao" != "SIM" ]; then
    echo ""
    echo "✅ Desinstalação cancelada. Ufa! Seus dados estão a salvo."
    exit 0
fi

echo ""
echo "🗑️ Iniciando a limpeza total do servidor..."
sleep 2

# 1. Parar e remover Docker (MySQL)
echo "🐳 1/4 - Removendo Banco de Dados e containers Docker..."
if [ -d "/var/www/backend" ]; then
    cd /var/www/backend
    docker-compose down -v 2>/dev/null
fi
# Garantia extra caso o docker-compose falhe
docker rm -f ararinha_mysql 2>/dev/null

# 2. Parar PM2
echo "🚀 2/4 - Removendo API do PM2..."
pm2 delete ararinha-backend 2>/dev/null
pm2 save 2>/dev/null

# 3. Limpar Nginx
echo "🌐 3/4 - Removendo rotas do Nginx..."
rm -f /etc/nginx/sites-enabled/backend /etc/nginx/sites-enabled/admin /etc/nginx/sites-enabled/frontend
rm -f /etc/nginx/sites-available/backend /etc/nginx/sites-available/admin /etc/nginx/sites-available/frontend
systemctl restart nginx

# 4. Apagar Arquivos
echo "📂 4/4 - Apagando códigos-fonte..."
rm -rf /var/www/backend /var/www/admin /var/www/frontend

echo "================================================================="
echo "💀 DESINSTALAÇÃO CONCLUÍDA. O SERVIDOR ESTÁ LIMPO."
echo "================================================================="
