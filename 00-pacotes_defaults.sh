#!/usr/bin/env bash
# =============================================================================
# Script para instalação de pacotes no Arch Linux / Manjaro / EndeavourOS etc
# Agora com suporte a AUR via yay (instala yay-bin automaticamente se necessário)
# =============================================================================
set -euo pipefail

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}→ Iniciando instalação de pacotes...${NC}\n"

# ------------------------------------------------------------------------------
# Função: Instalar yay se não estiver presente (usa yay-bin do AUR)
# ------------------------------------------------------------------------------
install_yay_if_needed() {
    if command -v yay &> /dev/null; then
        echo -e "${GREEN}✓ yay já está instalado${NC}"
        return 0
    fi

    echo -e "${YELLOW}yay não encontrado. Instalando yay-bin (AUR)...${NC}"

    # Instala dependências básicas necessárias para compilar/instalar do AUR
    sudo pacman -S --needed --noconfirm base-devel git

    # Diretório temporário limpo
    local tmpdir="/tmp/yay-install-$(date +%s)"
    mkdir -p "$tmpdir"
    cd "$tmpdir"

    # Clona yay-bin (binário pré-compilado → mais rápido e sem compilar Go)
    git clone https://aur.archlinux.org/yay-bin.git .
    
    # Build e instala sem interação (assume sim para todas as perguntas)
    makepkg -si --noconfirm --needed

    cd - >/dev/null
    rm -rf "$tmpdir"

    if command -v yay &> /dev/null; then
        echo -e "${GREEN}✓ yay-bin instalado com sucesso!${NC}\n"
    else
        echo -e "${RED}Erro: falha ao instalar yay. Instale manualmente.${NC}"
        echo "Tente: git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si"
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# MÓDULO: pacotes gerais (agora usando yay para suportar AUR como visual-studio-code-bin)
# ------------------------------------------------------------------------------
install_pacotes_gerais() {
    echo -e "${YELLOW}Instalando pacotes gerais / dev / terminal moderno...${NC}"

    local pkgs=(
        base-devel
        starship
        zoxide
        eza
        fd
        ripgrep
        fzf
        duf
        fastfetch
        btop
        htop
        neofetch
        screenfetch
        lazygit
        git
        neovim
        visual-studio-code-bin      # ← AUR
        foot
        kitty
        alacritty
        gcc
        luarocks
        jq
        findutils
        coreutils
        bc
        lua51
        python-pipenv
        python-pynvim
        tree-sitter-cli
        npm
        nodejs
        wget
        curl
        bash-completion
    )

    # Usa yay para instalar tudo (pacman + AUR) de uma vez
    yay -S --needed --noconfirm "${pkgs[@]}"

    echo -e "${GREEN}✓ Pacotes gerais instalados${NC}\n"
}

# ------------------------------------------------------------------------------
# MÓDULO: pacotes para máquinas virtuais (VMware / VirtualBox guests)
# ------------------------------------------------------------------------------
install_pacotes_vm() {
    echo -e "${YELLOW}Instalando pacotes para convidado VM...${NC}"

    local vm_pkgs=(
        open-vm-tools
        fuse2
        gtkmm3
        #open-vm-tools-dkms
        # Opcional: descomente se usar VirtualBox como guest
        # virtualbox-guest-utils
        # virtualbox-guest-dkms
    )

    yay -S --needed --noconfirm "${vm_pkgs[@]}"

    # Ativação automática (VMware guest comum)
    if systemctl is-active --quiet vmware-vmblock-fuse.service 2>/dev/null; then
        echo -e "${GREEN}→ Ativando serviços open-vm-tools...${NC}"
        sudo systemctl enable --now vmtoolsd.service vmware-vmblock-fuse.service
    fi

    echo -e "${GREEN}✓ Pacotes de VM instalados${NC}\n"
}

# ------------------------------------------------------------------------------
# Lógica principal
# ------------------------------------------------------------------------------
main() {
    # Primeiro: garante que yay está disponível
    install_yay_if_needed

    if [[ $# -eq 0 ]]; then
        # Sem argumentos → instala tudo
        install_pacotes_gerais
        read -p "Deseja instalar também os pacotes para VM? (s/N): " resp
        if [[ "${resp,,}" =~ ^(s|sim|y|yes)$ ]]; then
            install_pacotes_vm
        fi
    elif [[ "$1" == "vm" ]]; then
        install_pacotes_vm
    elif [[ "$1" == "geral" || "$1" == "normal" ]]; then
        install_pacotes_gerais
    else
        echo -e "${RED}Uso:${NC}"
        echo "  $0               → tudo (pergunta sobre VM)"
        echo "  $0 vm            → somente pacotes de VM"
        echo "  $0 geral         → somente pacotes normais"
        exit 1
    fi

    echo -e "\n${GREEN}Instalação concluída!${NC}"
    echo -e "Execute ${YELLOW}fastfetch${NC} ou ${YELLOW}starship${NC} para ver o resultado.\n"
    echo -e "Dica: agora você pode usar ${YELLOW}yay${NC} para instalar qualquer pacote do AUR!"
}

main "$@"
