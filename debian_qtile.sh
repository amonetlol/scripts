#!/bin/bash

set -e  # Para o script em caso de erro

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
        eza fastfetch duf kitty htop
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

install_sddm_sugar_dark() {
    echo "Instalando SDDM com tema Sugar Dark..."
    sudo apt install -y sddm
    sudo systemctl enable sddm
    sudo mkdir -p /usr/share/sddm/themes
    sudo git clone --depth 1 https://github.com/MarianArlt/sddm-sugar-dark.git /usr/share/sddm/themes/sugar-dark
    sudo sh -c 'echo "[Theme]\nCurrent=sugar-dark" > /etc/sddm.conf'
}

install_qtile() {
    local qtile_dir="$HOME/.src/qtile"
    local repo_url="https://github.com/amonetlol/qtile.git"
    local post_install_script="$qtile_dir/pos_install.sh"

    echo "→ Iniciando instalação/configuração do qtile (amonetlol fork)"

    # 1. Cria diretório base se não existir
    mkdir -p "$HOME/.src" || {
        echo "Erro ao criar diretório ~/.src"
        return 1
    }

    # 2. Verifica se já existe o repositório
    if [ -d "$qtile_dir" ] && [ -d "$qtile_dir/.git" ]; then
        echo "Diretório $qtile_dir já existe. Tentando atualizar..."
        cd "$qtile_dir" || return 1
        git fetch --all
        git reset --hard origin/main  # ou master/main — ajuste conforme o branch principal
        git clean -fd
        echo "Repositório atualizado."
    else
        # 3. Clona o repositório caso não exista
        echo "Clonando qtile (amonetlol fork) → $qtile_dir"
        git clone "$repo_url" "$qtile_dir" || {
            echo "Falha ao clonar repositório"
            return 1
        }
        cd "$qtile_dir" || return 1
    fi

    # 4. Dá permissão de execução no script de pós-instalação
    if [ -f "$post_install_script" ]; then
        chmod +x "$post_install_script" || {
            echo "Não conseguiu dar permissão de execução em $post_install_script"
            return 1
        }
    else
        echo "Aviso: script pos_install.sh não encontrado em $qtile_dir"
        echo "Continuando mesmo assim..."
    fi

    # 5. Abre o script no neovim
    if [ -f "$post_install_script" ]; then
        echo "Abrindo pos_install.sh no neovim..."
        nvim "$post_install_script"
    else
        echo "Não foi possível abrir pos_install.sh (arquivo não existe)"
        echo "Você pode editar manualmente depois: $post_install_script"
    fi
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
#install_jetbrains_mono_nerd_font
#install_sddm_sugar_dark
install_qtile

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
