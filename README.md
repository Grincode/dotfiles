# Dotfiles

Configuración personal para un workflowDev optimal.

## Estructura

| Directorio | Descripción |
|--------------|-------------|
| `nvim/` | Neovim (LazyVim-based) |
| `fish/` | Fish shell config |
| `tmux/` | Tmux con plugins |
| `starship/` | Starship prompt |
| `lazygit/` | LazyGit config |
| `alacritty/` | Alacritty terminal |
| `ghostty/` | Ghostty terminal |

## Requisitos Previos

- Neovim >= 0.10
- Fish shell >= 3.0
- Tmux >= 3.0
- [LazyVim prerequisites](https://lazyvim.github.io/installation)

## Instalación

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

El script symlinkea cada directorio a `~/.config/`.

## Post-Instalación

1. **Tmux**: Instalar TPM plugins (prefix + I)
2. **Fisher**: Plugins de fish se instalan automáticamente en primera sesión
3. **LazyVim**: Plugins se instalan automáticamente al abrir nvim