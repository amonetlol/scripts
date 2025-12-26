#!/usr/bin/env bash

# Determina o diretório onde o script está localizado
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cria os diretórios necessários
mkdir -p ~/.icons
mkdir -p ~/.themes

ICONS_ZIPS=(
    "Afterglow-cursors.zip"
    "McMojave-circle-black.zip"
    "McMojave-circle-blue.zip"
    "McMojave-circle-grey.zip"
)

THEME_ZIPS=(
    "Mojave-Dark-solid-alt.zip"
    "Mojave-Light-solid-alt.zip"
    "WhiteSur-Dark-solid.zip"
    "WhiteSur-Light-solid.zip"
    "WhiteSur-Dark-solid-nord.zip"
    "WhiteSur-Light-solid-nord.zip"
)

echo "Extraindo cursores para ~/.icons..."

# Extrai os icons + cursor
for zip in "${ICONS_ZIPS[@]}"; do
    zip_path="${SCRIPT_DIR}/${zip}"
    
    if [[ -f "$zip_path" ]]; then
        unzip -qo "$zip_path" -d ~/.icons
        if [[ $? -eq 0 ]]; then
            echo "Extraído com sucesso: $zip → ~/.icons"
        else
            echo "Erro ao extrair: $zip" >&2
        fi
    else
        echo "Arquivo não encontrado: $zip" >&2
    fi
done

echo
echo "Extraindo temas para ~/.themes..."

# Extrai os temas
for zip in "${THEME_ZIPS[@]}"; do
    zip_path="${SCRIPT_DIR}/${zip}"
    
    if [[ -f "$zip_path" ]]; then
        unzip -qo "$zip_path" -d ~/.themes
        if [[ $? -eq 0 ]]; then
            echo "Extraído com sucesso: $zip → ~/.themes"
        else
            echo "Erro ao extrair: $zip" >&2
        fi
    else
        echo "Arquivo não encontrado: $zip" >&2
    fi
done

echo
echo "Operação concluída com sucesso!"
