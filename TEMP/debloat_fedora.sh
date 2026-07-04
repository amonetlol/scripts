#!/bin/bash
# Script atualizado com nomes corretos do Fedora 44 GNOME

echo "=== Removendo aplicativos padrão do Fedora GNOME ==="

sudo dnf remove -y --skip-unavailable \
    gnome-contacts \
    gnome-weather \
    gnome-maps \
    simple-scan \
    gnome-boxes \
    snapshot \
    gnome-calendar \
    decibels \
    gnome-software \
    mediawriter \
    gnome-music \
    gnome-photos \
    gnome-tour \
    gnome-calculator \
    gnome-clocks

# Remove LibreOffice completo
echo "Removendo LibreOffice..."
sudo dnf remove -y --skip-unavailable libreoffice*

echo "Limpando dependências órfãs..."
sudo dnf autoremove -y

echo "Atualizando cache..."
sudo dnf makecache

echo "========================================"
echo "✅ Processo finalizado!"
echo "Reinicie o sistema para ver as mudanças."
echo "========================================"
