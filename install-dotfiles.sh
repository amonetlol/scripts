#!/bin/bash

# Script de instalação dos dotfiles com GNU Stow
# Rode dentro do diretório do repositório (ex: ~/.dotfiles)
# Autor: Grok (dezembro 2025)

set -e  # Para o script se algo falhar

echo "Instalando dotfiles com GNU Stow..."
echo "Diretório atual: $(pwd)"
echo ""

# Lista de pacotes para instalar (adicione ou remova conforme seu repo)
PACKAGES=(
    alacritty
    cava
    dunst
    fastfetch
    kitty
    neofetch
    picom
    qtile
    rofi
    starship
    bash          # para .bashrc e .aliases
    bin-package   # para ~/.bin (mude o nome se alterou no script anterior)
)

# Verifica se stow está instalado
if ! command -v stow &> /dev/null; then
    echo "Erro: GNU Stow não encontrado."
    echo "Instale com: sudo apt install stow"
    exit 1
fi

# Instala cada pacote
for package in "${PACKAGES[@]}"; do
    if [ -d "$package" ]; then
        echo "Instalando $package..."
        stow -v "$package"
    else
        echo "Aviso: Pacote '$package' não encontrado (pulando)."
    fi
done

echo ""
echo "Instalação concluída!"
echo ""
echo "Dicas finais:"
echo "  - Se usar bash, recarregue: source ~/.bashrc"
echo "  - Se adicionou scripts em ~/.bin, verifique se está no PATH:"
echo "    Adicione no ~/.bashrc se necessário:"
echo "    echo 'export PATH=\"\$HOME/.bin:\$PATH\"' >> ~/.bashrc"
echo "  - Reinicie o Qtile (Mod + Shift + R) ou faça logout/login para aplicar tudo."
echo "  - Para remover tudo: rode 'stow -D <pacote>' ou crie um uninstall.sh"
