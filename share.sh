#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------
#  --------------- V2 ------------------
# --------------------------------------
#
# --- Lista de Otimizações ---
# echo header: OK
# optimização de código: OK

# Cores
G='\033[0;32m' Y='\033[1;33m' N='\033[0m'

header() { echo -e "\n${G}===== $1 =====${N}"; }
link() {
    local src="$1" dest="$2"
    local abs_src=$(readlink -f "$src")
    if [[ -L "$dest" && $(readlink -f "$dest") == "$abs_src" ]]; then
        echo -e "${G}OK${N} $dest -> $(basename "$src")"
        return
    fi
    [[ -e "$dest" || -L "$dest" ]] && mv "$dest" "$dest.bak.$(date +%Y%m%d_%H%M%S)" && echo -e "${Y}Backup${N} $dest"
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    echo -e "${G}Link${N} $dest -> $src"
}

# Instala git se necessário e clona dotfiles
setup_base() {
    mkdir -p "$HOME/.src"
    [[ -f /etc/os-release ]] && . /etc/os-release

    if ! command -v git &>/dev/null; then
        echo "Git não encontrado. Instalando..."
        case "$ID$ID_LIKE" in
            *fedora*|*rhel*) sudo dnf install -y git ;;
            *ubuntu*|*debian*) sudo apt update && sudo apt install -y git ;;
            *arch*) sudo pacman -S --noconfirm git ;;
            *) echo "Distro não suportada automaticamente. Instale git manualmente." && exit 1 ;;
        esac
    fi

    local dest="$HOME/.src/qtile"
    rm -rf "$dest"
    git clone --depth 1 https://github.com/amonetlol/qtile.git "$dest"
    rm -rf ~/.src/qtile/.git
    echo "Dotfiles clonados!"
}
setup_base
DOT="$HOME/.src/qtile"

# Fontes
header "Instalação de fontes"
if [[ -d "$HOME/.fonts/.git" ]]; then
    git -C "$HOME/.fonts" pull
else
    [[ -d "$HOME/.fonts" ]] && mv "$HOME/.fonts" "$HOME/.fonts.bak.$(date +%Y%m%d_%H%M%S)"
    git clone --depth 1 https://github.com/amonetlol/fonts "$HOME/.fonts"
fi
fc-cache -vf

# AstroNvim usuário
header "AstroNvim (usuário)"
rm -rf ~/.config/nvim
git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
rm -rf ~/.config/nvim/.git

# Mappings personalizados
mkdir -p ~/.config/nvim/lua/user
cat > ~/.config/nvim/lua/user/mappings.lua << 'EOF'
return {
  -- Modo Normal
  n = {
    ["<C-s>"] = { "<cmd>w<cr>", desc = "Salvar buffer" },
    ["<C-q>"] = { "<cmd>wqa<cr>", desc = "Salvar e sair todos" },
  },
  -- Modo Insert
  i = {
    ["<C-s>"] = { "<cmd>w<cr>", desc = "Salvar buffer" },
    ["<C-q>"] = { "<cmd>wqa<cr>", desc = "Salvar e sair todos" },
  },
  -- Modo Visual
  v = {
    ["<C-s>"] = { "<cmd>w<cr>", desc = "Salvar buffer" },
    ["<C-q>"] = { "<cmd>wqa<cr>", desc = "Salvar e sair todos" },
  },
}
EOF

# OU
# mkdir -p ~/.config/nvim/lua/user
# curl -sLf https://github.com/amonetlol/scripts/raw/refs/heads/main/TEMP/nvim_fix/mappings.lua -o ~/.config/nvim/lua/user/mappings.lua

echo "AstroNvim pronto. Abra nvim para sincronizar plugins."

# Aplicações ocultas
header "Aplicações ocultas"
link "$DOT/local/share/applications" "$HOME/.local/share/applications"

# Starship
header "Starship prompt"
link "$DOT/config/starship.toml" "$HOME/.config/starship.toml"

# Demais configs + bin
header "Configs e binários"
link "$DOT/config/kitty"      "$HOME/.config/kitty"
link "$DOT/config/fastfetch"  "$HOME/.config/fastfetch"
link "$DOT/config/alacritty"  "$HOME/.config/alacritty"
link "$DOT/config/neofetch"   "$HOME/.config/neofetch"
link "$DOT/config/qtile/walls" "$HOME/walls"
link "$DOT/bin"               "$HOME/.bin"
chmod +x "$HOME/.bin"/* 2>/dev/null || true

# ufetch
header "ufetch"
"$HOME/.bin/get_ufetch"

# AstroNvim root
header "AstroNvim (root)"
sudo rm -rf /root/.config/nvim
sudo git clone --depth 1 https://github.com/AstroNvim/template /root/.config/nvim
sudo rm -rf /root/.config/nvim/.git

echo -e "\n${G}Tudo concluído! Seu setup está pronto.${N}"
