#!/usr/bin/env bash
# install-minimal.sh — Instalação mínima: fonts, wallpapers, AstroNvim e hidden apps

set -euo pipefail

# Diretório raiz dos dotfiles
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Função: echo com cor
info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[AVISO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }

# Função: backup de arquivo/diretório existente
backup() {
    local target="$1"
    if [[ -e "$target" || -L "$target" ]]; then
        local backup_path="${target}.bak.$(date +%Y%m%d_%H%M%S)"
        mv "$target" "$backup_path"
        warn "Backup criado: $target → $backup_path"
    fi
}

# Função: criar symlink com verificação e backup
link() {
    local src="$1"
    local dest="$2"

    # Se já existe e aponta corretamente → pular
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(realpath "$src")" ]]; then
        success "$dest → $(basename "$src") (já existe)"
        return
    fi

    backup "$dest"
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    success "$dest → $src"
}

info "Iniciando instalação mínima (fonts, AstroNvim, hidden apps)..."

# ====================
# 1. Fonts (amonetlol/fonts)
# ====================
info "Instalando/atualizando fonts do amonetlol/fonts..."

FONTS_DIR="$HOME/.fonts"
FONTS_REPO="https://github.com/amonetlol/fonts.git"

if [[ -d "$FONTS_DIR/.git" ]]; then
    info "Repositório de fonts já existe. Atualizando..."
    git -C "$FONTS_DIR" pull --rebase
else
    backup "$FONTS_DIR"
    info "Clonando repositório de fonts em $FONTS_DIR..."
    git clone --depth 1 "$FONTS_REPO" "$FONTS_DIR"
fi

info "Atualizando cache de fontes..."
fc-cache -vf >/dev/null
success "Fonts instaladas e cache atualizado."

# ====================
# 2. AstroNvim
# ====================
info "Instalando AstroNvim..."

NVIM_DIR="$HOME/.config/nvim"
ASTRO_TEMPLATE="https://github.com/AstroNvim/template.git"

backup "$NVIM_DIR"

info "Clonando template do AstroNvim..."
git clone --depth 1 "$ASTRO_TEMPLATE" "$NVIM_DIR"

# Remove .git para evitar conflitos futuros
rm -rf "$NVIM_DIR/.git"

success "AstroNvim instalado em $NVIM_DIR"
warn "Dica: Execute 'nvim' para baixar plugins e finalizar a configuração."

# ====================
# 3. Hidden Applications (.desktop ocultos)
# ====================
info "Configurando aplicações ocultas..."

HIDDEN_SRC="$DOTFILES_DIR/local/share/applications"
HIDDEN_DEST="$HOME/.local/share/applications"

if [[ -d "$HIDDEN_SRC" ]]; then
    link "$HIDDEN_SRC" "$HIDDEN_DEST"
    success "Aplicações ocultas configuradas."
else
    warn "Diretório $HIDDEN_SRC não encontrado. Pulando hidden apps."
fi

# ====================
# Finalização
# ====================
echo
success "Instalação mínima concluída com sucesso!"
echo
echo "Próximos passos recomendados:"
echo "  • Execute 'nvim' para completar a instalação do AstroNvim"
echo "  • Se necessário, atualize o cache de ícones:"
echo "      gtk-update-icon-cache ~/.local/share/icons/"
echo
echo "Dotfiles base: $DOTFILES_DIR"
echo
