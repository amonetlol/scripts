#!/bin/bash
# Script chroot automático para sistemas BTRFS
# Uso: sudo ./chroot-btrfs-auto.sh /dev/sdXY
# Exemplo: sudo ./chroot-btrfs-auto.sh /dev/sda2

set -e  # Para o script em caso de erro

if [ $# -ne 1 ]; then
    echo "Uso: sudo $0 <partição-btrfs> (ex: /dev/sda2)"
    exit 1
fi

PART="$1"
MNT="/mnt/root"

# Verifica se é uma partição BTRFS
if ! blkid "$PART" | grep -q TYPE=\"btrfs\"; then
    echo "Erro: $PART não parece ser uma partição BTRFS."
    exit 1
fi

# Cria ponto de montagem
echo "Criando $MNT..."
mkdir -p "$MNT"

# Monta o subvolume raiz padrão (primeiro tenta @, senão monta o raiz do filesystem)
echo "Montando subvolume raiz..."
if mount "$PART" "$MNT" -o subvol=@ 2>/dev/null; then
    echo "Subvolume @ montado."
elif mount "$PART" "$MNT" -o subvol=/ 2>/dev/null; then
    echo "Subvolume raiz (/) montado."
else
    echo "Não encontrou subvolume @ nem /. Tentando montagem padrão..."
    mount "$PART" "$MNT"
fi

# Função para montar subvolume se existir
mount_subvol() {
    local subvol="$1"
    local target="$2"
    mkdir -p "$MNT/$target"
    if mount "$PART" "$MNT/$target" -o subvol="$subvol" 2>/dev/null; then
        echo "Subvolume $subvol montado em /$target"
    fi
}

# Monta subvolumes comuns (se existirem)
echo "Procurando e montando subvolumes comuns..."
mount_subvol @home              home
mount_subvol @log               var/log
mount_subvol @cache             var/cache
mount_subvol @tmp               var/tmp
mount_subvol @pkg               var/cache/pacman/pkg   # Arch-specific
mount_subvol @snapshots         .snapshots
mount_subvol @root              root                  # alguns usam isso

# Monta sistemas de arquivos virtuais
echo "Montando proc, sys, dev, etc..."
mount -t proc proc "$MNT/proc"
mount -t sysfs sys "$MNT/sys"
mount -t devtmpfs dev "$MNT/dev"
mount -t devpts devpts "$MNT/dev/pts"
mount -o bind /run "$MNT/run"

# Copia resolv.conf para internet dentro do chroot
echo "Configurando DNS..."
cp --remove-destination /etc/resolv.conf "$MNT/etc/resolv.conf"

# Função de limpeza ao sair
cleanup() {
    echo "Desmontando tudo..."
    umount "$MNT"/{proc,sys,dev/pts,dev,run} 2>/dev/null || true
    umount "$MNT"/{home,var/log,var/cache,var/tmp,var/cache/pacman/pkg,.snapshots,root} 2>/dev/null || true
    umount "$MNT"
    echo "Concluído."
}

# Captura saída do chroot (Ctrl+D ou exit)
trap cleanup EXIT

echo "=================================="
echo "Entrando no chroot em $PART"
echo "Digite 'exit' ou pressione Ctrl+D para sair e desmontar automaticamente."
echo "=================================="

chroot "$MNT" /bin/bash -l

# O trap cleanup será executado automaticamente ao sair
