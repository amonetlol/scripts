#!/bin/bash

set -e  # Para o script em caso de erro

echo "Ativando repositórios contrib e non-free (necessário para unrar e outros)..."
sudo sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
sudo apt update

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

echo "Atualizando o sistema..."
sudo apt upgrade -y

# echo "Adicionando usuário 'pio' ao grupo sudo (se existir)..."
# if id "pio" &>/dev/null; then
#     sudo usermod -aG sudo pio
#     echo "Usuário pio adicionado ao sudo."
# else
#     echo "Aviso: Usuário 'pio' não existe. Crie-o primeiro."
# fi

echo "Instalando pacotes básicos do Debian..."
sudo apt install -y \
    mate-polkit \
    pavucontrol \
    x11-xserver-utils \
    python3-psutil \
    python3-dbus \
    wget \
    neovim \
    git \
    rofi \
    dmenu \
    scrot \
    xclip \
    dunst \
    alsa-utils \
    alacritty \
    picom \
    unzip \
    gcc \
    luarocks \
    maim \
    loupe \
    mousepad \
    numlockx \
    thunar \
    thunar-volman \
    thunar-archive-plugin \
    file-roller \
    gvfs \
    zip \
    p7zip-full \
    unrar-free \
    bat \
    nwg-look \
    xdg-user-dirs \
    xdg-user-dirs-gtk \
    xdotool \
    jq \
    xxhash \
    xwallpaper \
    imagemagick \
    findutils \
    coreutils \
    bc \
    lua5.1 \
    python3-pip \
    python3-pynvim \
    tree-sitter-cli \
    npm \
    nodejs \
    fd-find \
    feh \
    qtile \
    open-vm-tools-desktop \
    fuse \
    libgtk-3-dev \
    sddm \
    lazygit
    starship \
    btop \
    ripgrep \
    eza \
    fastfetch \
    duf \
    kitty

echo "Instalando Firefox estável (versão oficial Mozilla, não ESR)..."
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
sudo apt update
sudo apt install -y firefox

echo "Habilitando serviços..."
sudo systemctl enable vmtoolsd
sudo systemctl enable sddm

echo "Instalando Visual Studio Code (repo oficial Microsoft)..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt update
sudo apt install -y code

# echo "Instalando JetBrains Mono Nerd Font..."
# mkdir -p ~/.local/share/fonts
# wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
# cd ~/.local/share/fonts
# unzip JetBrainsMono.zip
# rm JetBrainsMono.zip
# fc-cache -fv
# cd -

# echo "Instalando tema SDDM Sugar Dark..."
# sudo mkdir -p /usr/share/sddm/themes
# sudo git clone https://github.com/MarianArlt/sddm-sugar-dark.git /usr/share/sddm/themes/sugar-dark
# sudo sh -c 'echo "[Theme]\nCurrent=sugar-dark" > /etc/sddm.conf'

echo "Configuração concluída!"
echo "Reinicie o sistema para aplicar o SDDM com tema Sugar Dark e testar o mate-polkit (diálogos de senha sudo)."
echo "Para aplicar o novo PATH imediatamente no terminal atual, execute: source ~/.bashrc"
echo "Se preferir outro agente Polkit (ex: lxqt-policykit ou lxpolkit), instale manualmente e remova mate-polkit."
