# ═══════════════════════════════════════════════
# SECCIÓN 1: Siempre corre (login + no-interactivo)
# Solo PATH y variables esenciales
# ═══════════════════════════════════════════════

# Detect Termux
set -l IS_TERMUX 0
if test -n "$TERMUX_VERSION"; or test -d /data/data/com.termux
    set IS_TERMUX 1
end

if test $IS_TERMUX -eq 1
    set -x PATH $PREFIX/bin $HOME/.local/bin $HOME/.cargo/bin $PATH
else if test (uname) = Darwin
    if test -f /opt/homebrew/bin/brew
        set BREW_BIN /opt/homebrew/bin/brew
    else if test -f /usr/local/bin/brew
        set BREW_BIN /usr/local/bin/brew
    end
    set -x PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.cargo/bin $PATH
else
    # Linux
    set BREW_BIN /home/linuxbrew/.linuxbrew/bin/brew
    set -x PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.cargo/bin $PATH
end

# Brew shellenv — solo si existe
if test $IS_TERMUX -eq 0; and set -q BREW_BIN; and test -f $BREW_BIN
    eval ($BREW_BIN shellenv)
end

# Editor
set -gx EDITOR nvim
set -gx VISUAL nvim

# ═══════════════════════════════════════════════
# SECCIÓN 2: Solo para sesiones interactivas
# Todo lo visual, tools de shell, tmux, etc.
# Nvim NUNCA llega hasta aquí
# ═══════════════════════════════════════════════

if status is-interactive

    # Fisher
    if not functions -q fisher
        curl -sL https://git.io/fisher | source
        fisher install jorgebucaran/fisher
    end

    # Tmux — solo en terminal real, no dentro de nvim
    # NVIM_LISTEN_ADDRESS o VIM indican que estamos dentro de nvim
    if not set -q TMUX; and not set -q VIM; and not set -q NVIM
        tmux
    end

    # Tools init — solo interactivo
    starship init fish | source
    zoxide init fish | source
    atuin init fish | source
    fzf --fish | source

    # Carapace
    set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
    if not test -f ~/.config/fish/completions/.initialized
        mkdir -p ~/.config/fish/completions
        carapace --list | awk '{print $1}' | xargs -I{} touch ~/.config/fish/completions/{}.fish
        touch ~/.config/fish/completions/.initialized
    end
    carapace _carapace | source

    # Vi mode
    fish_vi_key_bindings

    # Greeting
    set -g fish_greeting ""

    # Aliases
    if test (uname) = Darwin
        alias ls='ls --color=auto'
    else
        alias ls='gls --color=auto'
    end
    alias fzfbat='fzf --preview="bat --theme=gruvbox-dark --color=always {}"'
    alias fzfnvim='nvim (fzf --preview="bat --theme=gruvbox-dark --color=always {}")'

    # Colores de Fish
    set -l foreground F3F6F9 normal
    set -l selection 263356 normal
    set -l comment 8394A3 brblack
    set -l red CB7C94 red
    set -l orange DEBA87 orange
    set -l yellow FFE066 yellow
    set -l green B7CC85 green
    set -l purple A3B5D6 purple
    set -l cyan 7AA89F cyan
    set -l pink FF8DD7 magenta

    set -g fish_color_normal $foreground
    set -g fish_color_command $cyan
    set -g fish_color_keyword $pink
    set -g fish_color_quote $yellow
    set -g fish_color_redirection $foreground
    set -g fish_color_end $orange
    set -g fish_color_error $red
    set -g fish_color_param $purple
    set -g fish_color_comment $comment
    set -g fish_color_selection --background=$selection
    set -g fish_color_search_match --background=$selection
    set -g fish_color_operator $green
    set -g fish_color_escape $pink
    set -g fish_color_autosuggestion $comment

    set -g fish_pager_color_progress $comment
    set -g fish_pager_color_prefix $cyan
    set -g fish_pager_color_completion $foreground
    set -g fish_pager_color_description $comment

    clear

end
