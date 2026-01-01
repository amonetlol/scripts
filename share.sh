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

# versão FINAL
global() {
    mkdir -p "$HOME/.src"

    # Detecta a distro via /etc/os-release
    if [ -f /etc/os-release ]; then
        . /etc/os-release  # carrega as variáveis (ID, ID_LIKE, etc.)
    else
        echo "Não foi possível detectar a distribuição (arquivo /etc/os-release ausente)."
        echo "Instalação do git abortada."
        return 1
    fi

    # Verifica se git já está instalado
    if command -v git >/dev/null 2>&1; then
        echo "Git já está instalado."
    else
        echo "Git não encontrado. Tentando instalar..."

        # Determina o gerenciador de pacotes com base em ID ou ID_LIKE
        if [[ "$ID" == "fedora" || "$ID_LIKE" == *"fedora"* || "$ID" == "rhel" || "$ID_LIKE" == *"rhel"* ]]; then
            PKG_MANAGER="dnf"
            INSTALL_CMD="sudo dnf install -y git"
        elif [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"ubuntu"* || "$ID_LIKE" == *"debian"* ]]; then
            PKG_MANAGER="apt"
            # Atualiza a lista de pacotes primeiro (boa prática no apt)
            sudo apt update
            INSTALL_CMD="sudo apt install -y git"
        elif [[ "$ID" == "arch" || "$ID" == "manjaro" || "$ID_LIKE" == *"arch"* ]]; then
            PKG_MANAGER="pacman"
            INSTALL_CMD="sudo pacman -S --noconfirm git"
        else
            echo "Distribuição não suportada automaticamente ($ID)."
            echo "Instale o git manualmente e execute o script novamente."
            return 1
        fi

        echo "Usando $PKG_MANAGER para instalar git..."
        $INSTALL_CMD || {
            echo "Falha ao instalar git com $PKG_MANAGER."
            return 1
        }
        echo "Git instalado com sucesso."
    fi

    # Diretório de destino
    DEST="$HOME/.src/qtile"

    # Remove se já existir
    if [ -d "$DEST" ]; then
        echo "Pasta $DEST já existe. Removendo..."
        rm -rf "$DEST"
    fi

    # Cria o diretório pai (já feito no início, mas não custa garantir)
    mkdir -p "$(dirname "$DEST")"

    # Clona o repositório
    echo "Clonando Qtile para $DEST..."
    git clone https://github.com/amonetlol/qtile.git "$DEST" || {
        echo "Falha ao clonar o repositório. Verifique sua conexão ou instalação do git."
        return 1
    }

    echo "Concluído!"
}

global
DOTFILES_DIR="$HOME/.src/qtile"

# ------------- Funções -------------

share_fonts() {
    echo_header "Instalação de fontes"
    if [[ -d "$HOME/.fonts" && -d "$HOME/.fonts/.git" ]]; then
        echo -e "${YELLOW}Atualizando fontes existentes...${NC}"
        git -C "$HOME/.fonts" pull
    else
        if [[ -d "$HOME/.fonts" ]]; then
            mv "$HOME/.fonts" "$HOME/.fonts.bak.$(date +%Y%m%d_%H%M%S)"
        fi
        git clone https://github.com/amonetlol/fonts "$HOME/.fonts"
    fi
    fc-cache -vf
    echo -e "${GREEN}Cache de fontes atualizado${NC}"
}

share_nvim() {
    echo_header "AstroNvim (template limpo)"
    rm -rf ~/.config/nvim
    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
    rm -rf ~/.config/nvim/.git
    echo "AstroNvim clonado. Abra o nvim para finalizar a instalação inicial."
}

share_hidden_applications() {
    echo_header "Aplicações ocultas"
    link "$HOME/.src/qtile/local/share/applications" "$HOME/.local/share/applications"

    # # Fix Gnome
    # rm -rf "$HOME/.local/share/applications/Alacritty.desktop"
    # rm -rf "$HOME/.local/share/applications/kitty.desktop"
}

share_starship_config() {
    echo_header "Starship prompt"
    link "$HOME/.src/qtile/config/starship.toml" "$HOME/.config/starship.toml"
}

share_links_configs(){
    link "$HOME/.src/qtile/config/kitty" "$HOME/.config/kitty"
    link "$HOME/.src/qtile/config/fastfetch" "$HOME/.config/fastfetch"
    link "$HOME/.src/qtile/config/alacritty" "$HOME/.config/alacritty"
    link "$HOME/.src/qtile/config/neofetch" "$HOME/.config/neofetch"
    link "$HOME/.src/qtile/config/qtile/walls" "$HOME/walls"

    # Bin
    link "$HOME/.src/qtile/bin" "$HOME/.bin"
    cd "$HOME/.bin" && chmod +x *
}

share_ufetch(){
  ~/.bin/get_ufetch
}

share_fonts
share_nvim
share_hidden_applications
share_starship_config
share_links_configs
share_ufetch

