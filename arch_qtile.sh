#!/usr/bin/env bash
set -euo pipefail

# base-devel archlinux-keyring

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

pre_install(){
    echo 'MAKEFLAGS="-j$(nproc)"' | sudo tee -a /etc/makepkg.conf
    sudo pacman -S --needed --noconfirm archlinux-keyring
    sudo pacman -S --needed --noconfirm base-devel
}

aur_helper(){    
    if [ ! -d "$HOME/.src" ]; then
        mkdir -p "$HOME/.src" && cd "$HOME/.src" && git clone https://aur.archlinux.org/yay-bin && cd yay-bin && makepkg --noconfirm -si        
    else
        cd "$HOME/.src" && git clone https://aur.archlinux.org/yay-bin && cd yay-bin && makepkg --noconfirm -si
    fi  
    
}

speed(){
    sudo pacman -S --needed --noconfirm reflector rsync
    sudo reflector --country Brazil --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
}

# Arch
packages="
  visual-studio-code-bin
  polkit-gnome
  pavucontrol
  reflector
  rsync
  xorg-xrandr
  ttf-jetbrains-mono-nerd
  firefox
  python-psutil
  python-dbus-next
  wget
  neovim
  git
  kitty
  rofi
  scrot
  xclip
  dunst
  alsa-utils
  alacritty
  picom
  unzip
  fastfetch
  eza
  duf
  starship
  btop
  ripgrep
  gcc
  luarocks
  ripgrep
  lazygit
  pmenu
  dmenu
  maim
  loupe
  mousepad
  numlockx
  thunar
  thunar-volman
  thunar-archive-plugin
  file-roller
  gvfs
  zip
  unzip
  p7zip
  unrar
  bat
  nwg-look
  xdg-user-dirs  
  xdotool
  jq
  xxhsum
  xwallpaper
  imagemagick
  findutils
  coreutils
  bc
  lua51
  python-pipenv
  python-nvim
  tree-sitter-cli
  npm
  nodejs
  fd
  feh
  qtile
  htop
"

pacman_parallel_downloads() {
    echo "Configurando pacman para downloads paralelos (ParallelDownloads = 25)..."

    local config_file="/etc/pacman.conf"

    # Fazer backup do pacman.conf original (só na primeira vez)
    if [ ! -f "${config_file}.backup" ]; then
        sudo cp "${config_file}" "${config_file}.backup"
        echo "Backup do pacman.conf original criado em ${config_file}.backup"
    fi

    # Ativar ParallelDownloads = 25
    if grep -q "^#ParallelDownloads" "$config_file"; then
        sudo sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 25/' "$config_file"
    elif grep -q "^ParallelDownloads" "$config_file"; then
        sudo sed -i 's/^ParallelDownloads.*/ParallelDownloads = 25/' "$config_file"
    else
        # Se não existir a linha, adiciona na secção [options]
        sudo sed -i '/^\[options\]/a ParallelDownloads = 25' "$config_file"
    fi

    # Ativar cor (bonito no terminal)
    sudo sed -i 's/^#Color/Color/' "$config_file"

    # Ativar ILoveCandy (Pacman com "boca" em vez de barra – opcional, mas clássico)
    if grep -q "^#ILoveCandy" "$config_file"; then
        sudo sed -i 's/^#ILoveCandy/ILoveCandy/' "$config_file"
    elif ! grep -q "^ILoveCandy" "$config_file"; then
        sudo sed -i '/^\[options\]/a ILoveCandy' "$config_file"
    fi

    echo "pacman.conf configurado com sucesso!"
    echo "   → ParallelDownloads = 25"
    echo "   → Color ativado"
    echo "   → ILoveCandy ativado (pacman com animação bonitinha)"
}

vm(){
    yay -S --needed --noconfirm open-vm-tools fuse2 gtkmm3
    sudo systemctl enable --now vmtoolsd
}

install(){    
    yay -S --needed --noconfirm $packages    
}

greeter_choice() {
    echo "Escolha o Display Manager (Greeter):"
    echo "1. SDDM (com tema sugar-dark)"
    echo "2. LightDM (com slick-greeter)"
    echo "3. Nenhum"
    echo -n "Opção (1-3): "
    read choice

    case $choice in
        1)
            echo "Instalando e configurando SDDM com tema sugar-dark..."
            yay -S --needed --noconfirm sddm sddm-sugar-dark

            # Criar ou editar /etc/sddm.conf para definir o tema
            sudo mkdir -p /etc/sddm.conf.d
            if ! sudo grep -q "\[Theme]" /etc/sddm.conf 2>/dev/null; then
                echo "[Theme]" | sudo tee -a /etc/sddm.conf > /dev/null
            fi
            if sudo grep -q "^Current=" /etc/sddm.conf; then
                sudo sed -i 's/^Current=.*/Current=sugar-dark/' /etc/sddm.conf
            else
                echo "Current=sugar-dark" | sudo tee -a /etc/sddm.conf > /dev/null
            fi

            # Desativar LightDM se estiver ativo
            sudo systemctl disable lightdm --now 2>/dev/null || true

            sudo systemctl enable sddm
            echo "SDDM configurado e ativado com tema sugar-dark."
            ;;
        2)
            echo "Instalando e configurando LightDM com slick-greeter..."
            yay -S --needed --noconfirm lightdm lightdm-slick-greeter  # lightdm-slick-greeter está nos repositórios oficiais (extra)

            # Configurar greeter-session=slick-greeter em /etc/lightdm/lightdm.conf
            sudo mkdir -p /etc/lightdm
            if ! sudo grep -q "\[Seat:\*\]" /etc/lightdm/lightdm.conf 2>/dev/null; then
                echo "[Seat:*]" | sudo tee /etc/lightdm/lightdm.conf > /dev/null
            fi
            if sudo grep -q "^greeter-session=" /etc/lightdm/lightdm.conf; then
                sudo sed -i 's/^greeter-session=.*/greeter-session=slick-greeter/' /etc/lightdm/lightdm.conf
            else
                echo "greeter-session=slick-greeter" | sudo tee -a /etc/lightdm/lightdm.conf > /dev/null
            fi

            # Desativar SDDM se estiver ativo
            sudo systemctl disable sddm --now 2>/dev/null || true

            sudo systemctl enable lightdm
            echo "LightDM configurado e ativado com slick-greeter."
            echo "Nota: Para mais customizações (background, etc.), edita /etc/lightdm/slick-greeter.conf"
            ;;
        3)
            echo "Nenhum display manager instalado/ativado."
            sudo systemctl disable sddm lightdm --now 2>/dev/null || true
            ;;
        *)
            echo "Opção inválida. Nenhuma ação realizada."
            ;;
    esac
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
    link "$HOME/.src/qtile/.aliases-arch" "$HOME/.aliases-arch"

    echo -e "${YELLOW}Dica:${NC} Rode 'source ~/.bashrc' para aplicar as mudanças agora."
}

feh_arch(){
    feh --bg-fill '/home/pio/walls/monokai_pro_blue_arch.png'
}

bye() {
  echo "Bye!!!!"
}

# função
pacman_parallel_downloads
pre_install
speed
aur_helper
install
vm
greeter_choice
clone_qtile
install_shell_configs
feh_arch
bye
