#!/usr/bin/env bash
# Rice Manjaro → Debloat GNOME + Qtile + Polybar custom
# Versão tolerante a falhas: continua mesmo com erro e registra tudo no log

set -euo pipefail

LOG_FILE="$HOME/manjaro_rice.log"
FAILED_MODULES=()

# Redireciona todo output (stdout + stderr) para tela E para o log
exec > >(tee -a "$LOG_FILE") 2>&1

echo "======================================"
echo "Iniciando Rice Manjaro → Debloat GNOME + Qtile"
echo "Data: $(date)"
echo "Log salvo em: $LOG_FILE"
echo "======================================"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Função que executa um módulo e registra erro sem parar o script
run_module() {
    local module_name="$1"
    shift
    echo -e "\n${GREEN}===== Iniciando: $module_name =====${NC}"
    
    if "$@"; then
        echo -e "${GREEN}===== $module_name → SUCESSO =====${NC}"
    else
        local exit_code=$?
        echo -e "${RED}===== ERRO no módulo: $module_name (código $exit_code) =====${NC}"
        echo -e "${RED}Detalhes do erro acima. Continuando com os próximos módulos...${NC}\n"
        FAILED_MODULES+=("$module_name")
    fi
}

link() {
    local src="$1" dest="$2"
    [[ -L "$dest" && "$(readlink -f "$dest")" == "$(realpath "$src")" ]] && {
        echo -e "${GREEN}OK${NC} $dest → $(basename "$src")"
        return
    }
    [[ -e "$dest" || -L "$dest" ]] && {
        echo -e "${YELLOW}Backup${NC} $dest → $dest.bak.$(date +%Y%m%d_%H%M%S)"
        mv "$dest" "$dest.bak.$(date +%Y%m%d_%H%M%S)"
    }
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    echo -e "${GREEN}Link${NC} $dest → $src"
}

echo_header() { echo -e "\n${GREEN}===== $1 =====${NC}"; }

pacman_parallel_downloads() {
    echo_header "Otimizando pacman"
    sudo sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 25/; s/^#Color/Color/; /#ILoveCandy/! { /\[options\]/a ILoveCandy }' /etc/pacman.conf
}

debloat_manjaro_gnome() {
    echo_header "Debloating Manjaro GNOME"
    local pkgs_to_remove=(
        gnome-music decibels gnome-weather gnome-calendar gnome-firmware malcontent micro
        gnome-software gnome-calculator gnome-clocks gnome-contacts gnome-font-viewer gnome-logs
        gnome-maps gnome-photos gnome-screenshot gnome-system-monitor gnome-terminal gnome-text-editor
        gnome-backgrounds gnome-control-center gnome-initial-setup gnome-online-accounts gnome-user-docs
        gnome-user-share gnome-remote-desktop gnome-bluetooth gnome-power-manager gnome-keyring gnome-menus
        gnome-themes-extra gnome-accessibility-themes libreoffice* thunderbird* remmina* transmission*
        aisleriot cheese deja-dup evolution shotwell* yelp* orca* rhythmbox totem gdm3 nautilus
        evince eog file-roller seahorse simple-scan baobab gnome-disk-utility gnome-tweaks gnome-settings-daemon
    )
    sudo pacman -Rns --noconfirm "${pkgs_to_remove[@]}" 2>/dev/null || echo "Alguns pacotes não existiam (normal)"
    sudo pacman -Scc --noconfirm
}

aur_helper() {
    command -v yay >/dev/null 2>&1 && { echo "yay já instalado."; return; }
    mkdir -p "$HOME/.src" && cd "$HOME/.src"
    rm -rf yay-bin
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git yay-bin && cd yay-bin
    makepkg --noconfirm -si
}

install_packages() {
    echo_header "Instalando pacotes essenciais + Qtile"
    local pkgs=(
        visual-studio-code-bin polkit-gnome pavucontrol reflector rsync xorg-xrandr ttf-jetbrains-mono-nerd
        firefox python-psutil python-dbus-next wget neovim git kitty rofi scrot xclip dunst alsa-utils alacritty
        picom unzip fastfetch eza duf starship btop ripgrep gcc luarocks lazygit pmenu dmenu maim loupe mousepad
        numlockx thunar thunar-volman thunar-archive-plugin file-roller gvfs zip p7zip unrar bat nwg-look
        xdg-user-dirs xdotool jq xxhsum xwallpaper imagemagick findutils coreutils bc lua51 python-pipenv python-nvim
        tree-sitter-cli npm nodejs fd feh qtile htop screenfetch gammastep polybar neofetch catfish baobab linux-zen
    )
    aur_helper
    yay -S --needed --noconfirm "${pkgs[@]}"
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}

vm_tools() {
    pacman -Qs open-vm-tools >/dev/null && { echo "VM Tools já instalado."; return; }
    yay -S --needed --noconfirm open-vm-tools fuse2 gtkmm3
    sudo systemctl enable --now vmtoolsd
}

display_manager() {
    echo_header "Configurando Display Manager"
    systemctl is-enabled --quiet sddm || systemctl is-enabled --quiet lightdm && { echo "DM já configurado."; return; }
    echo "Escolha DM: 1) SDDM (sugar-dark) 2) LightDM (slick) 3) Nenhum"
    read -p "Opção (1-3): " choice
    case $choice in
        1) yay -S --noconfirm sddm sddm-sugar-dark
           echo "[Theme]"$'\n'"Current=sugar-dark" | sudo tee /etc/sddm.conf >/dev/null
           sudo systemctl disable lightdm --now 2>/dev/null
           sudo systemctl enable sddm ;;
        2) yay -S --noconfirm lightdm lightdm-gtk-greeter lightdm-slick-greeter
           echo "[Seat:*]"$'\n'"greeter-session=lightdm-slick-greeter" | sudo tee /etc/lightdm/lightdm.conf >/dev/null
           sudo systemctl disable sddm --now 2>/dev/null
           sudo systemctl enable lightdm ;;
        3) sudo systemctl disable sddm lightdm --now 2>/dev/null ;;
        *) echo "Opção inválida. Pulando configuração do DM." ;;
    esac
}

clone_qtile() {
    echo_header "Clonando Qtile (amonetlol fork)"
    mkdir -p "$HOME/.src"
    rm -rf "$HOME/.src/qtile"
    git clone --depth 1 https://github.com/amonetlol/qtile.git "$HOME/.src/qtile"
    cd "$HOME/.src/qtile"
    [[ -f "install_qtile.sh" ]] && chmod +x install_qtile.sh && ./install_qtile.sh
}

polybar_configs() {
    echo_header "Instalando Polybar custom (amonetlol)"
    local dir="$HOME/.src/polybar"
    rm -rf "$dir"
    git clone --depth 1 https://github.com/amonetlol/polybar.git "$dir"
    cd "$dir"
    [[ -f "00-install.sh" ]] && chmod +x 00-install.sh && ./00-install.sh
}

rice() {
    echo_header "Aplicando Rice"
    local zip_script="$HOME/.src/scripts/rice/rice.sh"
    local set_script="$HOME/.src/scripts/rice/set_rice_qtile.sh"
    [[ -f "$zip_script" ]] && chmod +x "$zip_script" "$set_script" 2>/dev/null && "$zip_script" && "$set_script"
}

install_shell_configs() {
    echo_header "Configurações shell"
    link "$HOME/.src/qtile/.bashrc" "$HOME/.bashrc"
    link "$HOME/.src/qtile/.aliases" "$HOME/.aliases"
    link "$HOME/.src/qtile/.aliases-arch" "$HOME/.aliases-arch"
    echo -e "${YELLOW}Dica:${NC} source ~/.bashrc para aplicar agora."
}

feh_wallpaper() {
    echo_header "Configurando wallpaper"
    cat > ~/.fehbg << 'EOF'
#!/bin/env bash
feh --no-fehbg --bg-fill "/home/pio/walls/monokai_pro_blue_arch.png"
EOF
    chmod +x ~/.fehbg
}

# ============= EXECUÇÃO TOLERANTE A FALHAS =============
run_module "Otimizando pacman"               pacman_parallel_downloads
run_module "Debloating GNOME"                debloat_manjaro_gnome
run_module "Instalando pacotes essenciais"   install_packages
run_module "VM Tools"                        vm_tools
run_module "Display Manager"                 display_manager
run_module "Clone Qtile config"              clone_qtile
run_module "Polybar custom"                  polybar_configs
run_module "Aplicando Rice"                  rice
run_module "Shell configs"                   install_shell_configs
run_module "Wallpaper"                       feh_wallpaper

# ============= RESUMO FINAL =============
echo "======================================"
if [[ ${#FAILED_MODULES[@]} -eq 0 ]]; then
    echo -e "${GREEN}Rice concluído com SUCESSO total!${NC}"
else
    echo -e "${YELLOW}Rice concluído com falhas nos seguintes módulos:${NC}"
    printf "   • %s\n" "${FAILED_MODULES[@]}"
    echo -e "${YELLOW}Consulte o log para detalhes: $LOG_FILE${NC}"
fi
echo "======================================"
echo "• Reinicie o sistema para aplicar tudo"
echo "• No login escolha a sessão Qtile"
echo "• source ~/.bashrc para atualizar o shell"
echo "• Se necessário: ~/.src/scripts/rice/set_rice_qtile.sh"
echo "======================================"
