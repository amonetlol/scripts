#!/usr/bin/env bash
#set -e

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

echo_header() { echo -e "\n${GREEN}===== $1 =====${NC}"; }

# ------------- Funções -------------

# Final
pacman_parallel_downloads() {
    echo_header "Pacman.conf Stuffs..."
    echo_header "Otimizando pacman"
    sudo sed -i -e '/^ParallelDownloads/s/^/#/' -e '/^#ParallelDownloads/a ParallelDownloads = 25' \
            -e 's/^#Color$/Color/' \
            -e '/^Color/a ILoveCandy' \
            /etc/pacman.conf
}

pre_install(){
    echo_header "Pre install...."
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

install_apps(){
    echo_header "Checando se Gnome esta instalado...."
    if ! pacman -Qi gnome-shell &> /dev/null || ! pacman -Qi gdm &> /dev/null; then
        sudo pacman -S --needed --noconfirm gnome 
        sudo systemctl enable gdm
        #echo "GNOME instalado! Reinicie com 'reboot'."
    else
        echo "GNOME já está instalado."
    fi

    aur_helper
    echo_header "Instalando Apps..."
    yay -S --needed --noconfirm power-profiles-daemon extension-manager visual-studio-code-bin reflector rsync ttf-jetbrains-mono-nerd \
        firefox wget neovim git kitty xclip wl-clipboard alacritty fastfetch eza duf screenfetch starship btop ripgrep gcc luarocks ripgrep \
        lazygit zip unzip p7zip unrar bat jq gnome-tweaks findutils coreutils bc lua51 python-pipenv python-nvim tree-sitter-cli npm nodejs fd htop screenfetch catfish    
}

share() {
    echo_header "Share..."
    local script="$HOME/.src/scripts/share.sh"

    [[ -f "$script" ]] || { echo "Aviso: share.sh não encontrado em $script"; return 1; }
    [[ -x "$script" ]] || chmod +x "$script"  # só tenta chmod se não for executável

    "$script"  # executa diretamente, mais rápido e seguro que 'sh'
}

debloat(){
    echo_header "Debloat..."
    yay -R --noconfirm gnome-music decibels gnome-weather gnome-calendar gnome-firmware malcontent micro
}

vm_tools() {
    echo_header "VM Tools"
    pacman -Qs open-vm-tools >/dev/null && { echo "VM Tools já instalado."; return; }
    yay -S --needed --noconfirm open-vm-tools fuse2 gtkmm3
    sudo systemctl enable --now vmtoolsd
}

hidden_gnome() {
    echo_header "Aplicações ocultas"
    link "$HOME/.src/qtile/local/share/applications" "$HOME/.local/share/applications"

    # Fix Gnome
    rm -rf "$HOME/.local/share/applications/Alacritty.desktop"
    rm -rf "$HOME/.local/share/applications/kitty.desktop"
}

install_shell_configs() {
    echo_header "Configurações shell"
    link "$HOME/.src/qtile/.bashrc" "$HOME/.bashrc"
    link "$HOME/.src/qtile/.aliases" "$HOME/.aliases"
    link "$HOME/.src/qtile/.aliases-arch" "$HOME/.aliases-arch"  # Adaptado para Manjaro/Arch
    echo -e "${YELLOW}Dica:${NC} source ~/.bashrc para aplicar."
}

gnome_tweaks(){
    echo_header "Gnome Tewaks..."
  # -- Button --
  gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

  # -- Plano de energia --
  # ----- Tuned-adm :: Fedora e mais novos
  # tuned-adm list  ## lista os planos disponiveis
  # tuned-adm profile virtual-guest # Para VM
  #tuned-adm profile throughput-performance # Desempenho
  # ---- Performance não é instalado
  #powerprofilesctl set performance
  # ---- Arch
  powerprofilesctl set balanced
  
  # -- Desligamento de Tela --
  gsettings set org.gnome.desktop.session idle-delay 0

  # Doar Gnome:
  # gsettings set org.gnome.settings-daemon.plugins.housekeeping donation-reminder-enabled false

  # Super + Q = close app
  gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"

  # Atalhos: Kitty / Alacritty / Firefox
  # Primeiro: Alacritty com Shift+Super+Enter
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Alacritty'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'alacritty'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Shift><Super>Return'

  # Segundo: Kitty com Super+Enter
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Kitty'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'kitty'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>Return'

  # Terceiro: Firefox com Super+W
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'Firefox'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'firefox'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Super>W'

  # Ativa a lista de atalhos personalizados
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']"

  # Wallpaper Arch
  gsettings set org.gnome.desktop.background picture-uri "file:///home/pio/walls/monokai_pro_blue_arch.png"
  gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/pio/walls/monokai_pro_blue_arch.png"
}

rice() {
    echo_header "Aplicando Rice"
    local zip_script="$HOME/.src/scripts/rice/rice.sh"
    local set_script="$HOME/.src/scripts/rice/set_rice_qtile.sh"
    [[ -f "$zip_script" ]] && chmod +x "$zip_script" "$set_script" && "$zip_script" && "$set_script"
}

clean_lixo() {
    echo_header "Limpando o sistema..."
    sudo pacman -Scc --noconfirm  # Limpa cache para velocidade
    yay -Scc --noconfirm
}

fix_manjaro() {
    echo_header "Fix bash"
    chsh -s /bin/bash
}

bye(){
    echo -e "${YELLOW}Reboot o sistema. BYE${NC}"
}

pacman_parallel_downloads
pre_install
aur_helper
install_apps
#debloat
share
vm_tools
hidden_gnome
install_shell_configs
gnome_tweaks
rice
clean_lixo
fix_manjaro
bye

# -- Conteudo share: --
#share_fonts
#share_nvim
#share_hidden_applications
#share_starship_config
#share_links_configs
#share_ufetch
#share_nvim_root

# -- Conteudo set_rice: --
# Tema: WhiteSur-Dark-solid
# Icone: McMojave-circle-black
# Cursor: Afterglow-Cursors
