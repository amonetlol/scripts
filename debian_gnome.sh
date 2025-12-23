#!/usr/bin/env bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

link() {
    local src="$1"
    local dest="$2"
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$src" ]]; then
        echo -e "${GREEN}OK${NC} $dest -> $(basename "$src")"
        return
    fi
    if [[ -e "$dest" || -L "$dest" ]]; then
        echo -e "${YELLOW}Backup${NC} $dest -> $dest.bak.$(date +%Y%m%d_%H%M%S)"
        mv "$dest" "$dest.bak.$(date +%Y%m%d_%H%M%S)"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    echo -e "${GREEN}Link${NC} $dest -> $src"
}

echo_header() {
    echo -e "\n${GREEN}===== $1 =====${NC}"
}

global() {
    mkdir -p "$HOME/.src"
    sudo apt install git -y
    git clone https://github.com/amonetlol/qtile.git "$HOME/.src/qtile"
}

global
DOTFILES_DIR="$HOME/.src/qtile"

enable_contrib_nonfree() {
    echo "Ativando repositórios contrib e non-free..."
    sudo sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
    sudo apt update -qq
}

update_and_upgrade() {
    echo "Atualizando o sistema..."
    sudo apt upgrade -y
}

install_apps() {
    sudo apt install -y \
        wget neovim xclip gcc luarocks lua5.1 python3-pip python3-pynvim \
        tree-sitter-cli npm nodejs fd-find lazygit starship btop ripgrep \
        eza fastfetch duf kitty htop wl-clipboard
}

install_flatpak() {
    sudo apt install -y flatpak
    echo "=== Adicionando o repositório Flathub (oficial) ==="
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "=== Instalando o Extension Manager (GNOME Extensions) ==="
    sudo flatpak install -y flathub com.mattjakeman.ExtensionManager
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

install_shell_configs() {
    echo_header "Configurações do shell (.bashrc + .aliases)"
    # Cria symlink do .bashrc
    link "$HOME/.src/qtile/" "$HOME/.bashrc"    
    link "$HOME/.src/qtile/.aliases" "$HOME/.aliases"
    link "$HOME/.src/qtile/.aliases-debian" "$HOME/.aliases-debian"

    echo -e "${YELLOW}Dica:${NC} Rode 'source ~/.bashrc' para aplicar as mudanças agora."
}

links_configs(){
    link "$HOME/.src/qtile/config/kitty" "$HOME/.config/kitty"
    link "$HOME/.src/qtile/config/fastfetch" "$HOME/.config/fastfetch"
    link "$HOME/.src/qtile/config/alacritty" "$HOME/.config/alacritty"
    link "$HOME/.src/qtile/config/neofetch" "$HOME/.config/neofetch"
    link "$HOME/.src/qtile/config/qtile/walls" "$HOME/walls"
}

tema_gnome-terminal(){
    sudo apt install dconf-cli uuid-runtime -y
    #Reset total dos perfis (isso remove tudo, mas é o que mais resolve):
    Bashdconf reset -f /org/gnome/terminal/legacy/profiles:/
    bash -c "$(wget -qO- https://git.io/vQgMr)"
}

install_walls() {
    echo_header "Fixes e ajustes pessoais"
    link "$HOME/.config/qtile/walls" "$HOME/walls"
}

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
install_shell_configs
links_configs
tema_gnome-terminal
install_walls
