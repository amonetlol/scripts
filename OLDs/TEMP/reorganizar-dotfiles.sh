#!/bin/bash
# Script completo para reorganizar dotfiles para GNU Stow
# Trata: ~/.config/* , ~/,bashrc ~/,aliases e ~/.bin
# Agora também trata rofi/scripts e rofi/themes → ~/.local/share/rofi/
# Rode no diretório raiz (onde tem config/, .bashrc, etc.)
set -e
echo "Verificando estrutura atual..."
if [ ! -d "config" ] && [ ! -f ".bashrc" ] && [ ! -f ".aliases" ] && [ ! -d "bin" ] && [ ! -d "rofi" ]; then
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
  mkdir -p "bin-package/.bin" # nomeei 'bin-package' pra evitar conflito
  mv bin/* "bin-package/.bin/"
  rmdir bin # remove pasta vazia
fi

# Rofi: scripts e themes → ~/.local/share/rofi/
if [ -d "rofi" ]; then
  echo "Processando rofi (scripts e themes) → ~/.local/share/rofi/..."
  mkdir -p "rofi-package/.local/share/rofi"
  if [ -d "rofi/scripts" ]; then
    mv "rofi/scripts" "rofi-package/.local/share/rofi/scripts"
  fi
  if [ -d "rofi/themes" ]; then
    mv "rofi/themes" "rofi-package/.local/share/rofi/themes"
  fi
  # Remove pasta rofi vazia (se sobrar algo, avisa)
  if [ -z "$(ls -A rofi)" ]; then
    rmdir rofi
    echo "Pasta rofi vazia removida."
  else
    echo "Aviso: Pasta rofi ainda contém arquivos não processados."
  fi
fi

# Limpa config vazia
if [ -d "config" ] && [ -z "$(ls -A config)" ]; then
  rmdir config
  echo "Pasta config vazia removida."
fi

echo "Reorganização completa!"
echo "Estrutura agora:"
echo " - Pacotes em .config/: qtile/.config/qtile , alacritty/.config/alacritty , etc."
echo " - bash/.bashrc e bash/.aliases (stow bash → symlinka ~/,bashrc e ~/,aliases)"
echo " - bin-package/.bin/ (stow bin-package → symlinka ~/.bin inteiro)"
echo " - rofi-package/.local/share/rofi/{scripts,themes} (stow rofi-package → symlinka ~/.local/share/rofi/)"
echo ""
echo "Instalação exemplo:"
echo " stow qtile alacritty rofi-package bash bin-package # etc."
echo "Teste com: stow -n -v rofi-package (simula)"
