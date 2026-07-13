#!/usr/bin/env bash
# Instala temas Catppuccin para Ulauncher: Mocha-Blue e Frappe-Blue
set -euo pipefail

if ! command -v ulauncher &>/dev/null; then
  echo "[ERRO] ulauncher não encontrado. Instale antes: yay -S ulauncher"
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  echo "[ERRO] python3 não encontrado."
  exit 1
fi

echo "[*] Instalando Catppuccin-Mocha-Blue e Catppuccin-Frappe-Blue..."
python3 <(curl -fsSL https://raw.githubusercontent.com/catppuccin/ulauncher/main/install.py) \
  -f mocha frappe -a blue

echo ""
echo "[OK] Temas instalados em ~/.config/ulauncher/user-themes/"
ls -1 ~/.config/ulauncher/user-themes/ | grep -E 'Mocha-Blue|Frappe-Blue' || true
echo ""
echo "Escolha o tema em: Ulauncher → Preferências → Aparência → Tema"
