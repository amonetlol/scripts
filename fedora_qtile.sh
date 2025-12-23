#!/bin/bash
set -e

# ==============================================
# Configurações iniciais
# ==============================================

# Habilitar download paralelo (20 downloads simultâneos)
# Isso acelera bastante as instalações grandes
sudo sh -c 'echo "max_parallel_downloads=20" >> /etc/dnf/dnf.conf'
sudo sh -c 'echo "fastestmirror=True" >> /etc/dnf/dnf.conf'  # opcional, mas recomendado

# ==============================================
# Funções
# ==============================================

install_repo(){
    sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

update_and_upgrade() {
    echo "Atualizando o sistema (Fedora)..."
    sudo dnf upgrade --refresh -y
}

install_basic_packages() {
    echo "Instalando pacotes básicos para ambiente Qtile..."
    sudo dnf install -y \
        polkit-gnome pavucontrol xorg-x11-server-utils python3-psutil python3-dbus \
        wget neovim git rofi dmenu scrot xclip dunst alsa-utils alacritty picom \
        unzip gcc luarocks maim gnome-calendar mousepad thunar thunar-volman \
        thunar-archive-plugin file-roller gvfs unzip p7zip p7zip-plugins unrar bat \
        xdg-user-dirs xdg-user-dirs-gtk xdotool jq xwallpaper \
        imagemagick findutils coreutils bc lua lua-devel python3-pip python3-pynvim \
        tree-sitter-cli npm nodejs fd-find feh qtile qtile-extras \
        open-vm-tools-desktop fuse gtk3-devel lightdm lightdm-gtk greeter \
        lazygit starship btop ripgrep eza fastfetch duf kitty htop numlockx

    # Alguns pacotes extras úteis que costumam faltar em setups mínimos
    sudo dnf install -y \
        xset xrandr \
        python3-xcffib python3-cairocffi python3-dbus-next
}

install_firefox_official() {
    echo "Instalando Firefox oficial (Mozilla) via COPR..."
    sudo dnf copr enable -y thunderbird-team/ppa
    sudo dnf install -y firefox
}

install_vscode() {
    echo "Instalando Visual Studio Code (oficial Microsoft)..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf check-update
    sudo dnf install -y code
}

enable_services() {
    echo "Habilitando serviços..."
    # open-vm-tools (se for VM)
    sudo systemctl enable vmtoolsd 2>/dev/null || true
    # LightDM
    sudo systemctl enable lightdm
}

install_jetbrains_mono_nerd_font() {
    echo "Instalando JetBrains Mono Nerd Font..."
    mkdir -p ~/.local/share/fonts
    wget -q -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
    cd ~/.local/share/fonts
    unzip -q JetBrainsMono.zip
    rm JetBrainsMono.zip
    fc-cache -fv
    cd - >/dev/null
}

install_qtile() {
    mkdir -p "$HOME/.src"
    local qtile_dir="$HOME/.src/qtile"
    local repo_url="https://github.com/amonetlol/qtile.git"
    local post_install_script="$qtile_dir/pos_install.sh"

    echo "→ Iniciando instalação/configuração do qtile (amonetlol fork)"

    mkdir -p "$HOME/.src" || { echo "Erro ao criar ~/.src"; return 1; }

    if [ -d "$qtile_dir" ] && [ -d "$qtile_dir/.git" ]; then
        echo "Diretório $qtile_dir já existe. Atualizando..."
        cd "$qtile_dir" || return 1
        git fetch --all
        git reset --hard origin/main
        git clean -fd
        echo "Repositório atualizado."
    else
        echo "Clonando qtile (amonetlol fork) → $qtile_dir"
        git clone "$repo_url" "$qtile_dir" || { echo "Falha ao clonar"; return 1; }
        cd "$qtile_dir" || return 1
    fi

    if [ -f "$post_install_script" ]; then
        chmod +x "$post_install_script" || echo "Aviso: não conseguiu dar permissão em pos_install.sh"
    else
        echo "Aviso: pos_install.sh não encontrado em $qtile_dir"
    fi

    if [ -f "$post_install_script" ]; then
        echo "Abrindo pos_install.sh no neovim..."
        nvim "$post_install_script"
    else
        echo "pos_install.sh não encontrado. Edite manualmente depois:"
        echo "   $post_install_script"
    fi    
}

# ==============================================
# Execução principal
# ==============================================
echo "======================================"
echo " Configuração do ambiente - Fedora "
echo "======================================"

install_repo
update_and_upgrade
install_basic_packages
install_vscode
#install_firefox_official         # descomente se quiser o Firefox oficial via COPR
enable_services
#install_jetbrains_mono_nerd_font # descomente se quiser a fonte agora
#install_sddm_sugar_dark          # não recomendado para Fedora + Qtile (LightDM é mais usado)
install_qtile

echo
echo "======================================"
echo " Configuração concluída! "
echo "======================================"
echo
echo "Sugestões finais:"
echo "• Reinicie o sistema: sudo reboot"
echo "• Selecione a sessão 'Qtile' na tela de login do LightDM"
echo "• Para aplicar PATH novo imediatamente: source ~/.bashrc"
echo "• Verifique se o lightdm está funcionando: systemctl status lightdm"
echo "• Se quiser trocar para SDDM, use: sudo dnf install sddm && sudo systemctl enable sddm -f"
echo
