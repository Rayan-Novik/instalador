# Instalador Automático do Sistema Rayan Novik

Este repositório contém scripts de automação para deploy, atualização e backup do ecossistema de aplicações (Frontend, Backend, Admin).

## O que este instalador faz?
- Instala Docker, Docker Compose e Git.
- Cria a estrutura de diretórios em `/www`.
- Configura MySQL e PhpMyAdmin automaticamente.
- Baixa os repositórios (Admin, Frontend, Backend).
- Cria redes Docker compartilhadas.
- Configura variáveis de ambiente (.env) de forma interativa.

## Requisitos
- Servidor Ubuntu 20.04/22.04 ou Debian 11/12.
- Acesso Root.

## 🚀 Instalação Rápida

Rode o comando abaixo no seu servidor:

```bash
git clone [https://github.com/SEU-USUARIO/NOME-DO-REPO.git](https://github.com/SEU-USUARIO/NOME-DO-REPO.git) instalador
cd instalador
chmod +x *.sh
sudo ./install.sh