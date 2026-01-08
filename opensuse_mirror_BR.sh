#!/bin/bash

# Script pra configurar repos essenciais no Tumbleweed (com mirror BR + openh264)
# Inclui: oss, non-oss (mirror BR) e openh264 (oficial)
# Rode com: sudo bash setup-repos-tumbleweed-br.sh

set -e

BASE_BR="https://download.opensuse.net.br/tumbleweed/repo"

echo "=== Limpando repos antigos (por segurança) ==="
sudo zypper clean --all
sudo rm -f /etc/zypp/repos.d/*.repo  # remove tudo mesmo

echo "=== Adicionando repo OSS (mirror BR) ==="
sudo zypper addrepo -f "$BASE_BR/oss/" repo-oss-br

echo "=== Adicionando repo Non-OSS (mirror BR) ==="
sudo zypper addrepo -f "$BASE_BR/non-oss/" repo-non-oss-br

echo "=== Adicionando repo OpenH264 (oficial Cisco/openSUSE) ==="
sudo zypper addrepo -f http://codecs.opensuse.org/openh264/openSUSE_Tumbleweed repo-openh264

# Renomeia pra ficar claro no zypper lr
sudo zypper renamerepo repo-oss-br "BR - OSS"
sudo zypper renamerepo repo-non-oss-br "BR - Non-OSS"
sudo zypper renamerepo repo-openh264 "OpenH264 (Cisco)"

echo "=== Atualizando cache dos repos ==="
sudo zypper --non-interactive refresh

echo "=== Instalando pacotes openh264 básicos ==="
sudo zypper --non-interactive install gstreamer-plugin-openh264 mozilla-openh264

echo "=== Pronto! Sistema configurado ==="
echo "Teste o update completo: sudo zypper dup"
echo "Lista de repos: zypper lr"
echo ""
echo "Se algo der errado, reinstala o pacote openSUSE-repos-Tumbleweed pra voltar ao padrão oficial:"
echo "sudo zypper in openSUSE-repos-Tumbleweed"
