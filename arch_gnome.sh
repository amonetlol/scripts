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

# ------------- Funções -------------

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

pre_install(){
    echo 'MAKEFLAGS="-j$(nproc)"' | sudo tee -a /etc/makepkg.conf
    sudo pacman -S --needed --noconfirm archlinux-keyring
    sudo pacman -S --needed --noconfirm base-devel
}

aur_helper() {
    # Verifica se o yay já está instalado
    if command -v yay >/dev/null 2>&1; then
        echo "yay já está instalado. Nada a fazer."
        return 0
    fi

    # Cria o diretório de fontes se não existir
    mkdir -p "$HOME/.src"
    cd "$HOME/.src" || return 1

    # Se a pasta yay-bin já existir, remove para garantir um clone limpo
    if [ -d "yay-bin" ]; then
        echo "Pasta yay-bin existente detectada. Removendo para baixar uma versão nova..."
        rm -rf yay-bin
    fi

    # Clone o repositório e instale
    echo "Clonando yay-bin do AUR..."
    git clone https://aur.archlinux.org/yay-bin.git yay-bin || {
        echo "Erro ao clonar o repositório yay-bin."
        return 1
    }

    cd yay-bin || return 1
    echo "Construindo e instalando yay..."
    makepkg --noconfirm -si || {
        echo "Erro durante a compilação/instalação do yay."
        return 1
    }

    echo "yay instalado com sucesso!"
}

speed(){
    sudo pacman -S --needed --noconfirm reflector rsync
    sudo reflector --country Brazil --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
}

debloat(){
 yay -R --noconfirm epiphany decibels malcontent simple-scan snapshot gnome-{calendar,characters,connections,contacts,software,music,remote-desktop,weather,maps} xterm
}


install_apps(){
    if ! pacman -Qi gnome-shell &> /dev/null || ! pacman -Qi gdm &> /dev/null; then
        sudo pacman -S --needed gnome
        sudo systemctl enable gdm
        #echo "GNOME instalado! Reinicie com 'reboot'."
    else
        echo "GNOME já está instalado."
    fi
    
    yay -S --needed --noconfirm power-profiles-daemon linux-zen extension-manager visual-studio-code-bin reflector rsync ttf-jetbrains-mono-nerd \
        firefox wget neovim git kitty xclip wl-clipboard alacritty unzip fastfetch eza duf screenfetch starship btop ripgrep gcc luarocks ripgrep \
        lazygit zip unzip p7zip unrar bat jq gnome-tweaks findutils coreutils bc lua51 python-pipenv python-nvim tree-sitter-cli npm nodejs fd htop  
}

share(){   
    local sharerice="$HOME/.src/scripts/share.sh"

    if [ -f "$sharerice" ]; then
        echo "+x sharerice"
        chmod +x "$sharerice" || echo "Aviso: não conseguiu dar permissão em share.sh"
        echo "sh sharerice"
        sh "$sharerice"
    else
        echo "Aviso: share.sh não encontrado em $sharerice"
    fi
}

hidden_gnome() {
    echo_header "Aplicações ocultas"
    link "$HOME/.src/qtile/local/share/applications" "$HOME/.local/share/applications"

    # Fix Gnome
    rm -rf "$HOME/.local/share/applications/Alacritty.desktop"
    rm -rf "$HOME/.local/share/applications/kitty.desktop"
}

install_shell_configs() {
    echo_header "Configurações do shell (.bashrc + .aliases)"
    # Cria symlink do .bashrc
    link "$HOME/.src/qtile/.bashrc" "$HOME/.bashrc"    
    link "$HOME/.src/qtile/.aliases" "$HOME/.aliases"
    link "$HOME/.src/qtile/.aliases-arch" "$HOME/.aliases-arch"

    echo -e "${YELLOW}Dica:${NC} Rode 'source ~/.bashrc' para aplicar as mudanças agora."
}

gnome_tweaks(){
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

rice(){  
  local zip_in="$HOME/.src/scripts/rice/rice.sh"
  local setrice="$HOME/.src/scripts/rice/set_rice.sh"

  if [ -f "$zip_in" ]; then
        echo "+x zip_in"   
        chmod +x "$zip_in" || echo "Aviso: não conseguiu dar permissão em share.sh"
        echo "sh zip_in"
        sh "$zip_in"
        echo "+x setrice"
        chmod +x "$setrice"
        echo "sh setrice"
        sh "$setrice"
    else
        echo "Aviso: share.sh não encontrado em $zip_in"
    fi
}

pacman_parallel_downloads
pre_install
aur_helper
speed
debloat
install_apps
share
hidden_gnome
install_shell_configs
gnome_tweaks
rice

# -- Conteudo share: --
#share_fonts
#share_nvim
#share_hidden_applications
#share_starship_config
#share_links_configs
#share_ufetch

# -- Conteudo set_rice: --
# Tema: WhiteSur-Dark-solid
# Icone: McMojave-circle-black
# Cursor: Afterglow-Cursors
