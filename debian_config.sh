#!/bin/bash

set -e  # Para o script em caso de erro

echo "Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y

echo "Adicionando usuário 'pio' ao grupo sudo (se existir)..."
if id "pio" &>/dev/null; then
    sudo usermod -aG sudo pio
    echo "Usuário pio adicionado ao sudo."
else
    echo "Aviso: Usuário 'pio' não existe. Crie-o primeiro."
fi

echo "Instalando pacotes básicos do Debian..."
sudo apt install -y \
    policykit-1-gnome \
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
    unrar \
    bat \
    nwg-look \
    xdg-user-dirs \
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
    sddm

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

echo "Instalando Kitty (terminal) via curl..."
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

echo "Instalando JetBrains Mono Nerd Font..."
mkdir -p ~/.local/share/fonts
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
cd ~/.local/share/fonts
unzip JetBrainsMono.zip
rm JetBrainsMono.zip
fc-cache -fv
cd -

echo "Instalando tema SDDM Sugar Dark..."
sudo mkdir -p /usr/share/sddm/themes
sudo git clone https://github.com/MarianArlt/sddm-sugar-dark.git /usr/share/sddm/themes/sugar-dark
sudo sh -c 'echo "[Theme]\nCurrent=sugar-dark" > /etc/sddm.conf.d/theme.conf'

echo "Instalando ferramentas via Cargo (Rust) - isso pode demorar..."
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi
cargo install --locked lazygit starship btop ripgrep eza duf fastfetch

echo "Adicionando ~/.cargo/bin ao PATH no ~/.bashrc..."
if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc; then
    echo '' >> ~/.bashrc
    echo '# Adicionado pelo script de configuração - ferramentas Rust/Cargo' >> ~/.bashrc
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    echo "PATH atualizado em ~/.bashrc"
else
    echo "PATH já estava configurado no ~/.bashrc"
fi

echo "Configuração concluída!"
echo "Reinicie o sistema para aplicar o SDDM com tema Sugar Dark."
echo "Para aplicar o novo PATH imediatamente no terminal atual, execute: source ~/.bashrc"
