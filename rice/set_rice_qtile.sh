#!/usr/bin/env bash

# Determina o diretório onde o script está localizado
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Diretório de origem dos arquivos de tema
SETTINGS_DIR="${SCRIPT_DIR}/settings"

# Cria os diretórios necessários
mkdir -p ~/.icons
mkdir -p ~/.config/xsettingsd
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0

# Cria os links simbólicos conforme a estrutura desejada

# ~/.gtkrc-2.0 -> $SETTINGS_DIR/.gtkrc-2.0
ln -sf "${SETTINGS_DIR}/gtkrc-2.0" ~/.gtkrc-2.0

# ~/.icons/default -> $SETTINGS_DIR/.icons/default
ln -sf "${SETTINGS_DIR}/icons/default" ~/.icons/default

# ~/.config/gtk-3.0/settings.ini -> $SETTINGS_DIR/gtk-3.0/settings.ini
ln -sf "${SETTINGS_DIR}/gtk-3.0/settings.ini" ~/.config/gtk-3.0/settings.ini

# ~/.config/xsettingsd/xsettingsd.conf -> $SETTINGS_DIR/xsettingsd/xsettingsd.conf
ln -sf "${SETTINGS_DIR}/xsettingsd/xsettingsd.conf" ~/.config/xsettingsd/xsettingsd.conf

# Todos os itens dentro de gtk-4.0/ -> ~/.config/gtk-4.0/
for item in "${SETTINGS_DIR}/gtk-4.0"/*; do
    if [ -e "$item" ]; then
        ln -sf "$item" ~/.config/gtk-4.0/
    fi
done

echo "Links simbólicos criados com sucesso a partir da pasta 'settings/'!"
