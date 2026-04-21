#!/bin/bash
set -e
set -o pipefail

VERSION="2.0.0"

RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"

BOX_TOP_LEFT="╔"
BOX_TOP_RIGHT="╗"
BOX_BOTTOM_LEFT="╚"
BOX_BOTTOM_RIGHT="╝"
BOX_HORIZONTAL="═"
BOX_VERTICAL="║"
BOX_T_DOWN="╦"
BOX_T_UP="╩"
BOX_T_RIGHT="╠"
BOX_T_LEFT="╣"

DRY_RUN=false
VERBOSE=false
INTERACTIVE=true

print_box() {
    local title="$1"
    local width=60
    local title_len=${#title}
    local pad=$(( (width - title_len - 2) / 2 ))
    
    echo -en "${CYAN}${BOX_TOP_LEFT}${BOX_HORIZONTAL}$(printf '%0.s' $BOX_HORIZONTAL | head -c $pad)${RESET}"
    echo -en "${BOLD}${title}${RESET}"
    echo -en "${CYAN}$(printf '%0.s' $BOX_HORIZONTAL | head -c $((width - pad - title_len - 2)))${BOX_TOP_RIGHT}${RESET}"
    echo
}

print_line() {
    echo -en "${CYAN}${BOX_VERTICAL}${RESET}"
    printf "%-$((60))s" "$1"
    echo -en "${CYAN}${BOX_VERTICAL}${RESET}"
    echo
}

print_box_bottom() {
    echo -en "${CYAN}${BOX_BOTTOM_LEFT}${BOX_HORIZONTAL}$(printf '%0.s' $BOX_HORIZONTAL | head -c 58)${BOX_BOTTOM_RIGHT}${RESET}"
    echo
}

log_info() {
    echo -e "${CYAN}○${RESET} $1"
}

log_success() {
    echo -e "${GREEN}✓${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠️ ${RESET} $1"
}

log_error() {
    echo -e "${RED}✗${RESET} $1"
}

log_step() {
    echo -e "${MAGENTA}🔧${RESET} ${BOLD}$1${RESET}"
}

log_verbose() {
    [ "$VERBOSE" = true ] && echo -e "${DIM}  →${RESET} $1"
}

ask() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    while true; do
        echo -en "${CYAN}?${RESET} ${prompt} [${default^^}] "
        read -r response
        
        if [ -z "$response" ]; then
            response="$default"
        fi
        
        case "$response" in
            s|S|y|Y) return 0 ;;
            n|N) return 1 ;;
        esac
    done
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

get_version() {
    local cmd="$1"
    local version=""
    set +e
    
    case "$cmd" in
        tmux) version=$(tmux -V 2>/dev/null | awk '{print $2}') ;;
        ghostty) version=$(ghostty +version 2>/dev/null | awk '{print $2}') ;;
        fish) version=$(fish --version 2>/dev/null | awk '{print $3}') ;;
        nvim) version=$(nvim --version 2>/dev/null | head -1 | awk '{print $2}') ;;
        starship) version=$(starship --version 2>/dev/null | head -1 | awk '{print $2}') ;;
        alacritty) version=$(alacritty --version 2>/dev/null | head -1 | awk '{print $2}') ;;
        lazygit) version=$(lazygit --version 2>/dev/null | awk '{print $3}') ;;
    esac
    
    set -e
    echo "$version"
}

check_brew() {
    if check_command brew; then
        return 0
    fi
    return 1
}

install_brew() {
    log_warn "Brew no encontrado en PATH"
    
    if ask "¿Instalar Homebrew?"; then
        log_step "Instalando Homebrew..."
        
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>/dev/null
        
        if check_command brew; then
            log_success "Homebrew instalado"
            
            local shell_rc=""
            if [ -f "$HOME/.bashrc" ]; then
                shell_rc="$HOME/.bashrc"
            elif [ -f "$HOME/.profile" ]; then
                shell_rc="$HOME/.profile"
            fi
            
            if [ -n "$shell_rc" ]; then
                if ! grep -q "homebrew" "$shell_rc" 2>/dev/null; then
                    echo '' >> "$shell_rc"
                    echo '# Homebrew' >> "$shell_rc"
                    echo 'export PATH="/usr/local/bin:$PATH"' >> "$shell_rc"
                fi
            fi
            
            export PATH="/usr/local/bin:$PATH"
            return 0
        else
            log_error "Error al instalar Homebrew"
            return 1
        fi
    fi
    return 1
}

check_app() {
    local app="$1"
    check_command "$app"
}

install_app() {
    local app="$1"
    local install_cmd="$2"
    
    log_step "Instalando $app..."
    
    if eval "$install_cmd"; then
        log_success "$app instalado"
        return 0
    else
        log_error "Error al instalar $app"
        return 1
    fi
}



create_link() {
    local src="$1"
    local dst="$2"
    
    if [ ! -e "$src" ]; then
        log_error "Origen no existe: $src"
        return 1
    fi
    
    local is_dir=false
    if [ -d "$dst" ] && [ ! -L "$dst" ]; then
        is_dir=true
    fi
    
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        if [ "$is_dir" = true ]; then
            local count=$(ls -1 "$dst" 2>/dev/null | wc -l)
            if [ "$INTERACTIVE" = true ]; then
                log_warn "$dst es un directorio con $count archivos"
                if ! ask "¿Eliminar y reemplazar por symlink?"; then
                    log_warn "Omitido: $dst"
                    return 2
                fi
            fi
        else
            if [ "$INTERACTIVE" = true ]; then
                if ! ask "¿Respaldar $dst?"; then
                    log_warn "Omitido: $dst"
                    return 2
                fi
            fi
        fi
        local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
        rm -rf "$dst"
        mv "$(dirname "$dst")/$(basename "$dst")" "$backup" 2>/dev/null || mv "$dst" "$backup"
        log_success "Respaldado → $backup"
    fi
    
    if [ -d "$src" ]; then
        rm -rf "$dst"
    fi
    
    ln -sf "$src" "$dst"
    log_success "Linkeado: $dst"
    log_verbose "  → $(readlink -f "$dst")"
    return 0
}

verify_links() {
    local failed=0
    
    echo
    log_step "Verificando symlinks..."
    
    for link in "${!LINK_MAP[@]}"; do
        if [ -L "$link" ] && [ -e "$link" ]; then
            log_verbose "✓ $link"
        else
            log_error "✗ $link"
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log_success "Todos los symlinks verificados"
        return 0
    else
        log_error "$failed symlinks fallidos"
        return 1
    fi
}

declare -A APPS=(
    ["tmux"]="brew install tmux"
    ["ghostty"]="brew tap homebrew/core && brew install ghostty"
    ["fish"]="brew install fish"
    ["nvim"]="brew install neovim"
    ["starship"]="brew install starship"
    ["alacritty"]="brew install alacritty"
    ["lazygit"]="brew install lazygit"
)

declare -A LINK_MAP
declare -A APP_STATUS

scan_system() {
    log_step "Escaneando sistema..."
    
    set +e
    
    local -a APP_LIST=(tmux ghostty fish nvim starship alacritty lazygit)
    
    for app in "${APP_LIST[@]}"; do
        local status="missing"
        if command -v "$app" >/dev/null 2>&1; then
            status="installed"
            log_verbose "$app: instalado"
        else
            log_verbose "$app: no instalado"
        fi
        APP_STATUS[$app]="$status"
    done
    
    set -e
    
    if check_brew; then
        APP_STATUS["brew"]="installed"
    else
        APP_STATUS["brew"]="missing"
    fi
}

print_status() {
    local width=58
    local apps_installed=0
    local -a APP_LIST=(tmux ghostty fish nvim starship alacritty lazygit)
    local apps_total=${#APP_LIST[@]}
    local line
    
    echo
    line=$(printf "%${width}s" "")
    echo -e "${CYAN}${BOX_TOP_LEFT}${line:0:$width}${BOX_TOP_RIGHT}${RESET}"
    
    echo -e "${CYAN}${BOX_VERTICAL}$(printf "%$((width))s" "")${BOX_VERTICAL}${RESET}"
    echo -e "${CYAN}${BOX_VERTICAL}  📦 Estado del sistema:$(printf "%$((width - 22))s" "")${BOX_VERTICAL}${RESET}"
    echo -e "${CYAN}${BOX_VERTICAL}$(printf "%$((width))s" "")${BOX_VERTICAL}${RESET}"
    
    for app in "${APP_LIST[@]}"; do
        local status="${APP_STATUS[$app]:-missing}"
        local symbol="[✗]"
        local color="$RED"
        
        if [ "$status" = "installed" ]; then
            symbol="[✓]"
            color="$GREEN"
            apps_installed=$((apps_installed + 1))
        fi
        
        local entry="  ${color}${symbol}${RESET} $app"
        echo -e "${CYAN}${BOX_VERTICAL}$(printf "%-${width}s" "$entry")${BOX_VERTICAL}${RESET}"
    done
    
    echo -e "${CYAN}${BOX_VERTICAL}$(printf "%$((width))s" "")${BOX_VERTICAL}${RESET}"
    echo -e "${CYAN}${BOX_VERTICAL}  Resumen: $apps_installed/$apps_total apps instaladas$(printf "%$((width - 32))s" "")${BOX_VERTICAL}${RESET}"
    
    line=$(printf "%${width}s" "")
    echo -e "${CYAN}${BOX_BOTTOM_LEFT}${line:0:$width}${BOX_BOTTOM_RIGHT}${RESET}"
}

show_menu() {
    local width=58
    local line
    
    line=$(printf "%${width}s" "")
    echo -e "${CYAN}${BOX_TOP_LEFT}${line:0:$width}${BOX_TOP_RIGHT}${RESET}"
    
    echo -e "${CYAN}${BOX_VERTICAL}$(printf "%$((width))s" "")${BOX_VERTICAL}${RESET}"
    echo -e "${CYAN}${BOX_VERTICAL}$(printf "%-${width}s" "  [I] Instalar apps faltantes + symlinks")${BOX_VERTICAL}${RESET}"
    echo -e "${CYAN}${BOX_VERTICAL}$(printf "%-${width}s" "  [A] Reinstalar todos los symlinks (con backup)")${BOX_VERTICAL}${RESET}"
    echo -e "${CYAN}${BOX_VERTICAL}$(printf "%-${width}s" "  [C] Solo crear symlinks (apps ya instaladas)")${BOX_VERTICAL}${RESET}"
    echo -e "${CYAN}${BOX_VERTICAL}$(printf "%-${width}s" "  [V] Verbose (activar)")${BOX_VERTICAL}${RESET}"
    echo -e "${CYAN}${BOX_VERTICAL}$(printf "%-${width}s" "  [Q] Salir")${BOX_VERTICAL}${RESET}"
    echo -e "${CYAN}${BOX_VERTICAL}$(printf "%$((width))s" "")${BOX_VERTICAL}${RESET}"
    
    line=$(printf "%${width}s" "")
    echo -e "${CYAN}${BOX_BOTTOM_LEFT}${line:0:$width}${BOX_BOTTOM_RIGHT}${RESET}"
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --verbose|-v)
                VERBOSE=true
                ;;
            --non-interactive|-y)
                INTERACTIVE=false
                ;;
            --help|-h)
                echo "Uso: $0 [--verbose] [--non-interactive]"
                echo "  --verbose, -v    Salida detallada"
                echo "  --non-interactive, -y  No preguntar (usar defaults)"
                exit 0
                ;;
            *)
                ;;
        esac
        shift
    done
}

main() {
    parse_args "$@"
    
    local title="  GRINGO.DEV DOTFILES INSTALLER v${VERSION}"
    local width=58
    
    echo
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 60) | tr '\n' '=')${RESET}"
    echo -e "${BOLD}${MAGENTA}${BOX_TOP_LEFT}==========================================================${BOX_TOP_RIGHT}${RESET}"
    echo -e "${BOLD}${MAGENTA}${BOX_VERTICAL}$(printf "%-58s" "$title")${BOX_VERTICAL}${RESET}"
    echo -e "${BOLD}${MAGENTA}${BOX_BOTTOM_LEFT}==========================================================${BOX_BOTTOM_RIGHT}${RESET}"
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 60) | tr '\n' '=')${RESET}"
    
    if [ "$(uname -s)" != "Linux" ]; then
        log_error "Este script solo funciona en Linux"
        exit 1
    fi
    
    DOTFILES_DIR="$HOME/dotfiles"
    if [ ! -d "$DOTFILES_DIR" ]; then
        log_error "No se encontró $DOTFILES_DIR"
        exit 1
    fi
    
    log_success "Directorio dotfiles: $DOTFILES_DIR"
    
    if ! check_brew; then
        if ! install_brew; then
            log_warn "Brew no disponible, se omitirá instalación de apps"
        fi
    else
        APP_STATUS["brew"]="installed"
    fi
    
    scan_system
    print_status
    
    if [ "$INTERACTIVE" = false ]; then
        install_missing_apps
        create_all_links
        exit 0
    fi
    
    while true; do
        show_menu
        echo
        echo -en "${CYAN}?${RESET} Opción: "
        read -r option
        
        case "$option" in
            i|I)
                install_missing_apps
                create_all_links
                ;;
            a|A)
                force_all_links
                ;;
            c|C)
                create_all_links
                ;;
            v|V)
                VERBOSE=true
                echo "Verbose activado"
                ;;
            q|Q)
                echo
                log_info "Saliendo..."
                exit 0
                ;;
            *)
                log_error "Opción inválida"
                ;;
        esac
        
        if [ "$?" -eq 0 ]; then
            break
        fi
    done
}

install_missing_apps() {
    log_step "Instalando apps faltantes..."
    
    local -a APP_LIST=(tmux ghostty fish nvim starship alacritty lazygit)
    
    for app in "${APP_LIST[@]}"; do
        local status="${APP_STATUS[$app]:-missing}"
        
        if [ "$status" = "missing" ]; then
            echo
            log_info "$app no instalado"
            
            if [ "$INTERACTIVE" = true ]; then
                if ! ask "¿Instalar $app?"; then
                    log_verbose "Omitido: $app"
                    continue
                fi
            fi
            
            local install_cmd="${APPS[$app]}"
            install_app "$app" "$install_cmd"
            
            if check_app "$app"; then
                local ver
                ver=$(get_version "$app")
                APP_STATUS[$app]="installed:${ver}"
            fi
        else
            log_verbose "$app ya instalado"
        fi
    done
    
    log_success "Instalación de apps completada"
}

create_all_links() {
    log_step "Creando symlinks..."
    
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.config/tmux"
    mkdir -p "$HOME/.config/ghostty"
    mkdir -p "$HOME/.config/fish"
    mkdir -p "$HOME/.config/alacritty"
    mkdir -p "$HOME/.config/lazygit"
    
    declare -A LINK_MAP
    LINK_MAP["$HOME/.config/tmux/tmux.conf"]="$DOTFILES_DIR/tmux/tmux.conf"
    LINK_MAP["$HOME/.tmux.conf"]="$DOTFILES_DIR/tmux/tmux.conf"
    LINK_MAP["$HOME/.config/ghostty/config"]="$DOTFILES_DIR/ghostty/config"
    LINK_MAP["$HOME/.config/fish/config.fish"]="$DOTFILES_DIR/fish/config.fish"
    LINK_MAP["$HOME/.config/starship.toml"]="$DOTFILES_DIR/starship/starship.toml"
    LINK_MAP["$HOME/.config/alacritty/alacritty.toml"]="$DOTFILES_DIR/alacritty/alacritty.toml"
    LINK_MAP["$HOME/.config/lazygit/config.yml"]="$DOTFILES_DIR/lazygit/config.yml"
    LINK_MAP["$HOME/.config/nvim"]="$DOTFILES_DIR/nvim"
    
    if [ -f "$DOTFILES_DIR/git/.gitconfig" ]; then
        LINK_MAP["$HOME/.gitconfig"]="$DOTFILES_DIR/git/.gitconfig"
    fi
    
    local success=0
    local failed=0
    local skipped=0
    
    for dst in "${!LINK_MAP[@]}"; do
        local src="${LINK_MAP[$dst]}"
        
        if [ ! -f "$src" ] && [ ! -d "$src" ]; then
            log_warn "Origen no existe: $src"
            skipped=$((skipped + 1))
            continue
        fi
        
        if [ "$INTERACTIVE" = true ]; then
            if ! ask "¿Linkear $dst?"; then
                log_verbose "Omitido: $dst"
                skipped=$((skipped + 1))
                continue
            fi
        fi
        
        if create_link "$src" "$dst"; then
            success=$((success + 1))
        else
            failed=$((failed + 1))
        fi
    done
    
    echo
    log_success "Symlinks creados: $success"
    [ $skipped -gt 0 ] && log_info "Omitidos: $skipped"
    [ $failed -gt 0 ] && log_error "Fallidos: $failed"
    
    verify_links
}

force_all_links() {
    log_step "Forzando todos los symlinks (con backup)..."
    INTERACTIVE=true
    
    create_all_links
}

main "$@"