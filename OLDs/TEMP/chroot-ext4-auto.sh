#!/bin/bash

# chroot-auto.sh - Chroot automático completo
# sudo fdisk -l
# Uso: sudo ./chroot-ext4-auto.sh /dev/sda2

set -e  # Para o script em caso de erro

if [ $# -ne 1 ]; then
    echo "Uso: sudo $0 <partição> (ex: /dev/sda2 ou /dev/nvme0n1p2)"
    exit 1
fi

PARTITION="$1"
MOUNT_POINT="/mnt/root"

echo "=== Chroot automático em $PARTITION ==="

# 1. Criar ponto de montagem se não existir
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Criando diretório $MOUNT_POINT..."
    mkdir -p "$MOUNT_POINT"
fi

# 2. Montar a partição raiz
echo "Montando $PARTITION em $MOUNT_POINT..."
mount "$PARTITION" "$MOUNT_POINT"

# Função para desmontar tudo (será chamada ao sair)
cleanup() {
    echo ""
    echo "Saindo do chroot. Desmontando tudo..."

    # Desmontar na ordem reversa (ignorando erros se já estiver desmontado)
    umount "$MOUNT_POINT/run" 2>/dev/null || true
    umount "$MOUNT_POINT/dev/pts" 2>/dev/null || true
    umount "$MOUNT_POINT/dev" 2>/dev/null || true
    umount "$MOUNT_POINT/sys" 2>/dev/null || true
    umount "$MOUNT_POINT/proc" 2>/dev/null || true

    # Desmontar a partição principal
    umount "$MOUNT_POINT" 2>/dev/null || true

    echo "Tudo desmontado com sucesso!"
}

# Capturar saída (exit, Ctrl+C, etc.) para garantir desmontagem
trap cleanup EXIT

# 3. Montar filesystems virtuais
echo "Montando proc, sys, dev, etc..."
mount -t proc proc "$MOUNT_POINT/proc"
mount -t sysfs sys "$MOUNT_POINT/sys"
mount -t devtmpfs dev "$MOUNT_POINT/dev"
mount -t devpts devpts "$MOUNT_POINT/dev/pts"
mount -o bind /run "$MOUNT_POINT/run"

# 4. Copiar resolv.conf para ter DNS/internet
echo "Configurando DNS..."
cp --preserve=mode /etc/resolv.conf "$MOUNT_POINT/etc/resolv.conf"

# 5. Entrar no chroot
echo "Entrando no chroot em $MOUNT_POINT..."
echo "Digite 'exit' ou pressione Ctrl+D quando terminar."
echo ""

chroot "$MOUNT_POINT" /bin/bash

# O trap cleanup será executado automaticamente aqui
