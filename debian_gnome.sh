#!/usr/bin/env bash

set -e  # Para o script em caso de erro  

 sudo apt install -y \
   wget neovim git xclip gcc luarocks lua5.1 python3-pip python3-pynvim \
   tree-sitter-cli npm nodejs fd-find lazygit starship btop ripgrep \
   eza fastfetch duf kitty htop
