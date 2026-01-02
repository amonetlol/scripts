#!/usr/bin/env bash
#set -e

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
enable_contrib_nonfree() {
    echo "Ativando repositórios contrib e non-free..."
    sudo sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
    sudo apt update -qq
}

update_and_upgrade() {
    echo "Atualizando o sistema..."
    sudo apt upgrade -y
}

install_apps() {
    sudo apt install -y \
        wget neovim xclip gcc luarocks lua5.1 python3-pip python3-pynvim \
        tree-sitter-cli npm nodejs fd-find lazygit starship btop ripgrep \
        eza fastfetch duf kitty alacritty htop wl-clipboard gnome-shell-extension-user-theme screenfetch
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

install_flatpak() {
    sudo apt install -y flatpak
    echo "=== Adicionando o repositório Flathub (oficial) ==="
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "=== Instalando o Extension Manager (GNOME Extensions) ==="
    sudo flatpak install -y flathub com.mattjakeman.ExtensionManager
}

# -- Debian Stuffs --
install_firefox() {
    echo "Instalando Firefox estável (Mozilla oficial)..."
    sudo apt remove firefox-esr -y
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | \
        sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
    sudo apt update -qq
    sudo apt install -y firefox
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
    link "$HOME/.src/qtile/.aliases-debian" "$HOME/.aliases-debian"

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
  # ---- Debian 13 ainda não tem perfomance
  #powerprofilesctl set performance
  # ---- Debian 13: é o que tem
  powerprofilesctl set balanced
  
  # -- Desligamento de Tela --
  gsettings set org.gnome.desktop.session idle-delay 0

  # Não tem ainda no Debian 13
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

  # Wallpaper Debian
  gsettings set org.gnome.desktop.background picture-uri "file:///home/pio/walls/monokai_pro_blue_debian.png"
  gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/pio/walls/monokai_pro_blue_debian.png"
}

# -- Debian stuffs --
debian_usertheme(){
  gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
}

# -- Debian Stuffs --
tema_gnome-terminal(){
    sudo apt install dconf-cli uuid-runtime -y
    #Reset total dos perfis (isso remove tudo, mas é o que mais resolve):
    dconf reset -f /org/gnome/terminal/legacy/profiles:/
    echo -e "{GREEN}Temas: ${NC} 94 116 336 240 247"
    bash -c "$(wget -qO- https://git.io/vQgMr)"
}

rice2(){
    echo -e "${YELLOW}Execute o ./rice/rice.sh e set_rice.sh manualmente ${NC}"
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

enable_contrib_nonfree
update_and_upgrade
install_apps
install_vscode
install_flatpak
install_firefox
share
hidden_gnome
install_shell_configs
gnome_tweaks
debian_usertheme
tema_gnome-terminal
rice2

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
