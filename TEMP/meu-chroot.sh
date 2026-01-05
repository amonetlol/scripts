#!/bin/bash

# 1. sudo fdisk -l
# 2. sudo mkdir /mnt/root
# 3. sudo mount /dev/sda2 /mnt/root
#
# ------ USO ----------
# 4. sudo meu-chroot.sh /mnt/root
#

if [ $# -ne 1 ]; then
    echo "Uso: $0 <diretorio-montado>  (ex: /mnt/root)"
    exit 1
fi

ROOT="$1"

# Monta os diretórios virtuais
mount -t proc proc "$ROOT/proc"
mount -t sysfs sys "$ROOT/sys"
mount -t devtmpfs dev "$ROOT/dev"
mount -t devpts devpts "$ROOT/dev/pts"
mount -o bind /run "$ROOT/run"

# Copia resolv.conf para internet
cp /etc/resolv.conf "$ROOT/etc/resolv.conf"

# Entra no chroot
echo "Entrando no chroot em $ROOT..."
chroot "$ROOT" /bin/bash

# Ao sair (exit), desmonta tudo automaticamente? (opcional, mas cuidado)
echo "Saindo do chroot. Desmontando..."
umount "$ROOT"/{proc,sys,dev/pts,dev,run}
