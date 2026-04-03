#!/bin/bash
set -e

echo "🚀 Instalando dotfiles..."

DOTFILES_DIR="$HOME/dotfiles"

# Crear carpetas necesarias
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/tmux"
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/fish"
mkdir -p "$HOME/.config/alacritty"
mkdir -p "$HOME/.config/lazygit"

# tmux
ln -sf "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
ln -sf "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"

# ghostty
ln -sf "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

# fish
ln -sf "$DOTFILES_DIR/fish/config.fish" "$HOME/.config/fish/config.fish"

# nvim (carpeta completa)
rm -rf "$HOME/.config/nvim"
ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# starship
ln -sf "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# alacritty
ln -sf "$DOTFILES_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

# lazygit (archivo correcto)
ln -sf "$DOTFILES_DIR/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

# git (solo si existe)
if [ -f "$DOTFILES_DIR/git/.gitconfig" ]; then
  ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
fi

echo "✅ Dotfiles instalados correctamente"
