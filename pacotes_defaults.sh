#!/usr/bin/env bash
# =============================================================================
# Script para instalação de pacotes no Arch Linux / Manjaro / EndeavourOS etc
# Uso: 
#   ./pacotes_defaults.sh          → instala tudo (pacotes normais + vm se quiser)
#   ./pacotes_defaults.sh vm       → instala SOMENTE os pacotes de VMware
#   ./pacotes_defaults.sh geral    → instala somente os pacotes gerais 
# =============================================================================

set -euo pipefail

# Cores para saída (opcional mas ajuda bastante)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}→ Iniciando instalação de pacotes...${NC}\n"

# ------------------------------------------------------------------------------
# MÓDULO: pacotes gerais / workflow de terminal moderno
# ------------------------------------------------------------------------------
install_pacotes_gerais() {
    echo -e "${YELLOW}Instalando pacotes gerais / dev / terminal moderno...${NC}"

    local pkgs=(
        # base & ferramentas básicas de compilação
        base-devel

        # shell & navegação melhorada
        starship
        zoxide
        eza
        fd
        ripgrep
        fzf           # muito útil junto com zoxide/ripgrep

        # visualização de disco / sistema
        duf
        fastfetch
        btop
        htop
        neofetch
        screenfetch

        # git & editores
        lazygit
        git
        neovim
        visual-studio-code-bin

        # terminais modernos (escolha 1 ou mais)
        foot
        kitty
        alacritty

        # ferramentas de desenvolvimento / LSP / nvim
        gcc
        luarocks
        jq
        findutils
        coreutils
        bc
        lua51
        python-pipenv
        python-pynvim      # antigo python-neovim → use pynvim
        tree-sitter-cli
        npm
        nodejs

        # utilitários gerais
        wget
        curl
        bash-completion
    )

    sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    
    echo -e "${GREEN}✓ Pacotes gerais instalados${NC}\n"
}

# ------------------------------------------------------------------------------
# MÓDULO: pacotes para máquinas virtuais (VMware / VirtualBox guests)
# ------------------------------------------------------------------------------
install_pacotes_vm() {
    echo -e "${YELLOW}Instalando pacotes para convidado VM (open-vm-tools)...${NC}"

    local vm_pkgs=(
        open-vm-tools
        open-vm-tools-dkms  # caso precise do módulo dkms
        fuse2
        gtkmm3
        # Opcional: se usar virtualbox como guest
        # virtualbox-guest-utils
        # virtualbox-guest-dkms
    )

    sudo pacman -S --needed --noconfirm "${vm_pkgs[@]}"

    # Ativação automática mais comum em VMs VMware
    if systemctl is-active --quiet vmware-vmblock-fuse.service 2>/dev/null; then
        echo -e "${GREEN}→ Ativando serviços open-vm-tools...${NC}"
        sudo systemctl enable --now vmtoolsd.service
        sudo systemctl enable --now vmware-vmblock-fuse.service
    fi

    echo -e "${GREEN}✓ Pacotes de VM instalados${NC}\n"
}

# ------------------------------------------------------------------------------
# Lógica principal
# ------------------------------------------------------------------------------
main() {
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
        echo "  $0                → tudo (pergunta sobre VM)"
        echo "  $0 vm             → somente pacotes de VM"
        echo "  $0 geral          → somente pacotes normais"
        exit 1
    fi

    echo -e "\n${GREEN}Instalação concluída!${NC}"
    echo -e "Execute ${YELLOW}fastfetch${NC} ou ${YELLOW}starship${NC} para ver o resultado.\n"
}

main "$@"



