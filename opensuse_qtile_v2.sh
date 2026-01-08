#!/usr/bin/env bash
#set -euo pipefail

# --- Lista de Otimizações ---
# echo header: OK
# optimização de código: OK

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

# ---------- Otimizações e Mirrors Brasil ----------
optimize_mirrors() {
    echo_header "Forçando mirrors brasileiros (UFPR - rápido)"
    sudo zypper mr -k --replace https://download.opensuse.org/tumbleweed/ https://opensuse.c3sl.ufpr.br/tumbleweed/ $(sudo zypper lr | grep repo-oss | awk '{print $1}')
    sudo zypper mr -k --replace https://download.opensuse.org/tumbleweed/ https://opensuse.c3sl.ufpr.br/tumbleweed/ $(sudo zypper lr | grep repo-update | awk '{print $1}')
    sudo zypper mr -k --replace https://download.opensuse.org/tumbleweed/ https://opensuse.c3sl.ufpr.br/tumbleweed/ $(sudo zypper lr | grep repo-non-oss | awk '{print $1}')
    sudo zypper ref
}

# ---------- Atualização completa ----------
full_update() {
    echo_header "Atualização completa do sistema"
    sudo zypper dup --no-allow-vendor-change
}

# ---------- VM Tools ----------
vm_tools() {
    echo_header "VM Tools (open-vm-tools)"
    zypper search --installed-only open-vm-tools >/dev/null && { echo "VM Tools já instalado."; return; }
    sudo zypper in -y open-vm-tools open-vm-tools-desktop
    sudo systemctl enable --now vmtoolsd vmware-vmblock-fuse
}

# ---------- Pacotes principais ----------
packages="polkit-gnome pavucontrol ttf-jetbrains-mono-nerd firefox python3-psutil python3-dbus-python wget neovim git kitty rofi scrot xclip dunst alsa-utils alacritty picom unzip fastfetch eza duf btop ripgrep gcc luarocks pmenu dmenu maim loupe mousepad starship lazygit numlockx thunar thunar-volman thunar-archive-plugin file-roller gvfs zip p7zip unrar bat nwg-look xdg-user-dirs xdotool jq xwallpaper imagemagick bc lua51 python3-pip tree-sitter npm nodejs fd feh qtile htop gammastep polybar neofetch catfish baobab open-vm-tools-desktop fzf zoxide fd-bash-completion"

install_packages() {
    echo_header "Instalando pacotes principais"
    sudo zypper in -y $packages
}

# ---------- VS Code (proprietário Microsoft) ----------
install_vscode() {
    echo_header "Instalando Visual Studio Code (Microsoft repo)"
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo zypper ar https://packages.microsoft.com/yumrepos/vscode vscode
    sudo zypper ref
    sudo zypper in -y code
}

# ---------- Display Manager ----------
display_manager() {
    echo_header "Configurando Display Manager"
    systemctl is-enabled --quiet sddm || systemctl is-enabled --quiet lightdm && { echo "DM já configurado."; return; }
    echo "Escolha DM: 1) SDDM (sugar-dark) 2) LightDM 3) Nenhum"
    read -p "Opção (1-3): " choice
    case $choice in
        1) sudo zypper in -y sddm
           sudo mkdir -p /etc/sddm.conf.d
           # echo -e "[Theme]\nCurrent=sugar-dark" | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
           sudo systemctl disable lightdm --now 2>/dev/null
           sudo systemctl enable sddm ;;
        2) sudo zypper in -y lightdm lightdm-gtk-greeter
           sudo systemctl disable sddm --now 2>/dev/null
           sudo systemctl enable lightdm ;;
        3) sudo systemctl disable sddm lightdm --now 2>/dev/null ;;
        *) echo "Inválido. Pulando." ;;
    esac
}

# ---------- Clone Qtile (fork amonetlol) ----------
clone_qtile() {
    echo_header "Clonando Qtile (amonetlol fork)"
    mkdir -p "$HOME/.src"
    rm -rf "$HOME/.src/qtile"
    git clone --depth 1 https://github.com/amonetlol/qtile.git "$HOME/.src/qtile"
    cd "$HOME/.src/qtile" || return
    [[ -f "install_qtile.sh" ]] && chmod +x install_qtile.sh && ./install_qtile.sh
}

# ---------- Configs shell ----------
install_shell_configs() {
    echo_header "Configurações do shell (.bashrc + .aliases)"
    link "$HOME/.src/qtile/.bashrc" "$HOME/.bashrc"
    link "$HOME/.src/qtile/.aliases" "$HOME/.aliases"
    link "$HOME/.src/qtile/.aliases-opensuse" "$HOME/.aliases-opensuse"  # renomeei para evitar confusão
    echo -e "${YELLOW}Dica:${NC} Rode 'source ~/.bashrc' para aplicar agora."
}

# ---------- Wallpaper com feh ----------
feh_wallpaper() {
    echo_header "Set wallpaper"
    mkdir -p ~/.config
    echo '#!/bin/env bash\nfeh --no-fehbg --bg-fill "/home/'"$USER"'/.src/qtile/config/walls/monokai_pro_blue_opensuse.png"' > ~/.fehbg
    chmod +x ~/.fehbg
}

# ---------- Rice ----------
rice() {
    echo_header "Aplicando Rice"
    local zip_script="$HOME/.src/scripts/rice/rice.sh"
    local set_script="$HOME/.src/scripts/rice/set_rice_qtile.sh"
    [[ -f "$zip_script" ]] && chmod +x "$zip_script" "$set_script" && "$zip_script" && "$set_script"
}

# ---------- Polybar custom (amonetlol) ----------
polybar_configs() {
    echo_header "Instalando Polybar custom (amonetlol)"
    local dir="$HOME/.src/polybar"
    rm -rf "$dir"
    git clone --depth 1 https://github.com/amonetlol/polybar.git "$dir"
    cd "$dir" || return
    [[ -f "00-install.sh" ]] && chmod +x 00-install.sh && ./00-install.sh
}

bye() {
    echo -e "\n${GREEN}Instalação concluída! Reinicie o sistema.${NC}"
    echo "Bye!!!!"
}

# ---------- Execução ----------
#optimize_mirrors
full_update
vm_tools
install_packages
install_vscode
display_manager
clone_qtile
install_shell_configs
feh_wallpaper
rice
polybar_configs
full_update  # atualização final
bye
