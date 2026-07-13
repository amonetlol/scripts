#!/usr/bin/env bash
# =============================================================================
# install-final.sh — Setup completo Arch/CachyOS + GNOME (amonetlol dotfiles)
#
# Uso:
#   SUDO_PASS='sua_senha' RDP_PASS='sua_senha_rdp' bash install-final.sh
#
# Variáveis opcionais:
#   SUDO_PASS      — senha sudo (obrigatória se sudo pedir senha)
#   RDP_USER       — usuário RDP (padrão: usuário atual)
#   RDP_PASS       — senha RDP (padrão: SUDO_PASS)
#   DOT_DIR        — pasta do repo dot (padrão: ~/src/dot)
#   BASE_DIR       — pasta do repo base (padrão: ~/src/base)
#   SKIP_CHAOTIC   — 1 para pular Chaotic-AUR
#   SKIP_AUR       — 1 para pular pacotes AUR
#
# Não inclui: montagem de HD externo, wayvnc, anydesk
#
# Pacotes extras: google-chrome, brave-origin-bin, ttf-0xproto-nerd, wl-clipboard
# Ulauncher: Catppuccin Mocha-Blue e Frappe-Blue apenas
# =============================================================================

set -euo pipefail

LOG="${LOG:-$HOME/install-final.log}"
exec > >(tee -a "$LOG") 2>&1

# --- Configuração ---
SUDO_PASS="${SUDO_PASS:-}"
RDP_USER="${RDP_USER:-$USER}"
RDP_PASS="${RDP_PASS:-$SUDO_PASS}"
DOT_DIR="${DOT_DIR:-$HOME/src/dot}"
BASE_DIR="${BASE_DIR:-$HOME/src/base}"
DOT_REPO="${DOT_REPO:-https://github.com/amonetlol/dot.git}"
BASE_REPO="${BASE_REPO:-https://github.com/amonetlol/base.git}"

KEEPALIVE_PID=""

# --- Helpers ---
log()  { echo -e "\033[0;34m[INFO]\033[0m $*"; }
ok()   { echo -e "\033[0;32m[OK]\033[0m $*"; }
warn() { echo -e "\033[1;33m[AVISO]\033[0m $*"; }

sudo_cmd() {
  if [[ -z "$SUDO_PASS" ]]; then
    sudo "$@"
  else
    echo "$SUDO_PASS" | sudo -S "$@"
  fi
}

setup_sudo() {
  if [[ -z "$SUDO_PASS" ]]; then
    sudo -v
    return
  fi
  echo "$SUDO_PASS" | sudo -S -v
  keep_sudo_alive() {
    while true; do
      echo "$SUDO_PASS" | sudo -S -v 2>/dev/null
      sleep 60
    done
  }
  keep_sudo_alive &
  KEEPALIVE_PID=$!
  trap 'kill "$KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

setup_session_bus() {
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
}

section() {
  echo ""
  echo "=========================================="
  echo ">>> $*"
  echo "=========================================="
}

require_user() {
  if [[ "${EUID:-0}" -eq 0 ]]; then
    echo "[ERRO] Execute como usuário normal, não como root."
    exit 1
  fi
}

# --- 1. Repositórios ---
clone_repos() {
  section "[1/13] Clonando repositórios dot e base"
  mkdir -p "$(dirname "$DOT_DIR")"
  if [[ ! -d "$DOT_DIR/.git" ]]; then
    git clone --depth 1 "$DOT_REPO" "$DOT_DIR"
  else
    git -C "$DOT_DIR" pull --ff-only || true
  fi
  if [[ ! -d "$BASE_DIR/.git" ]]; then
    git clone --depth 1 "$BASE_REPO" "$BASE_DIR"
  else
    git -C "$BASE_DIR" pull --ff-only || true
  fi
  ok "Repos em $DOT_DIR e $BASE_DIR"
}

# --- 2. Chaotic-AUR ---
setup_chaotic_aur() {
  [[ "${SKIP_CHAOTIC:-0}" == "1" ]] && { warn "Chaotic-AUR ignorado"; return; }
  section "[2/13] Configurando Chaotic-AUR"
  if grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
    ok "Chaotic-AUR já configurado"
  else
    sudo_cmd pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo_cmd pacman-key --lsign-key 3056513887B78AEB
    sudo_cmd pacman -U --noconfirm \
      'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
      'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
  {
    echo ""
    echo "[chaotic-aur]"
    echo "SigLevel = Optional TrustedOnly"
    echo "Include = /etc/pacman.d/chaotic-mirrorlist"
  } | sudo_cmd tee -a /etc/pacman.conf > /dev/null
    ok "Chaotic-AUR adicionado"
  fi
  sudo_cmd pacman -Sy --noconfirm
}

# --- 3. Pacotes pacman ---
install_pacman_packages() {
  section "[3/13] Instalando pacotes via pacman"
  local pkgs=(
    base-devel git wget curl unzip zip p7zip tar rsync nano vim neovim
    bash-completion procs less starship zoxide eza fd ripgrep fzf duf fastfetch
    btop htop tree tldr lazygit bat gcc make cmake pkgconf jq bc findutils
    coreutils intel-ucode snap-pac nodejs npm lua51 luarocks python python-pip
    python-pynvim python-pipenv tree-sitter-cli python-virtualenv tmux prettier
    foot kitty alacritty fontconfig noto-fonts noto-fonts-emoji inetutils
    wmctrl gtk3 xz wl-clipboard
    gnome-remote-desktop openssl
    vlc ffmpeg gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly
    libva libva-utils ntfs-3g
  )
  sudo_cmd pacman -S --needed --noconfirm "${pkgs[@]}" || {
    warn "Instalação em lote falhou — tentando pacote a pacote..."
    for pkg in "${pkgs[@]}"; do
      sudo_cmd pacman -S --needed --noconfirm "$pkg" 2>/dev/null || warn "SKIP: $pkg"
    done
  }
  ok "Pacotes pacman instalados"
}

# --- 4. yay + AUR ---
install_yay() {
  command -v yay >/dev/null 2>&1 && return
  if pacman -Si yay-bin &>/dev/null; then
    sudo_cmd pacman -S --needed --noconfirm yay-bin
  else
    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
    (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
  fi
}

install_aur_packages() {
  [[ "${SKIP_AUR:-0}" == "1" ]] && { warn "AUR ignorado"; return; }
  section "[4/13] Instalando yay-bin e pacotes AUR"
  install_yay
  local aur_pkgs=(
    herdr-bin visual-studio-code-bin extension-manager ulauncher
    google-chrome brave-origin-bin ttf-0xproto-nerd
  )
  for pkg in "${aur_pkgs[@]}"; do
    log "AUR: $pkg"
    yay -S --needed --noconfirm "$pkg" || warn "SKIP AUR: $pkg"
  done
  if command -v fc-cache &>/dev/null; then
    fc-cache -fv "$HOME/.local/share/fonts" &>/dev/null || fc-cache -fv &>/dev/null || true
  fi
  ok "Pacotes AUR instalados"
}

# --- 5. up-configs (all) ---
run_up_configs() {
  section "[5/13] up-configs.sh (all)"
  printf 'all\n\n0\n' | bash "$DOT_DIR/up-configs.sh" || warn "up-configs com avisos"
}

# --- 6. mod-rice (sem sudo — extração direta dos Assets) ---
install_mod_rice() {
  section "[6/13] 06-mod-rice (temas, cursor, ícones)"
  local assets="$DOT_DIR/Assets"
  local themes="$HOME/.themes"
  local icons="$HOME/.icons"
  local tmp="/tmp/catppuccin-theme-extractor"

  [[ -d "$assets" ]] || { warn "Pasta Assets não encontrada"; return; }
  mkdir -p "$themes" "$icons"

  extract_archive() {
    local file="$1" dest="$2" label="$3"
    [[ -f "$file" ]] || { warn "SKIP: $label"; return; }
    log "Instalando $label..."
    case "$file" in
      *.zip)    unzip -o -q "$file" -d "$dest" ;;
      *.tar.xz) tar -xJf "$file" -C "$dest" ;;
      *) warn "Formato não suportado: $file"; return ;;
    esac
    ok "$label"
  }

  install_catppuccin() {
    local file="$1" inner="$2" name="$3"
    [[ -f "$file" ]] || return
    log "Catppuccin $name..."
    rm -rf "$tmp"
    mkdir -p "$tmp"
    unzip -o -q "$file" -d "$tmp"
    rm -rf "$themes/$name"
    cp -r "$tmp/$inner" "$themes/$name"
    rm -rf "$tmp"
    ok "$name"
  }

  extract_archive "$assets/Manhattan.zip" "$themes" "Tema Manhattan"
  install_catppuccin "$assets/catppuccin-mocha-blue-standard+default.zip" \
    "catppuccin-mocha-blue-standard+default" "catppuccin-mocha-blue"
  install_catppuccin "$assets/catppuccin-frappe-blue-standard+default.zip" \
    "catppuccin-frappe-blue-standard+default" "catppuccin-frappe-blue"
  extract_archive "$assets/Qogir-cursors.tar.xz" "$icons" "Cursor Qogir"
  extract_archive "$assets/MacTahoe.tar.xz" "$icons" "Ícones MacTahoe"

  if command -v gtk-update-icon-cache &>/dev/null; then
    find "$icons" -mindepth 1 -maxdepth 1 -type d | while read -r d; do
      [[ -f "$d/index.theme" ]] && gtk-update-icon-cache -f -t "$d" &>/dev/null || true
    done
  fi

  setup_session_bus
  gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme 'MacTahoe-dark' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-theme 'Qogir-cursors' 2>/dev/null || true
  ok "Temas em ~/.themes e ~/.icons"
}

# --- 7. starship ---
install_starship_config() {
  section "[7/13] install-starship.sh"
  bash "$BASE_DIR/modules/install-starship.sh" || warn "starship com avisos"
}

# --- 8. foot ---
install_foot_config() {
  section "[8/13] install-foot.sh"
  bash "$BASE_DIR/modules/install-foot.sh" || warn "foot com avisos"
}

# --- 9. wallpapers ---
install_wallpapers() {
  section "[9/13] install-wallpapers.sh"
  bash "$BASE_DIR/modules/install-wallpapers.sh" || warn "wallpapers com avisos"
}

# --- 10. atalhos GNOME ---
install_gnome_shortcuts() {
  section "[10/13] gnome_shortcuts.sh"
  bash "$DOT_DIR/scripts/gnome_shortcuts.sh" || warn "gnome_shortcuts com avisos"
  systemctl --user enable --now ulauncher.service 2>/dev/null || true
}

# --- 11. Temas Catppuccin para Ulauncher (mocha-blue + frappe-blue) ---
install_ulauncher_catppuccin() {
  section "[11/13] Temas Catppuccin Ulauncher (mocha-blue, frappe-blue)"
  command -v ulauncher &>/dev/null || { warn "ulauncher não instalado — pulando temas"; return; }
  python3 <(curl -fsSL https://raw.githubusercontent.com/catppuccin/ulauncher/main/install.py) \
    -f mocha frappe -a blue || warn "Catppuccin Ulauncher com avisos"
  ok "Temas: Catppuccin-Mocha-Blue e Catppuccin-Frappe-Blue"
}

# --- 12. GNOME Remote Desktop (RDP) ---
setup_gnome_remote_desktop() {
  section "[12/13] GNOME Remote Desktop (RDP)"
  [[ -z "$RDP_PASS" ]] && { warn "RDP_PASS não definida — pulando credenciais RDP"; return; }

  setup_session_bus
  local grd_dir="$HOME/.local/share/gnome-remote-desktop"
  mkdir -p "$grd_dir"

  if [[ ! -f "$grd_dir/tls.key" ]]; then
    openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
      -subj "/CN=$(hostname)" \
      -keyout "$grd_dir/tls.key" -out "$grd_dir/tls.crt" 2>/dev/null
  fi

  grdctl rdp set-tls-key "$grd_dir/tls.key"
  grdctl rdp set-tls-cert "$grd_dir/tls.crt"
  grdctl rdp set-credentials "$RDP_USER" "$RDP_PASS"
  grdctl rdp disable-view-only
  grdctl rdp enable
  gsettings set org.gnome.desktop.remote-desktop.rdp enable true 2>/dev/null || true
  gsettings set org.gnome.desktop.remote-desktop.rdp view-only false 2>/dev/null || true
  systemctl --user enable gnome-remote-desktop.service
  systemctl --user restart gnome-remote-desktop.service 2>/dev/null || true

  sudo_cmd mkdir -p /etc/gnome-remote-desktop
  if [[ ! -f /etc/gnome-remote-desktop/rdp.key ]]; then
    sudo_cmd openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
      -subj "/CN=$(hostname)" \
      -keyout /etc/gnome-remote-desktop/rdp.key \
      -out /etc/gnome-remote-desktop/rdp.crt 2>/dev/null
  fi
  sudo_cmd grdctl --system rdp set-tls-key /etc/gnome-remote-desktop/rdp.key
  sudo_cmd grdctl --system rdp set-tls-cert /etc/gnome-remote-desktop/rdp.crt
  sudo_cmd grdctl --system rdp set-credentials "$RDP_USER" "$RDP_PASS"
  sudo_cmd grdctl --system rdp disable-view-only
  sudo_cmd grdctl --system rdp enable
  sudo_cmd systemctl enable --now gnome-remote-desktop.service 2>/dev/null || true

  if command -v firewall-cmd &>/dev/null; then
    sudo_cmd firewall-cmd --permanent --add-port=3389/tcp 2>/dev/null || true
    sudo_cmd firewall-cmd --reload 2>/dev/null || true
  fi
  ok "RDP ativo — conecte com mstsc em $(hostname -I | awk '{print $1}'):3389"
}

# --- 13. Ajustes GNOME (logout + ocultar bateria) ---
setup_gnome_tweaks() {
  section "[13/13] Ajustes GNOME (logout + ícone bateria)"
  setup_session_bus

  gsettings set org.gnome.shell always-show-log-out true
  dconf write /org/gnome/shell/always-show-log-out true 2>/dev/null || true

  local ext_uuid="hide-system-icons@shichen35.github.io"
  local url tmp="/tmp/hide-system-icons.zip"
  if ! gnome-extensions list 2>/dev/null | grep -q "$ext_uuid"; then
    url=$(curl -sL "https://extensions.gnome.org/extension-info/?pk=8558&shell_version=50" \
      | python3 -c "import sys,json; u=json.load(sys.stdin)['download_url']; print(u if u.startswith('http') else 'https://extensions.gnome.org'+u)")
    curl -sL "$url" -o "$tmp"
    gnome-extensions install --force "$tmp" 2>/dev/null || true
    rm -f "$tmp"
  fi
  if [[ -d "$HOME/.local/share/gnome-shell/extensions/$ext_uuid/schemas" ]]; then
    glib-compile-schemas "$HOME/.local/share/gnome-shell/extensions/$ext_uuid/schemas/" 2>/dev/null || true
  fi
  dconf write /org/gnome/shell/extensions/hide-system-icons/hide-power true 2>/dev/null || true
  gnome-extensions enable "$ext_uuid" 2>/dev/null || warn "Extensão bateria: faça logout/login para ativar"

  ok "Logout no menu habilitado; ícone bateria oculto após logout/login"
}

# --- Main ---
main() {
  echo "=========================================="
  echo " install-final.sh — $(date)"
  echo " Log: $LOG"
  echo "=========================================="

  require_user
  setup_sudo

  clone_repos
  setup_chaotic_aur
  install_pacman_packages
  install_aur_packages
  run_up_configs
  install_mod_rice
  install_starship_config
  install_foot_config
  install_wallpapers
  install_gnome_shortcuts
  install_ulauncher_catppuccin
  setup_gnome_remote_desktop
  setup_gnome_tweaks

  echo ""
  echo "=========================================="
  echo " INSTALAÇÃO CONCLUÍDA — $(date)"
  echo "=========================================="
  echo ""
  echo "Próximos passos:"
  echo "  1. Faça logout/login para aplicar temas e extensões GNOME"
  echo "  2. RDP: mstsc → $(hostname -I 2>/dev/null | awk '{print $1}'):3389"
  echo "  3. Log completo: $LOG"
  echo ""
}

main "$@"
