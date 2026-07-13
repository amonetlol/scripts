#!/bin/bash

# =============================================
# Install Catppuccin GTK Theme (Frappe Dark + Libadwaita)
# =============================================

set -e  # Para o script se algum comando falhar

echo "🚀 Iniciando instalação do tema Catppuccin GTK..."

# 1. Clonar o repositório
echo "📥 Clonando o repositório..."
git clone https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme.git --depth 1
cd Catppuccin-GTK-Theme || { echo "❌ Falha ao entrar no diretório"; exit 1; }

# 2. Criar pasta de configuração GTK-4.0
echo "📁 Criando diretório de configuração GTK..."
mkdir -p ~/.config/gtk-4.0

# 3. Entrar na pasta themes e instalar
echo "🎨 Instalando tema (Frappe Dark + Libadwaita)..."
cd themes || { echo "❌ Pasta 'themes' não encontrada"; exit 1; }

./install.sh --libadwaita --tweaks frappe --mode dark

echo "✅ Instalação concluída com sucesso!"
echo ""
echo "🔄 Reinicie sua sessão (logout/login) ou reinicie o computador para aplicar o tema."