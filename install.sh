#!/bin/bash
set -e

echo "🚀 Instalando dotfiles..."

# Crear carpetas necesarias
mkdir -p ~/.config/tmux
mkdir -p ~/.config/ghostty
mkdir -p ~/.config/fish
mkdir -p ~/.config

# tmux
ln -sf ~/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf
ln -sf ~/.config/tmux/tmux.conf ~/.tmux.conf

# ghostty
ln -sf ~/dotfiles/ghostty/config ~/.config/ghostty/config

# fish
ln -sf ~/dotfiles/fish/config.fish ~/.config/fish/config.fish

# nvim
ln -sf ~/dotfiles/nvim ~/.config/nvim

# starship
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# alacritty
ln -sf ~/dotfiles/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml

# lazygit
ln -sf ~/dotfiles/lazygit ~/.config/lazygit

# git
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig

echo "✅ Dotfiles instalados"
