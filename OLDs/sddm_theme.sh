#!/bin/bash

CURRENT=$(pwd)
cd /tmp

# Install Catppuccin theme for SDDM
# wget https://github.com/catppuccin/sddm/releases/download/v1.1.2/catppuccin-macchiato-mauve-sddm.zip

# if [ -f catppuccin-macchiato-mauve-sddm.zip ]; then
#   7z x catppuccin-macchiato-mauve-sddm.zip
#   sudo cp -r catppuccin-macchiato-mauve /usr/share/sddm/themes/
#   sudo tee /etc/sddm.conf <<'EOF'
# [Theme]
# Current=catppuccin-macchiato-mauve
# EOF
# fi

wget https://github.com/catppuccin/sddm/releases/download/v1.1.2/catppuccin-macchiato-blue-sddm.zip

if [ -f catppuccin-macchiato-blue-sddm.zip ]; then
  7z x catppuccin-macchiato-blue-sddm.zip
  sudo cp -r catppuccin-macchiato-blue /usr/share/sddm/themes/
  sudo tee /etc/sddm.conf <<'EOF'
[Theme]
Current=catppuccin-macchiato-blue
EOF
fi

# Return to previous path
cd $CURRENT
