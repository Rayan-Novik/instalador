#!/bin/bash

echo "========================================================"
echo "🔄 REINICIANDO O ARARINHA SAAS..."
echo "========================================================"

# 1. Reiniciar o Banco de Dados (MySQL no Docker)
echo "🗄️ Reiniciando o MySQL..."
cd /var/www/backend
docker-compose restart

# 2. Reiniciar o Backend (PM2)
echo "🚀 Reiniciando a API (Node.js)..."
pm2 restart all

# 3. Reiniciar o Servidor Web (Nginx)
echo "🌐 Reiniciando o Nginx..."
systemctl restart nginx

echo "========================================================"
echo "✅ SISTEMA REINICIADO COM SUCESSO!"
echo "========================================================"
