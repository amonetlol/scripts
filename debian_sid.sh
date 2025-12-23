#!/usr/bin/env bash
# =============================================================================
# Script: atualiza sources.list para Debian SID (com backup)
# =============================================================================

set -euo pipefail

FILE="/etc/apt/sources.list"
BACKUP="${FILE}.OLD.$(date +%Y%m%d_%H%M%S)"

echo "Operação: atualização do sources.list para Debian SID"
echo "──────────────────────────────────────────────────────"

# 1. Verifica se é root
if [[ $EUID -ne 0 ]]; then
    echo "Erro: Este script precisa ser executado como root (sudo)"
    exit 1
fi

# 2. Faz backup com data/hora no nome (evita sobrescrever backups anteriores)
if [[ -f "$FILE" ]]; then
    echo "→ Criando backup: $BACKUP"
    cp -a "$FILE" "$BACKUP"
else
    echo "Aviso: arquivo $FILE não encontrado. Criando do zero."
fi

# 3. Escreve o novo conteúdo (Debian SID completo)
echo "→ Escrevendo novo sources.list..."

cat > "$FILE" << 'EOF'
# Debian SID (unstable) - criado em $(date '+%Y-%m-%d %H:%M:%S')
# /etc/apt/sources.list
deb     http://deb.debian.org/debian/          sid main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/          sid main contrib non-free non-free-firmware

# Atualizações de segurança (ainda não existem no SID, mas boa prática manter comentado)
# deb     http://security.debian.org/debian-security sid-security main
# deb-src http://security.debian.org/debian-security sid-security main

# Mirrors alternativos (descomente se quiser testar)
# deb     http://ftp.br.debian.org/debian/       sid main contrib non-free non-free-firmware
# deb     http://ftp.debian.org/debian/          sid main contrib non-free non-free-firmware
EOF

# 4. Mostra resultado
echo
echo "Conteúdo atual do /etc/apt/sources.list:"
echo "───────────────────────────────────────"
cat "$FILE"
echo "───────────────────────────────────────"

echo
echo "Backup criado em: $BACKUP"
echo "Pronto! Agora você pode fazer:"
echo "  sudo apt update"
echo

exit 0
