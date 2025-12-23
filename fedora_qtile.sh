#!/bin/bash
set -e

# ==============================================
# Configurações iniciais
# ==============================================

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

# ==============================================
# Funções
# ==============================================

dnf_tweaks() {
    sudo sh -c 'echo "max_parallel_downloads=20" >> /etc/dnf/dnf.conf'
    sudo sh -c 'echo "fastestmirror=True" >> /etc/dnf/dnf.conf'  # opcional, mas recomendado
}

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
        git fedora polkit-gnome pavucontrol  python3-psutil python3-dbus \
        wget neovim git rofi dmenu scrot xclip dunst alsa-utils alacritty picom \
        unzip gcc luarocks maim gnome-calendar mousepad thunar thunar-volman \
        thunar-archive-plugin file-roller gvfs unzip p7zip p7zip-plugins unrar bat \
        xdg-user-dirs xdg-user-dirs-gtk xdotool jq  \
         findutils coreutils bc lua lua-devel python3-pip  \
        tree-sitter-cli npm nodejs fd-find feh qtile qtile-extras \
        open-vm-tools-desktop fuse gtk3-devel lightdm lightdm-gtk  \
         btop ripgrep fastfetch duf kitty htop numlockx xdg-user-dirs --skip-unavailable

    # Alguns pacotes extras úteis que costumam faltar em setups mínimos
    sudo dnf install -y \
        xset xrandr \
        python3-xcffib python3-cairocffi python3-dbus-next  --skip-unavailable

    # FALTA ARRUMAR:
    # xwallpaper imagemagick python3-pynvim lazygit starship
}

install_vscode() {
    echo "Instalando Visual Studio Code (oficial Microsoft)..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    sudo dnf check-update
    sudo dnf install -y code
}

enable_services() {
    echo "Habilitando serviços..."
    sudo systemctl enable vmtoolsd
    sudo systemctl enable lightdm
    # Fedora stuffs
    # 2. Cria o symlink correto para LightDM
    sudo ln -sf /usr/lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service
    # (opicional) Confirma que o target é graphical
    sudo systemctl set-default graphical.target
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

install_starship() {
    sudo curl -sS https://starship.rs/install.sh | sh
}

feh_fedora(){
    feh --bg-fill '/home/pio/walls/monokai_pro_blue_fedora.png'
}

# ==============================================
# Execução principal
# ==============================================
echo "======================================"
echo " Configuração do ambiente - Fedora "
echo "======================================"

dnf_tweaks
install_repo
update_and_upgrade
install_basic_packages
install_vscode
enable_services
clone_qtile
install_shell_configs
install_starship
feh_fedora

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
