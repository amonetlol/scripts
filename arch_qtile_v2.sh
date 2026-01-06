#!/usr/bin/env bash
#set -euo pipefail

# --- Lista de Otimizações ---
# echo header: OK
# optimização de código: OK

# base-devel archlinux-keyring

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

link() {
    local src="$1" dest="$2"
    [[ -L "$dest" && "$(readlink -f "$dest")" == "$src" ]] && { echo -e "${GREEN}OK${NC} $dest -> $(basename "$src")"; return; }
    [[ -e "$dest" || -L "$dest" ]] && { echo -e "${YELLOW}Backup${NC} $dest -> $dest.bak.$(date +%Y%m%d_%H%M%S)"; mv "$dest" "$dest.bak.$(date +%Y%m%d_%H%M%S)"; }
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

aur_helper() {
    echo_header "Aur Helper..."
    command -v yay >/dev/null 2>&1 && { echo "yay já instalado."; return; }
    mkdir -p "$HOME/.src" && cd "$HOME/.src" || return
    rm -rf yay-bin  # Limpa para clone fresco
    sudo pacman -S fakeroot --noconfirm
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git yay-bin && cd yay-bin || return
    makepkg --noconfirm -si
}

# Final
pacman_parallel_downloads() {
    echo_header "Otimizando pacman"
    sudo sed -i -e '/^ParallelDownloads/s/^/#/' -e '/^#ParallelDownloads/a ParallelDownloads = 25' \
            -e 's/^#Color$/Color/' \
            -e '/^Color/a ILoveCandy' \
            /etc/pacman.conf
}

vm_tools() {
    echo_header "VM Tools..."
    pacman -Qs open-vm-tools >/dev/null && { echo "VM Tools já instalado."; return; }
    yay -S --needed --noconfirm open-vm-tools fuse2 gtkmm3
    sudo systemctl enable --now vmtoolsd
}

# Arch - Instalação otimizada (sem duplicatas)
packages="visual-studio-code-bin polkit-gnome pavucontrol reflector rsync xorg-xrandr
ttf-jetbrains-mono-nerd firefox python-psutil python-dbus-next wget neovim git kitty
rofi scrot xclip dunst alsa-utils alacritty picom unzip fastfetch eza duf starship
btop ripgrep gcc luarocks lazygit pmenu dmenu maim loupe mousepad numlockx thunar
thunar-volman thunar-archive-plugin file-roller gvfs zip p7zip unrar bat nwg-look
xdg-user-dirs xdotool jq xxhsum xwallpaper imagemagick findutils coreutils bc lua51
python-pipenv python-nvim tree-sitter-cli npm nodejs fd feh qtile htop screenfetch
gammastep polybar neofetch catfish baobab linux-zen"

install() {
    yay -Syu --needed --noconfirm $packages &&
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}

display_manager() {
    echo_header "Configurando Display Manager"
    systemctl is-enabled --quiet sddm || systemctl is-enabled --quiet lightdm && { echo "DM já configurado."; return; }
    echo "Escolha DM: 1) SDDM (sugar-dark) 2) LightDM 3) Nenhum"
    read -p "Opção (1-3): " choice
    case $choice in
        1) yay -S --noconfirm sddm sddm-sugar-dark
           sudo mkdir -p /etc/sddm.conf.d
           echo "[Theme]\nCurrent=sugar-dark" | sudo tee /etc/sddm.conf >/dev/null
           sudo systemctl disable lightdm --now 2>/dev/null
           sudo systemctl enable sddm ;;
        2) yay -S --noconfirm lightdm lightdm-gtk-greeter           
           sudo systemctl disable sddm --now 2>/dev/null
           sudo systemctl enable lightdm ;;
        3) sudo systemctl disable sddm lightdm --now 2>/dev/null ;;
        *) echo "Inválido. Pulando." ;;
    esac
}

clone_qtile() {
    echo_header "Clonando Qtile (amonetlol fork)"
    mkdir -p "$HOME/.src"
    rm -rf "$HOME/.src/qtile"  # Limpa para fresco
    git clone --depth 1 https://github.com/amonetlol/qtile.git "$HOME/.src/qtile"
    cd "$HOME/.src/qtile" || return
    [[ -f "install_qtile.sh" ]] && chmod +x install_qtile.sh && ./install_qtile.sh
}

install_shell_configs() {
    echo_header "Configurações do shell (.bashrc + .aliases)"
    # Cria symlink do .bashrc
    link "$HOME/.src/qtile/.bashrc" "$HOME/.bashrc"    
    link "$HOME/.src/qtile/.aliases" "$HOME/.aliases"
    link "$HOME/.src/qtile/.aliases-arch" "$HOME/.aliases-arch"

    echo -e "${YELLOW}Dica:${NC} Rode 'source ~/.bashrc' para aplicar as mudanças agora."
}

feh_arch() {
    echo_header "Set wallpaper"
    echo '#!/bin/env bash\nfeh --no-fehbg --bg-fill "/home/pio/.src/qtile/config/walls/monokai_pro_blue_arch.png"' > ~/.fehbg
    chmod +x ~/.fehbg
}

rice() {
    echo_header "Aplicando Rice"
    local zip_script="$HOME/.src/scripts/rice/rice.sh"
    local set_script="$HOME/.src/scripts/rice/set_rice_qtile.sh"
    [[ -f "$zip_script" ]] && chmod +x "$zip_script" "$set_script" && "$zip_script" && "$set_script"
}

polybar_configs() {
    echo_header "Instalando Polybar custom (amonetlol)"
    local dir="$HOME/.src/polybar"
    rm -rf "$dir"
    git clone --depth 1 https://github.com/amonetlol/polybar.git "$dir"
    cd "$dir" || return
    [[ -f "00-install.sh" ]] && chmod +x 00-install.sh && ./00-install.sh
}

bye() {
  echo "Bye!!!!"
}

# função
pacman_parallel_downloads
pre_install
aur_helper
install
vm_tools
display_manager
clone_qtile
install_shell_configs
feh_arch
rice
polybar_configs
bye
