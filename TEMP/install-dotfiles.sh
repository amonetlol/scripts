#!/bin/bash
# Script de instalação dos dotfiles com GNU Stow (versão robusta)
# Sempre força o destino para o home do usuário ($HOME)
# Pode ser rodado de qualquer lugar, desde que as pastas existam no pwd
set -e
echo "Instalando dotfiles com GNU Stow..."
echo "Diretório atual (repo): $(pwd)"
echo "Destino dos symlinks: $HOME"
echo ""

# Lista de pacotes (ajuste se mudou nomes)
PACKAGES=(
    alacritty
    cava
    dunst
    fastfetch
    kitty
    neofetch
    picom
    qtile
    rofi          # se ainda tiver config em .config/rofi (config.rasi etc.)
    starship
    bash          # .bashrc e .aliases
    bin-package   # ~/.bin
    rofi-package  # ~/.local/share/rofi/{scripts,themes}
)

# Verifica se stow está instalado
if ! command -v stow &> /dev/null; then
    echo "Erro: GNU Stow não instalado."
    echo "Instale com: sudo apt install stow"
    exit 1
fi

# Instala cada pacote forçando destino $HOME
for package in "${PACKAGES[@]}"; do
    if [ -d "$package" ]; then
        echo "Instalando pacote: $package → $HOME/"
        stow --verbose --target="$HOME" "$package"
    else
        echo "Aviso: Pacote '$package' não encontrado neste diretório (pulando)."
    fi
done

echo ""
echo "Instalação concluída com sucesso!"
echo ""
echo "Próximos passos:"
echo " • source ~/.bashrc (para carregar aliases e PATH)"
echo " • Se usar Qtile: Mod + Shift + R para recarregar"
echo " • Ou faça logout/login para aplicar tudo"
echo ""
echo "Para desinstalar um pacote: stow -D --target=$HOME nome-do-pacote"
