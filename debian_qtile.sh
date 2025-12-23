#!/bin/bash

set -e  # Para o script em caso de erro

# Debian Trixie 13
# /etc/apt/sources.list
# deb http://deb.debian.org/debian/ trixie main non-free-firmware
# deb-src http://deb.debian.org/debian/ trixie main non-free-firmware
# deb http://security.debian.org/debian-security trixie-security main non-free-firmware
# deb-src http://security.debian.org/debian-security trixie-security main non-free-firmware
# deb http://deb.debian.org/debian/ trixie-updates main non-free-firmware
# deb-src http://deb.debian.org/debian/ trixie-updates main non-free-firmware

# Debian SID
# /etc/apt/sources.list
# deb http://deb.debian.org/debian/ sid main contrib non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ sid main contrib non-free non-free-firmware

# ==============================================
# Configuração do script - ative/desative aqui
# ==============================================

# ==============================================
# Funções
# ==============================================

enable_contrib_nonfree() {
    echo "Ativando repositórios contrib e non-free..."
    sudo sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
    sudo apt update -qq
}

update_and_upgrade() {
    echo "Atualizando o sistema..."
    sudo apt upgrade -y
}

install_basic_packages() {
    echo "Instalando pacotes básicos..."
    sudo apt install -y \
        mate-polkit pavucontrol x11-xserver-utils python3-psutil python3-dbus \
        wget neovim git rofi dmenu scrot xclip dunst alsa-utils alacritty picom \
        unzip gcc luarocks maim loupe mousepad numlockx thunar thunar-volman \
        thunar-archive-plugin file-roller gvfs zip p7zip-full unrar-free bat \
        nwg-look xdg-user-dirs xdg-user-dirs-gtk xdotool jq xxhash xwallpaper \
        imagemagick findutils coreutils bc lua5.1 python3-pip python3-pynvim \
        tree-sitter-cli npm nodejs fd-find feh qtile open-vm-tools-desktop \
        fuse libgtk-3-dev lightdm slick-greeter lazygit starship btop ripgrep \
        eza fastfetch duf kitty htop
}

install_firefox_official() {
    echo "Instalando Firefox estável (Mozilla oficial)..."
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

enable_services() {
    echo "Habilitando serviços..."
    sudo systemctl enable vmtoolsd
    sudo systemctl enable lightdm
}

install_sddm_sugar_dark() {
    echo "Instalando SDDM com tema Sugar Dark..."
    sudo apt install -y sddm
    sudo systemctl enable sddm
    sudo mkdir -p /usr/share/sddm/themes
    sudo git clone --depth 1 https://github.com/MarianArlt/sddm-sugar-dark.git /usr/share/sddm/themes/sugar-dark
    sudo sh -c 'echo "[Theme]\nCurrent=sugar-dark" > /etc/sddm.conf'
}

clone_qtile() {
    mkdir -p "$HOME/.src"
    local qtile_dir="$HOME/.src/qtile"
    local repo_url="https://github.com/amonetlol/qtile.git"
    local install_qtile_script="$qtile_dir/install_qtile.sh"

    echo "→ Iniciando instalação/configuração do qtile (amonetlol fork)"

    mkdir -p "$HOME/.src" || { echo "Erro ao criar ~/.src"; return 1; }

    echo "Clonando qtile (amonetlol fork) → $qtile_dir"
       git clone "$repo_url" "$qtile_dir" || { echo "Falha ao clonar"; return 1; }
       cd "$qtile_dir" || return 1

    if [ -f "$install_qtile_script" ]; then
        chmod +x "$install_qtile_script" || echo "Aviso: não conseguiu dar permissão em pos_install.sh"
    else
        echo "Aviso: pos_install.sh não encontrado em $qtile_dir"
    fi

    if [ -f "$install_qtile_script" ]; then
        echo "Abrindo pos_install.sh no neovim..."
        nvim "$install_qtile_script"
        sh "$install_qtile_script"
    else
        echo "pos_install.sh não encontrado. Edite manualmente depois:"
        echo "   $install_qtile_script"
    fi    
}

install_shell_configs() {
    echo_header "Configurações do shell (.bashrc + .aliases)"
    # Cria symlink do .bashrc
    link "$HOME/.src/qtile/.bashrc" "$HOME/.bashrc"    
    link "$HOME/.src/qtile/.aliases" "$HOME/.aliases"
    link "$HOME/.src/qtile/.aliases-debina" "$HOME/.aliases-debian"

    echo -e "${YELLOW}Dica:${NC} Rode 'source ~/.bashrc' para aplicar as mudanças agora."
}

feh_debian(){
    feh --bg-fill '/home/pio/walls/monokai_pro_blue_debian.png'
}


# ==============================================
# Execução principal
# ==============================================

echo "======================================"
echo "      Configuração do ambiente       "
echo "======================================"

enable_contrib_nonfree
update_and_upgrade
install_basic_packages
install_firefox_official
install_vscode
enable_services
#install_sddm_sugar_dark
clone_qtile
install_shell_configs
feh_debian

echo
echo "======================================"
echo "         Configuração concluída!      "
echo "======================================"
echo
echo "Sugestões finais:"
echo "• Reinicie o sistema para aplicar o LightDM/SDDM"
echo "• Para aplicar PATH novo imediatamente: source ~/.bashrc"
echo "• Se quiser usar outro polkit (lxpolkit, etc), remova mate-polkit"
echo
