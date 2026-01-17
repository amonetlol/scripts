#!/usr/bin/env bash

# =============================================================================
# Script para montar pasta compartilhada do VMware (HGFS) de forma persistente
# =============================================================================

set -euo pipefail

# Configurações - altere aqui se necessário
MOUNT_POINT="/mnt/hgfs/SERVER"
SHARE_NAME="SERVER"
UID_TO_USE=1000
GID_TO_USE=1000
FSTAB_LINE=".host:/${SHARE_NAME} ${MOUNT_POINT} fuse.vmhgfs-fuse allow_other,uid=${UID_TO_USE},gid=${GID_TO_USE},umask=0022,defaults 0 0"

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "→ Configurando montagem persistente do compartilhamento VMware: ${SHARE_NAME}"

# 1. Criar ponto de montagem (se não existir)
if [[ ! -d "$MOUNT_POINT" ]]; then
    echo "→ Criando diretório: $MOUNT_POINT"
    sudo mkdir -p "$MOUNT_POINT"
else
    echo "→ Diretório $MOUNT_POINT já existe"
fi

# 2. Verificar se já existe entrada no fstab
if grep -qF ".host:/${SHARE_NAME}" /etc/fstab; then
    echo -e "${YELLOW}Atenção:${NC} Já existe uma linha com .host:/${SHARE_NAME} no /etc/fstab"
    echo "Mostrando linhas relevantes:"
    grep ".host:/${SHARE_NAME}" /etc/fstab || true
    echo
    read -p "Deseja continuar e adicionar mesmo assim? (s/N): " resposta
    if [[ ! "$resposta" =~ ^[sS]$ ]]; then
        echo "Abortado pelo usuário."
        exit 1
    fi
fi

# 3. Adicionar ao fstab (com backup)
echo "→ Fazendo backup do /etc/fstab → /etc/fstab.bak.$(date +%Y%m%d_%H%M%S)"
sudo cp -f /etc/fstab /etc/fstab.bak.$(date +%Y%m%d_%H%M%S)

echo "→ Adicionando ao /etc/fstab:"
echo "   $FSTAB_LINE"
echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null

# 4. Testar se o fstab está sintaticamente correto
echo "→ Testando sintaxe do fstab..."
if ! sudo findmnt --verify --verbose; then
    echo -e "${RED}Erro na sintaxe do /etc/fstab!${NC}"
    echo "Últimas 5 linhas do fstab:"
    tail -n 5 /etc/fstab
    echo
    echo "Você pode restaurar o backup com:"
    echo "  sudo cp /etc/fstab.bak.* /etc/fstab"
    exit 1
fi

# 5. Tentar montar tudo que está no fstab (ou só o novo)
echo "→ Tentando montar todas as entradas do fstab..."
if sudo mount -a; then
    echo -e "${GREEN}Montagem realizada com sucesso${NC}"
else
    echo -e "${YELLOW}Alguns mounts falharam (pode ser normal se outros já estavam montados)${NC}"
fi

# 6. Mostrar status
echo
echo "→ Resultado atual:"
if mountpoint -q "$MOUNT_POINT"; then
    echo -e "${GREEN}OK →${NC} $MOUNT_POINT está montado"
    df -hT "$MOUNT_POINT" | tail -n 1
else
    echo -e "${RED}Atenção →${NC} $MOUNT_POINT NÃO está montado"
    echo "Tente montar manualmente para ver o erro:"
    echo "  sudo mount \"$MOUNT_POINT\""
fi

echo
echo "Comandos úteis para debug:"
echo "  sudo umount \"$MOUNT_POINT\"          # desmontar"
echo "  sudo mount \"$MOUNT_POINT\"           # montar apenas este"
echo "  findmnt \"$MOUNT_POINT\"              # ver detalhes"
echo "  systemctl status vmware-tools         # verificar serviço (se aplicável)"
echo
echo "Feito!"
