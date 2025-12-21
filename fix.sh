#!/usr/bin/env bash
# install-minimal.sh — instalação apenas de fonts, walls, nvim (AstroNvim) e hidden applications
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Iniciando instalação mínima (fonts, walls, nvim, hidden apps)...${NC}"

# Função auxiliar para criar symlinks com backup
link() {
    local src="$1"
    local dest="$2"
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$src" ]]; then
        echo -e "${GREEN}OK${NC} $dest → $(basename "$src")"
        return
    fi
    if [[ -e "$dest" || -L "$dest" ]]; then
        echo -e "${YELLOW}Backup${NC} $dest → $dest.bak.$(date +%Y%m%d_%H%M%S)"
        mv "$dest" "$dest.bak.$(date +%Y%m%d_%H%M%S)"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    echo -e "${GREEN}Link${NC} $dest → $src"
}

# 7. Instalando fonts (amonetlol/fonts)
echo -e "${GREEN}Instalando fonts do amonetlol/fonts...${NC}"
if [[ -d "$HOME/.fonts" && -d "$HOME/.fonts/.git" ]]; then
    echo -e "${YELLOW}~/.fonts já existe (repositório git). Atualizando...${NC}"
    git -C "$HOME/.fonts" pull
else
    if [[ -d "$HOME/.fonts" ]]; then
        echo -e "${YELLOW}Backup${NC} ~/.fonts → ~/.fonts.bak.$(date +%Y%m%d_%H%M%S)"
        mv "$HOME/.fonts" "$HOME/.fonts.bak.$(date +%Y%m%d_%H%M%S)"
    fi
    echo -e "${GREEN}Clonando${NC} https://github.com/amonetlol/fonts em ~/.fonts"
    git clone https://github.com/amonetlol/fonts "$HOME/.fonts"
fi

echo -e "${GREEN}Atualizando cache de fontes...${NC}"
fc-cache -vf

# 8. Walls → ~/walls
echo -e "${GREEN}Configurando wallpapers...${NC}"
if [[ -d "$HOME/.config/qtile/walls" ]]; then
    link "$HOME/.config/qtile/walls" "$HOME/walls"
else
    echo -e "${YELLOW}Aviso:${NC} Diretório ~/.config/qtile/walls não encontrado. Pulando link para ~/walls."
fi

# 9. Instalando AstroNvim
echo -e "${GREEN}Instalando AstroNvim...${NC}"
if [[ -d "$HOME/.config/nvim" ]]; then
    echo -e "${YELLOW}Backup${NC} ~/.config/nvim → ~/.config/nvim.bak.$(date +%Y%m%d_%H%M%S)"
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%Y%m%d_%H%M%S)"
fi

git clone --depth 1 https://github.com/AstroNvim/template "$HOME/.config/nvim"
rm -rf "$HOME/.config/nvim/.git"

echo -e "${GREEN}AstroNvim instalado.${NC}"
echo -e "${YELLOW}Dica:${NC} Execute 'nvim' para finalizar a instalação (baixar plugins, etc.)"

# 10. Hidden Applications → ~/.local/share/applications
echo -e "${GREEN}Configurando aplicações ocultas...${NC}"
if [[ -d "$DOTFILES_DIR/local/share/applications" ]]; then
    link "$DOTFILES_DIR/local/share/applications" "$HOME/.local/share/applications"
else
    echo -e "${YELLOW}Aviso:${NC} Diretório local/share/applications não encontrado no dotfiles. Pulando."
fi

echo -e "${GREEN}"
echo "Instalação mínima concluída!"
echo "Para aplicar as mudanças completamente:"
echo "  • Rode 'nvim' para terminar a configuração do AstroNvim"
echo "  • Atualize o cache de ícones se necessário: gtk-update-icon-cache"
echo -e "${NC}"
