#!/usr/bin/env bash

ln -sf $PWD/bin ~/.bin
chmod +x $PWD/bin/*
ln -sf $PWD/.aliases ~/.aliases
ln -sf $PWD/.aliases-arch ~/.aliases-arch
ln -sf $PWD/.bashrc ~/.bashrc
ln -sf $PWD/.functions ~/.functions
ln -sf $PWD/config/starship.toml ~/.config/starship.toml
ln -sf $PWD/config/fastfetch ~/.config/fastfetch
ln -sf $PWD/config/neofetch ~/.config/neofetch
ln -sf $PWD/local/share/applications ~/.local/share/applications

echo "Done!!!!"
