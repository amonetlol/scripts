#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Garantir privilégios de root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Erro: Execute este script como root (sudo).${NC}"
    exit 1
fi

echo -e "${GREEN}=== Iniciando Debloat otimizado do Mageia GNOME ===${NC}"

# === 1. Jogos GNOME e outros jogos ===
GAMES=(
    task-games
    quadrapassel gnome-mahjongg iagno aisleriot gnome-chess gnome-mines
    gnome-sudoku gnome-robots gnome-nibbles gnome-klotski gnome-taquin
    lightsoff hitori tali four-in-a-row five-or-more swell-foop gnome-2048
    gnome-tetravex gnuchess
)

# === 2. Aplicativos multimídia e comunicação (bloat comum) ===
BLOAT_APPS=(
    evolution pidgin hexchat empathy brasero
    gnome-maps gnome-weather gnome-contacts gnome-clocks
    gnome-music gnome-documents rhythmbox sound-juicer
    cheese gnome-sound-recorder pan epiphany polari gnome-calendar
    transmission-common transmission-gtk transmission-qt
)

# === 3. Editores e ferramentas gráficas extras ===
GRAPHICS_EDITORS=(
    gimp inkscape dia scribus pitivi
    gnome-multi-writer photorec vinagre
)

# === 4. Outros utilitários e pacotes Mageia extras ===
MAGEIA_EXTRAS=(
    bijiben dasher dconf-editor homebank planner filezilla
    # emacs e derivados removidos se desejar (cuidado, pode afetar dependências)
    # emacs-common
)

# === 5. LibreOffice completo (mantenha se quiser apenas alguns módulos) ===
LIBREOFFICE=(
    libreoffice-*
)

# === 6. Seção OPCIONAL: Suporte a impressão e scanner (descomente para ativar) ===
# PRINTING=(
#     cups cups-filters system-config-printer sane-backends
#     simple-scan xsane task-printing-server task-printing-hp
# )

# Função para remover pacotes com verificação
remove_packages() {
    local packages=("$@")
    local to_remove=()

    for pkg in "${packages[@]}"; do
        if rpm -q "$pkg" &>/dev/null; then
            to_remove+=("$pkg")
        fi
    done

    if [ ${#to_remove[@]} -eq 0 ]; then
        echo -e "${YELLOW}Nenhum pacote para remover nesta categoria.${NC}"
        return
    fi

    echo -e "Removendo: ${to_remove[*]}"
    dnf remove -y "${to_remove[@]}"
}

# Execução das remoções
echo -e "${GREEN}1. Removendo jogos...${NC}"
remove_packages "${GAMES[@]}"

echo -e "${GREEN}2. Removendo aplicativos multimídia/comunicação...${NC}"
remove_packages "${BLOAT_APPS[@]}"

echo -e "${GREEN}3. Removendo editores gráficos...${NC}"
remove_packages "${GRAPHICS_EDITORS[@]}"

echo -e "${GREEN}4. Removendo extras Mageia...${NC}"
remove_packages "${MAGEIA_EXTRAS[@]}"

echo -e "${GREEN}5. Removendo LibreOffice completo...${NC}"
remove_packages "${LIBREOFFICE[@]}"

# Descomente a linha abaixo se quiser remover impressão/scanner
# echo -e "${GREEN}6. Removendo suporte a impressão/scanner...${NC}"
# remove_packages "${PRINTING[@]}"

# === Limpeza final ===
echo -e "${GREEN}Limpando dependências órfãs e cache...${NC}"
dnf autoremove -y
dnf clean all

echo -e "${GREEN}=== Debloat concluído com sucesso! ===${NC}"
echo -e "${YELLOW}Recomenda-se reiniciar o sistema para aplicar todas as mudanças.${NC}"
echo -e "${YELLOW}Dica: Se algo essencial foi removido por engano, reinstale com 'sudo dnf install <pacote>'.${NC}"
