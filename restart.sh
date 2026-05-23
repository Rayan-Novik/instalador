#!/bin/bash

# ==============================================================================
# REINICIADOR DO ARARINHA SAAS (VERSÃO DOCKER/MICROSSERVIÇOS)
# ==============================================================================

echo "========================================================"
echo "🔄 REINICIANDO O ARARINHA SAAS (ECOSSISTEMA DOCKER)..."
echo "========================================================"

# 1. Reiniciar todos os contêineres (Banco, API, Painel, Loja e phpMyAdmin)
echo "🐳 [1/2] Reiniciando todos os Microsserviços no Docker..."
cd /var/www
docker compose restart

# 2. Reiniciar o Servidor Web (Nginx Reverse Proxy)
echo "🌐 [2/2] Recarregando as rotas do Nginx..."
nginx -t 2>/dev/null && systemctl reload nginx

echo "========================================================"
echo "✅ SISTEMA REINICIADO COM SUCESSO!"
echo "========================================================"