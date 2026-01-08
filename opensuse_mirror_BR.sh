#!/bin/bash

# Script para trocar os repos do Tumbleweed para o mirror brasileiro download.opensuse.net.br
# Rode com: sudo bash add-br-mirror-repos.sh
# Backup automático dos repos antigos em /etc/zypp/repos.d/backup/

set -e  # Para se algo der errado

MIRROR="https://download.opensuse.net.br/tumbleweed/repo"

echo "Fazendo backup dos repos atuais..."
sudo mkdir -p /etc/zypp/repos.d/backup
sudo mv /etc/zypp/repos.d/*.repo /etc/zypp/repos.d/backup/ 2>/dev/null || true

echo "Adicionando repo OSS..."
sudo zypper addrepo -f -k $MIRROR/oss repo-oss

echo "Adicionando repo Non-OSS..."
sudo zypper addrepo -f -k $MIRROR/non-oss repo-non-oss

# echo "Adicionando repo Debug (opcional, mas útil pra reports)"
# sudo zypper addrepo -f -k $MIRROR/debug repo-debug

# echo "Adicionando repo Source OSS"
# sudo zypper addrepo -f -k $MIRROR/src-oss repo-src-oss

# echo "Adicionando repo Source Non-OSS"
# sudo zypper addrepo -f -k $MIRROR/src-non-oss repo-src-non-oss

echo "Renomeando repos pra identificar o mirror BR..."
sudo zypper modifyrepo --all --name="BR-Mirror - $(zypper lr -d | grep 'repo-' | awk '{print $3}')"

echo "Fazendo refresh dos repos..."
sudo zypper --non-interactive refresh

echo "Pronto! Seus repos agora usam o mirror brasileiro."
echo "Teste com: zypper dup"
echo "Se quiser voltar: sudo mv /etc/zypp/repos.d/backup/*.repo /etc/zypp/repos.d/"
