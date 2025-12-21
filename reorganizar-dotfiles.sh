#!/bin/bash

# Script completo para reorganizar dotfiles para GNU Stow
# Trata: ~/.config/* , ~/,bashrc ~/,aliases e ~/.bin
# Rode no diretório raiz (onde tem config/, .bashrc, etc.)

set -e

echo "Verificando estrutura atual..."
if [ ! -d "config" ] && [ ! -f ".bashrc" ] && [ ! -f ".aliases" ] && [ ! -d "bin" ]; then
  echo "Erro: Nenhuma pasta/arq esperado encontrado. Verifique o diretório."
  exit 1
fi

# Apps em ~/.config/
APPS=("alacritty" "cava" "dunst" "fastfetch" "kitty" "neofetch" "picom" "qtile" "rofi")

for app in "${APPS[@]}"; do
  if [ -d "config/$app" ]; then
    echo "Processando $app (.config)..."
    mkdir -p "$app/.config"
    mv "config/$app" "$app/.config/$app"
  fi
done

# starship.toml
if [ -f "config/starship.toml" ]; then
  echo "Processando starship.toml..."
  mkdir -p "starship/.config"
  mv "config/starship.toml" "starship/.config/starship.toml"
fi

# .bashrc e .aliases (pacote 'bash')
echo "Processando .bashrc e .aliases..."
mkdir -p "bash"
if [ -f ".bashrc" ]; then
  mv ".bashrc" "bash/.bashrc"
fi
if [ -f ".aliases" ]; then
  mv ".aliases" "bash/.aliases"
fi

# Pasta bin → ~/.bin
if [ -d "bin" ]; then
  echo "Processando bin → ~/.bin..."
  mkdir -p "bin-package/.bin"  # nomeei 'bin-package' pra evitar conflito com pasta original
  mv bin/* "bin-package/.bin/"
  rmdir bin  # remove pasta vazia
fi

# Limpa config vazia
if [ -d "config" ] && [ -z "$(ls -A config)" ]; then
  rmdir config
  echo "Pasta config vazia removida."
fi

echo "Reorganização completa!"
echo "Estrutura agora:"
echo "  - Pacotes em .config/: qtile/.config/qtile , alacritty/.config/alacritty , etc."
echo "  - bash/.bashrc e bash/.aliases  (stow bash → symlinka ~/,bashrc e ~/,aliases)"
echo "  - bin-package/.bin/  (stow bin-package → symlinka ~/.bin inteiro)"
echo ""
echo "Instalação exemplo:"
echo "  stow qtile alacritty rofi bash bin-package  # etc."
echo "Teste com: stow -n -v bash  (simula)"
