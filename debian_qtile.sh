#!/bin/bash

#set -e  # Para o script em caso de erro

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

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ----- GLOBAL ----------
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

# ---------- FIM GLOBAL ------------------

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
        eza fastfetch duf kitty htop gammastep polybar
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
    link "$HOME/.src/qtile/.aliases-debian" "$HOME/.aliases-debian"

    echo -e "${YELLOW}Dica:${NC} Rode 'source ~/.bashrc' para aplicar as mudanças agora."
}

feh_debian(){
    feh --bg-fill '/home/pio/walls/monokai_pro_blue_debian.png'
}

polybar_configs() {
    local SRC_DIR="$HOME/.src"
    local POLYBAR_DIR="$SRC_DIR/polybar"
    local REPO_URL="https://github.com/amonetlol/polybar"

    echo "=== Instalando polybar personalizada (amonetlol/polybar) ==="

    # Cria a pasta .src se não existir
    if [ ! -d "$SRC_DIR" ]; then
        echo "Criando diretório $SRC_DIR..."
        mkdir -p "$SRC_DIR"
    fi

    # Se a pasta polybar já existir, remove-a
    if [ -d "$POLYBAR_DIR" ]; then
        echo "Pasta $POLYBAR_DIR já existe. Removendo..."
        rm -rf "$POLYBAR_DIR"
    fi

    # Clona o repositório
    echo "Clonando repositório $REPO_URL..."
    if ! git clone "$REPO_URL" "$POLYBAR_DIR"; then
        echo "Erro: Falha ao clonar o repositório polybar."
        return 1
    fi

    # Entra na pasta
    cd "$POLYBAR_DIR" || {
        echo "Erro: Não foi possível entrar na pasta $POLYBAR_DIR."
        return 1
    }

    # Verifica se o script de instalação existe
    if [ ! -f "00-install.sh" ]; then
        echo "Erro: Script 00-install.sh não encontrado no repositório."
        return 1
    fi

    # Dá permissão de execução e executa
    echo "Dando permissão de execução ao 00-install.sh..."
    chmod +x "00-install.sh"

    echo "Executando o script de instalação da polybar..."
    ./00-install.sh

    if [ $? -eq 0 ]; then
        echo "Polybar instalada com sucesso!"
    else
        echo "Erro durante a execução do 00-install.sh."
        return 1
    fi

    echo "=== Instalação da polybar concluída ==="
    echo
}

bye() {
  echo "Bye!!!!"
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
polybar_configs
bye

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
