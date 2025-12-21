#!/bin/bash

# Script para instalar Firefox .deb oficial da Mozilla no Ubuntu (24.04 ou superior)
# Evita o Snap e prioriza o repositório da Mozilla
# Data: Dezembro 2025 - Método oficial recomendado pela Mozilla

set -e  # Para o script se algum comando falhar

echo "Adicionando chave GPG do repositório Mozilla..."
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo gpg --dearmor -o /etc/apt/keyrings/packages.mozilla.org.gpg

echo "Adicionando repositório oficial da Mozilla..."
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.gpg] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null

echo "Dando prioridade alta ao repositório da Mozilla (para evitar Snap)..."
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1001
' | sudo tee /etc/apt/preferences.d/mozilla > /dev/null

echo "Atualizando lista de pacotes..."
sudo apt update

echo "Instalando Firefox .deb oficial..."
sudo apt install firefox -y

echo "Pronto! Firefox instalado como .deb nativo."
echo "Versão instalada:"
firefox --version

echo "Dica: Se quiser remover o Snap (caso já exista): sudo snap remove firefox"
