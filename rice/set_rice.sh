#!/usr/bin/env bash
# Cursor: Afterglow-cursors (nome exato da pasta do tema)
gsettings set org.gnome.desktop.interface cursor-theme 'Afterglow-Cursors'

# Ícones: McMojave-circle-black (ajuste se o nome for diferente, ex: McMojave-circle-dark-black)
gsettings set org.gnome.desktop.interface icon-theme 'McMojave-circle-black'

# Tema GTK (aplicações): WhiteSur-Dark-solid
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark-solid'

# Tema Shell (painel, overview etc.) – requer extensão User Themes instalada
gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-Dark-solid'
