#!/usr/bin/env bash
# =============================================================================
# Script para criar pasta de config do Neovim e baixar o arquivo mappings.lua
# =============================================================================

set -euo pipefail

# Configurações
NVIM_USER_DIR="$HOME/.nvim/lua/user"
TARGET_FILE="$NVIM_USER_DIR/mappings.lua"
SOURCE_URL="https://github.com/amonetlol/scripts/raw/refs/heads/main/TEMP/nvim_fix/mappings.lua"

echo "→ Configurando pasta de usuário do Neovim..."

# 1. Cria a estrutura de diretórios (equivalente ao mkdir -p)
mkdir -p "$NVIM_USER_DIR"

if [ ! -d "$NVIM_USER_DIR" ]; then
    echo "Erro: Não consegui criar a pasta $NVIM_USER_DIR"
    exit 1
fi

# 2. Faz download do arquivo
echo "→ Baixando mappings.lua de $SOURCE_URL ..."

if command -v curl >/dev/null 2>&1; then
    curl -s -L -o "$TARGET_FILE" "$SOURCE_URL" || {
        echo "Erro: falha ao baixar com curl"
        exit 1
    }
elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$TARGET_FILE" "$SOURCE_URL" || {
        echo "Erro: falha ao baixar com wget"
        exit 1
    }
else
    echo "Erro: nem curl nem wget encontrados no sistema."
    echo "Por favor instale um deles e tente novamente."
    exit 1
fi

# 3. Verificação final
if [ -s "$TARGET_FILE" ]; then
    echo ""
    echo "✓ Arquivo baixado com sucesso!"
    echo "  Localização: $TARGET_FILE"
    echo ""
    ls -l "$TARGET_FILE"
    echo ""
    echo "Tamanho: $(du -h "$TARGET_FILE" | cut -f1)"
else
    echo "Erro: o arquivo foi baixado mas está vazio ou não existe."
    exit 1
fi

exit 0
