#!/usr/bin/env bash

set -e  # Para o script em caso de erro 

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Global 
# --------- INICIO -----------
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

echo_header() {
    echo -e "\n${GREEN}===== $1 =====${NC}"
}

global(){
   mkdir -p "$HOME/.src"
   sudo apt install git -y
   git clone https://github.com/amonetlol/qtile.git "$HOME/.src/qtile"
}
global

DOTFILES_DIR="$HOME/.src/qtile"

# --------- FIM -----------

enable_contrib_nonfree() {
    echo "Ativando repositórios contrib e non-free..."
    sudo sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
    sudo apt update -qq
}

update_and_upgrade() {
    echo "Atualizando o sistema..."
    sudo apt upgrade -y
}

install_apps(){
 sudo apt install -y \
   wget neovim xclip gcc luarocks lua5.1 python3-pip python3-pynvim \
   tree-sitter-cli npm nodejs fd-find lazygit starship btop ripgrep \
   eza fastfetch duf kitty htop wl-clipboard
}

install_flatpak(){
 sudo apt install -y flatpak

 echo "=== Adicionando o repositório Flathub (oficial) ==="
 flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

 echo "=== Instalando o Extension Manager (GNOME Extensions) ==="
 flatpak install -y flathub com.mattjakeman.ExtensionManager
}

install_firefox() {
    echo "Instalando Firefox estável (Mozilla oficial)..."
    sudo apt remove firefox-esr -y
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | \
        sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
    sudo apt update -qq
    sudo apt install -y firefox
}

install_vscode() {
    echo "Instalando Visual Studio Code (oficial Microsoft)..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    sudo apt update -qq
    sudo apt install -y code
}

install_fonts() {
    echo_header "Instalação de fontes"
    if [[ -d "$HOME/.fonts" && -d "$HOME/.fonts/.git" ]]; then
        echo -e "${YELLOW}Atualizando fontes existentes...${NC}"
        git -C "$HOME/.fonts" pull
    else
        if [[ -d "$HOME/.fonts" ]]; then
            mv "$HOME/.fonts" "$HOME/.fonts.bak.$(date +%Y%m%d_%H%M%S)"
        fi
        git clone https://github.com/amonetlol/fonts "$HOME/.fonts"
    fi
    fc-cache -vf
    echo -e "${GREEN}Cache de fontes atualizado${NC}"
}

install_nvim() {
    echo_header "AstroNvim (template limpo)"
    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
    rm -rf ~/.config/nvim/.git
    # nvim   ← comentado, pois abre editor e trava o script
    echo "AstroNvim clonado. Abra o nvim para finalizar a instalação inicial."
}

install_hidden_applications() {
    echo_header "Aplicações ocultas"
    link "$HOME/.src/qtile/local/share/applications" "$HOME/.local/share/applications"
}

install_starship() {
   echo_header "Starship prompt"
   link "$HOME/.src/qtile/config/starship.toml" "$HOME/.config/starship.toml" 
}

install_walls() {
    echo_header "Fixes e ajustes pessoais"
    link "$HOME/.config/qtile/walls" "$HOME/walls"
}

install_shell_configs() {
    echo_header "Configurações do shell (.bashrc + .aliases)"

    if [[ -f "$DOTFILES_DIR/.bashrc" ]]; then
        BASHRC_DEST="$HOME/.bashrc"

        # Faz backup do .bashrc existente se houver
        if [[ -e "$BASHRC_DEST" || -L "$BASHRC_DEST" ]]; then
            echo -e "${YELLOW}Backup${NC} ~/.bashrc → ~/.bashrc.bak.$(date +%Y%m%d_%H%M%S)"
            mv "$BASHRC_DEST" "$BASHRC_DEST.bak.$(date +%Y%m%d_%H%M%S)"
        fi

        # Cria o symlink para .bashrc
        ln -sf "$DOTFILES_DIR/.bashrc" "$BASHRC_DEST"
        echo -e "${GREEN}Link${NC} ~/.bashrc → $DOTFILES_DIR/.bashrc"

        # Detecção da distro para carregar aliases corretos
        echo -e "${YELLOW}Detectando distro para carregar aliases corretos...${NC}"
        if [[ -f /etc/nixos/configuration.nix || -d /etc/nixos ]]; then
            DISTRO="nixos"
        elif [[ -f /etc/arch-release || -f /etc/artix-release ]]; then
            DISTRO="arch"
        elif [[ -f /etc/debian_version ]] || grep -qiE '(ubuntu|debian)' /etc/os-release 2>/dev/null; then
            DISTRO="debian"
        elif grep -qiE 'fedora' /etc/os-release 2>/dev/null || [[ -f /etc/fedora-release ]]; then
            DISTRO="fedora"
        else
            DISTRO="unknown"
        fi
        echo -e "${GREEN}Distro detectada:${NC} $DISTRO"

        # Nome do arquivo de aliases específico
        ALIASES_FILE="$DOTFILES_DIR/.aliases-$DISTRO"

        # Verifica se o arquivo específico existe
        if [[ -f "$ALIASES_FILE" ]]; then
            # Faz backup do .aliases atual se existir
            if [[ -e "$HOME/.aliases" || -L "$HOME/.aliases" ]]; then
                echo -e "${YELLOW}Backup${NC} ~/.aliases → ~/.aliases.bak.$(date +%Y%m%d_%H%M%S)"
                mv "$HOME/.aliases" "$HOME/.aliases.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
            fi

            # Cria o symlink para o .aliases correto
            ln -sf "$ALIASES_FILE" "$HOME/.aliases"
            echo -e "${GREEN}Link${NC} ~/.aliases → $ALIASES_FILE"
        else
            echo -e "${RED}Aviso:${NC} Arquivo $ALIASES_FILE não encontrado no repositório."
            echo -e " Usando apenas aliases comuns (se houver ~/.aliases)."
        fi

        echo -e "${YELLOW}Dica:${NC} Após instalar, rode 'source ~/.bashrc' para aplicar agora."
    fi
}

# Funções
enable_contrib_nonfree
update_and_upgrade
install_apps
install_flatpak
install_firefox
install_vscode
install_fonts
install_nvim
install_hidden_applications
install_starship
install_walls
install_shell_configs


