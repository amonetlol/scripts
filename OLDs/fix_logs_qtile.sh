#!/usr/bin/env bash

# Qtile udev
# sudo mkdir -p /usr/lib/udev # se precisar criar a pasta
sudo ln -s /usr/bin/qtile /usr/lib/udev/qtile

# VMware only
echo "blacklist i2c_piix4" | sudo tee /etc/modprobe.d/blacklist-i2c_piix4.conf
sudo mkinitcpio -P
