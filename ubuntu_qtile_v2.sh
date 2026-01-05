#!/bin/bash

# Script otimizado para Ubuntu: Debloat GNOME, instala Qtile + Polybar custom + Rice
# + Detecção VMware, instalação condicional de open-vm-tools-desktop

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

link() {
    local src="$1" dest="$2"
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$src" ]]; then
        echo -e "${GREEN}OK${NC} $dest -> $(basename "$src")"; return
    fi
    [[ -e "$dest" || -L "$dest" ]] && { echo -e "${YELLOW}Backup${NC} $dest -> $dest.bak.$(date +%Y%m%d_%H%M%S)"; mv "$dest" "$dest.bak.$(date +%Y%m%d_%H%M%S)"; }
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    echo -e "${GREEN}Link${NC} $dest -> $src"
}

echo_header() { echo -e "\n${GREEN}===== $1 =====${NC}"; }

debloat_ubuntu_gnome() {
    echo_header "Debloating Ubuntu GNOME"
    sudo apt purge -y --autoremove \
        gnome-shell gnome-software gnome-calendar gnome-calculator gnome-clocks gnome-contacts gnome-font-viewer gnome-logs gnome-maps gnome-music \
        gnome-photos gnome-screenshot gnome-system-monitor gnome-terminal gnome-text-editor gnome-weather rhythmbox totem yaru-theme-gnome-shell \
        ubuntu-desktop ubuntu-session gdm3 nautilus evince eog file-roller seahorse simple-scan baobab gnome-disk-utility gnome-tweaks \
        gnome-control-center gnome-settings-daemon gnome-backgrounds gnome-initial-setup gnome-online-accounts gnome-user-docs gnome-user-share \
        gnome-remote-desktop gnome-bluetooth gnome-power-manager gnome-keyring gnome-menus gnome-themes-extra gnome-accessibility-themes \
        libreoffice* thunderbird* remmina* transmission* aisleriot cheese deja-dup evolution firefox-esr* shotwell* yelp* orca*
    sudo apt autoremove -y
    sudo apt clean
}

enable_multiverse() {
    echo_header "Habilitando multiverse"
    sudo add-apt-repository multiverse -y
    sudo apt update -qq
}

update_and_upgrade() {
    echo_header "Atualizando sistema"
    sudo apt full-upgrade -y -qq
}

add_repos() {
    echo_header "Adicionando repositórios (Firefox, VSCode)"
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
    
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
}

detect_vmware_and_install_tools() {
    echo_header "Detectando VMware"
    if lspci | grep -iq vmware || dmidecode -s system-manufacturer | grep -iq vmware || dmidecode -s bios-vendor | grep -iq vmware; then
        echo "VMware detectada → instalando open-vm-tools-desktop"
        VMWARE_PKG="open-vm-tools-desktop"
    else
        echo "Não é VMware → pulando open-vm-tools-desktop"
        VMWARE_PKG=""
    fi
}

install_all_packages() {
    echo_header "Instalando pacotes essenciais + Firefox + VSCode + Qtile"
    sudo apt update -qq
    sudo apt install -y -qq \
        firefox code \
        mate-polkit pavucontrol x11-xserver-utils python3-psutil python3-dbus wget neovim git rofi dmenu scrot xclip dunst alsa-utils alacritty picom \
        unzip gcc luarocks maim loupe mousepad numlockx thunar thunar-volman thunar-archive-plugin file-roller gvfs zip p7zip-full unrar-free bat \
        nwg-look xdg-user-dirs xdg-user-dirs-gtk xdotool jq xxhash xwallpaper imagemagick findutils coreutils bc lua5.1 python3-pip python3-pynvim \
        tree-sitter-cli npm nodejs fd-find feh fuse libgtk-3-dev lightdm slick-greeter lazygit starship btop ripgrep \
        eza fastfetch duf kitty htop gammastep polybar qtile curl $VMWARE_PKG
}

enable_services() {
    echo_header "Habilitando serviços"
    sudo systemctl enable lightdm
    sudo dpkg-reconfigure lightdm -f noninteractive
    [[ -n "$VMWARE_PKG" ]] && sudo systemctl enable vmtoolsd
}

clone_qtile() {
    echo_header "Clonando e configurando Qtile (fork amonetlol)"
    mkdir -p "$HOME/.src"
    git clone --depth 1 https://github.com/amonetlol/qtile.git "$HOME/.src/qtile"
    cd "$HOME/.src/qtile" || return
    [[ -f "install_qtile.sh" ]] && chmod +x install_qtile.sh && ./install_qtile.sh
}

polybar_configs() {
    echo_header "Instalando Polybar customizada (amonetlol/polybar)"
    local dir="$HOME/.src/polybar"
    rm -rf "$dir"  # Remove antiga para garantir versão fresca
    git clone --depth 1 https://github.com/amonetlol/polybar.git "$dir"
    cd "$dir" || return
    [[ -f "00-install.sh" ]] && chmod +x 00-install.sh && ./00-install.sh
}

rice() {
    echo_header "Aplicando Rice final"
    local zip_script="$HOME/.src/scripts/rice/rice.sh"
    local set_script="$HOME/.src/scripts/rice/set_rice.sh"

    if [[ -f "$zip_script" ]]; then
        chmod +x "$zip_script" "$set_script" 2>/dev/null
        "$zip_script"
        # set_rice.sh geralmente precisa de interação ou roda depois – deixei comentado por segurança
        # [[ -x "$set_script" ]] && "$set_script"
    else
        echo -e "${YELLOW}Aviso:${NC} rice.sh não encontrado em $zip_script"
    fi
}

install_shell_configs() {
    echo_header "Configurações shell (.bashrc + aliases)"
    link "$HOME/.src/qtile/.bashrc" "$HOME/.bashrc"
    link "$HOME/.src/qtile/.aliases" "$HOME/.aliases"
    link "$HOME/.src/qtile/.aliases-debian" "$HOME/.aliases-debian"
    echo -e "${YELLOW}Dica:${NC} source ~/.bashrc para aplicar agora."
}

set_wallpaper() {
    feh --bg-fill '/home/pio/walls/monokai_pro_blue_debian.png'  # Ajuste o caminho
}

# Execução principal
echo "======================================"
echo "   Rice Ubuntu → Qtile + Polybar     "
echo "======================================"

enable_multiverse
debloat_ubuntu_gnome
update_and_upgrade
add_repos
detect_vmware_and_install_tools
install_all_packages
enable_services
clone_qtile
polybar_configs
rice
install_shell_configs
set_wallpaper

echo "======================================"
echo "           Rice concluído!           "
echo "======================================"
echo "• Reinicie o sistema"
echo "• No LightDM escolha a sessão Qtile"
echo "• source ~/.bashrc para atualizar o shell"
echo "• Caso queira rodar set_rice.sh manualmente depois: ~/.src/scripts/rice/set_rice.sh"
