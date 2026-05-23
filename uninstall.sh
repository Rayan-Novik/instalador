#!/bin/bash

# ==============================================================================
# DESINSTALADOR DO ARARINHA SAAS (VERSÃO DOCKER/MICROSSERVIÇOS)
# ==============================================================================

clear
echo "================================================================="
echo " 🚨 ATENÇÃO: ZONA DE PERIGO 🚨 "
echo "================================================================="
echo "Você está prestes a DESINSTALAR o Ararinha SaaS."
echo "Isso vai parar todos os contêineres, deletar o banco de dados MySQL,"
echo "apagar os códigos-fonte e limpar as configurações do Nginx."
echo "Essa ação NÃO tem volta e todos os dados dos clientes serão perdidos!"
echo "================================================================="
echo ""
read -p "Você tem CERTEZA ABSOLUTA? Digite 'SIM' para destruir o sistema: " confirmacao

if [ "$confirmacao" != "SIM" ]; then
    echo ""
    echo "✅ Desinstalação cancelada. Ufa! Seus dados e clientes estão a salvo."
    exit 0
fi

echo ""
echo "🗑️ Iniciando a limpeza total do servidor (Protocolo de Destruição)..."
sleep 2

# ==============================================================================
# 1. PARAR E REMOVER TODOS OS CONTÊINERES DOCKER E BANCO DE DADOS
# ==============================================================================
echo "🐳 1/4 - Removendo Ecossistema Docker e Banco de Dados..."
if [ -f "/var/www/docker-compose.yml" ]; then
    cd /var/www
    # Para e remove contêineres, redes e volumes criados pelo compose
    docker compose down -v 2>/dev/null
fi

# Garantia extra de aniquilação caso o comando acima falhe
docker rm -f ararinha_frontend ararinha_admin ararinha_backend ararinha_phpmyadmin ararinha_mysql 2>/dev/null
docker volume rm www_mysql_data backend_mysql_data 2>/dev/null

# ==============================================================================
# 2. LIMPEZA DE SISTEMAS ANTIGOS (PM2)
# ==============================================================================
echo "🚀 2/4 - Verificando e derrubando processos antigos (PM2)..."
pm2 delete ararinha-backend 2>/dev/null
pm2 save --force 2>/dev/null

# ==============================================================================
# 3. LIMPAR NGINX (ROTAS E SITEMAP)
# ==============================================================================
echo "🌐 3/4 - Removendo pontes e rotas do Nginx..."
rm -f /etc/nginx/sites-enabled/backend /etc/nginx/sites-enabled/admin /etc/nginx/sites-enabled/frontend
rm -f /etc/nginx/sites-available/backend /etc/nginx/sites-available/admin /etc/nginx/sites-available/frontend

# Testa se a remoção não quebrou a sintaxe principal antes de recarregar
nginx -t 2>/dev/null && systemctl reload nginx

# ==============================================================================
# 4. APAGAR ARQUIVOS FONTE E DIRETÓRIOS
# ==============================================================================
echo "📂 4/4 - Queimando os arquivos de código-fonte..."
rm -rf /var/www/backend /var/www/admin /var/www/frontend /var/www/docker-compose.yml

echo "================================================================="
echo "💀 DESINSTALAÇÃO CONCLUÍDA. O SERVIDOR ESTÁ 100% LIMPO."
echo "================================================================="