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
dnf_tweaks() {
    sudo sh -c 'echo "max_parallel_downloads=20" >> /etc/dnf/dnf.conf'
    sudo sh -c 'echo "fastestmirror=True" >> /etc/dnf/dnf.conf'  # opcional, mas recomendado
}

install_repo() {
    # Verifica se os repositórios RPM Fusion já estão presentes na lista
    if dnf repolist | grep -q "rpmfusion-free\|rpmfusion-nonfree"; then
        echo "RPM Fusion (free e/ou nonfree) já está habilitado."
    else
        echo "Habilitando RPM Fusion free e nonfree..."
        sudo dnf install -y \
            https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    fi

    # Verificação final (opcional, mas útil para debug)
    # echo "Repositórios RPM Fusion atuais:"
    # dnf repolist | grep rpmfusion || echo "Nenhum repositório RPM Fusion encontrado."
}

install_repo_extra() {
    # Verifica se os sub-repositórios já estão presentes
    if dnf repolist | grep -q "rpmfusion-nonfree-nvidia-driver\|rpmfusion-nonfree-steam"; then
        echo "Sub-repositórios RPM Fusion Nonfree (NVIDIA e/ou Steam) já estão habilitados."
    else
        echo "Habilitando sub-repositórios RPM Fusion Nonfree para NVIDIA drivers e Steam..."
        sudo dnf install -y \
            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        
        # Atualiza metadados após adicionar o nonfree principal
        sudo dnf makecache
        
        # Agora instala os branches específicos (eles configuram os sub-repos)
        sudo dnf install -y \
            rpmfusion-nonfree-nvidia-driver \
            rpmfusion-nonfree-steam
    fi

    # Verificação final
    # echo "Repositórios RPM Fusion Nonfree atuais (branches):"
    # dnf repolist | grep "rpmfusion-nonfree" || echo "Nenhum sub-repositório Nonfree encontrado."
}

disable_repo_extra() {
    # Verifica se os branches estão habilitados
    if dnf repolist --enabled | grep -q "rpmfusion-nonfree-nvidia-driver\|rpmfusion-nonfree-steam"; then
        
        echo "Desativando sub-repositórios RPM Fusion Nonfree (NVIDIA e/ou Steam)..."
        
        # Desativa via setopt (DNF5)
        sudo dnf config-manager setopt \
            rpmfusion-nonfree-nvidia-driver.enabled=0 \
            rpmfusion-nonfree-steam.enabled=0
        
        # Remove os pacotes que criam os branches (opcional, mas recomendado para limpeza total)
        sudo dnf remove -y rpmfusion-nonfree-nvidia-driver rpmfusion-nonfree-steam
        
        # Atualiza metadados
        sudo dnf makecache
        
        echo "Sub-repositórios desativados com sucesso."
    else
        echo "Sub-repositórios RPM Fusion Nonfree (NVIDIA e Steam) já estão desativados ou não foram encontrados."
    fi

    # Verificação final
    # echo "Repositórios RPM Fusion Nonfree ativos:"
    # dnf repolist --enabled | grep "rpmfusion-nonfree" || echo "Nenhum ativo encontrado."
}

debloat(){
  sudo dnf remove gnome-contacts gnome-weather gnome-maps simple-scan snapshot gnome-boxes gnome-characters gnome-calendar decibels mediawriter libreoffice* gnome-remote-desktop gnome-connections -y

  sudo dnf autoremove -y
  sudo dnf clean all
}

update_and_upgrade() {
    echo "Atualizando o sistema (Fedora)..."
    sudo dnf upgrade --refresh -y
}

install_basic_packages() {
    echo "Instalando pacotes básicos para ambiente Qtile..."
    sudo dnf install -y \
        git wget neovim xclip alacritty luarocks bat jq findutils bc lua lua-devel python3-pip wl-clipboard \
        tree-sitter-cli npm nodejs python3-neovim fd-find btop htop ripgrep fastfetch duf coreutils kitty gnome-tweaks screenfetch --skip-unavailable

    # Falta: lazygit starship
}

install_vscode() {
    echo "Instalando Visual Studio Code (oficial Microsoft)..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    sudo dnf check-update
    sudo dnf install -y code
}

install_flatpak() {
    sudo dnf install -y flatpak
    echo "=== Adicionando o repositório Flathub (oficial) ==="
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "=== Instalando o Extension Manager (GNOME Extensions) ==="
    sudo flatpak install -y flathub com.mattjakeman.ExtensionManager
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

install_starship() {
    sudo curl -sS https://starship.rs/install.sh | sh
}

install_shell_configs() {
    echo_header "Configurações do shell (.bashrc + .aliases)"
    # Cria symlink do .bashrc
    link "$HOME/.src/qtile/.bashrc" "$HOME/.bashrc"    
    link "$HOME/.src/qtile/.aliases" "$HOME/.aliases"
    link "$HOME/.src/qtile/.aliases-fedora" "$HOME/.aliases-fedora"

    # 1. Instalar o plugin do DNF para gerenciar repositórios COPR
    sudo dnf install -y 'dnf-command(copr)'
    # 2. Habilitar o repositório COPR específico para o eza
    echo "--- Habilitando repositório COPR (alternateved/eza) ---"
    sudo dnf copr enable -y alternateved/eza
    # 3. Instalar o eza
    echo "--- Instalando o eza ---"
    sudo dnf install -y eza
    
    echo -e "${YELLOW}Dica:${NC} Rode 'source ~/.bashrc' para aplicar as mudanças agora."
}

gnome_tweaks(){
  # -- Button --
  gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

  # -- Plano de energia --
  tuned-adm profile virtual-guest # Para VM
  # tuned-adm profile throughput-performance # Desempenho
  
  # -- Desligamento de Tela --
  gsettings set org.gnome.desktop.session idle-delay 0

  #Doar Gnome:
  gsettings set org.gnome.settings-daemon.plugins.housekeeping donation-reminder-enabled false

  #Super + Q = close app
  gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"

  # Atalhos: Kitty e Alacritty
  # Primeiro: Alacritty com Shift+Super+Enter
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Alacritty'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'alacritty'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Shift><Super>Return'

  # Segundo: Kitty com Super+Enter
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Kitty'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'kitty'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>Return'

  # Ativa a lista de atalhos personalizados
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"

  #Wallpaper Fedora
  gsettings set org.gnome.desktop.background picture-uri "file:///home/pio/walls/monokai_pro_blue_fedora.png"
  gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/pio/walls/monokai_pro_blue_fedora.png"
}

rice(){  
  local zip_in="$HOME/.src/scripts/rice/rice.sh"
  local setrice="$_dir/set_rice.sh"

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

dnf_tweaks
install_repo
#install_repo_extra #Nvidia
#disable_repo_extra #Nvidia
debloat
update_and_upgrade
install_basic_packages
install_vscode
install_flatpak
share #share Configs
hidden_gnome
install_starship
install_shell_configs
gnome_tweaks
rice

