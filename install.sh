#!/usr/bin/env bash
# ==============================================================================
# Master Limine Theme Installer
# Author: John Varghese (J0X)
# LinkedIn: /in/John--Varghese/
# GitHub: John-Varghese-EH
# Description: Interactive Limine Theme Manager for modifying bootloader UI.
# ==============================================================================

set -Euo pipefail

# ─────────────────────── Terminal Auto-Launcher ────────────────
if [[ ! -t 1 ]]; then
    for term in foot kitty alacritty wezterm gnome-terminal konsole xterm; do
        if command -v "$term" >/dev/null 2>&1; then
            exec "$term" -e "$0" "$@"
        fi
    done
    echo "Error: No terminal emulator found. Please run this script in a terminal." >&2
    exit 1
fi

# ─────────────────────── Error Handling ──────────────────────
ERRORS=0
WARNINGS=0
FAILED_CMDS=()
trap 'FAILED_CMDS+=("Line $LINENO: $BASH_COMMAND"); ((ERRORS++)) || true' ERR

# ─────────────────────── Constants ───────────────────────
readonly BOLD="\033[1m"
readonly RESET="\033[0m"
readonly GREEN="\033[32m"
readonly BLUE="\033[34m"
readonly RED="\033[31m"
readonly YELLOW="\033[33m"
readonly CYAN="\033[36m"
readonly DIM="\033[2m"

readonly LIMINE_CONF="/boot/limine.conf"
readonly BACKUP_DIR="/boot/limine_backups"
readonly THEME_FILE="theme.conf"
readonly DEFAULT_BG="background.jpeg"

# ─────────────────────── Variables ───────────────────────
CUSTOM_BG="$DEFAULT_BG"
CUSTOM_BRANDING="Bootloader - J0X"
CUSTOM_PALETTE="Pitch Black"
UNINSTALL=false
DRY_RUN=false
INTERACTIVE=true

# ─────────────────────── Functions ───────────────────────
log_info() { echo -e "  ${CYAN}INFO${RESET}  | $*"; }
log_success() { echo -e "  ${GREEN}OK${RESET}    | $*"; }
log_warn() { echo -e "  ${YELLOW}WARN${RESET}  | $*"; ((WARNINGS++)) || true; }
log_error() { echo -e "  ${RED}ERROR${RESET} | $*"; }

print_header() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "  ╔═══════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                   ║"
    echo "  ║       ██╗ ██████╗ ██╗  ██╗    ██████╗  ██████╗  ██████╗ ████████╗ ║"
    echo "  ║       ██║██╔═══██╗╚██╗██╔╝    ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝ ║"
    echo "  ║       ██║██║   ██║ ╚███╔╝     ██████╔╝██║   ██║██║   ██║   ██║    ║"
    echo "  ║  ██   ██║██║   ██║ ██╔██╗     ██╔══██╗██║   ██║██║   ██║   ██║    ║"
    echo "  ║  ╚█████╔╝╚██████╔╝██╔╝ ██╗    ██████╔╝╚██████╔╝╚██████╔╝   ██║    ║"
    echo "  ║   ╚════╝  ╚═════╝ ╚═╝  ╚═╝    ╚═════╝  ╚═════╝  ╚═════╝    ╚═╝    ║"
    echo "  ║                                                                   ║"
    echo "  ║             Limine Theme Installer - Interactive Manager          ║"
    echo "  ║             By John Varghese (J0X)                                ║"
    echo "  ║                                                                   ║"
    echo "  ╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

print_results() {
    echo ""
    echo "  ────────────────────────────────────────────────────────────────"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}${BOLD}DRY RUN COMPLETE${RESET}"
    elif [[ $ERRORS -gt 0 ]]; then
        echo -e "  ${RED}${BOLD}Operation completed with $ERRORS error(s)${RESET}"
        if [[ ${#FAILED_CMDS[@]} -gt 0 ]]; then
            echo -e "  ${RED}Failed Commands:${RESET}"
            for cmd in "${FAILED_CMDS[@]}"; do
                echo -e "    ${DIM}• $cmd${RESET}"
            done
        fi
    else
        echo -e "  ${GREEN}${BOLD}Operation Complete!${RESET}"
    fi

    echo ""
    [[ $WARNINGS -gt 0 ]] && echo -e "  ${YELLOW}$WARNINGS warning(s) occurred.${RESET}"
    echo ""
}

show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --bg <file>       Specify a custom background image"
    echo "  --branding <text> Specify custom branding text (e.g. 'Welcome')"
    echo "  --dry-run         Show what would happen without making changes"
    echo "  --uninstall       Restore the most recent backup"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Run without arguments to launch the Interactive Theme Manager."
    echo ""
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --bg)
                CUSTOM_BG="$2"
                INTERACTIVE=false
                shift 2
                ;;
            --branding)
                CUSTOM_BRANDING="$2"
                INTERACTIVE=false
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                INTERACTIVE=false
                shift
                ;;
            --uninstall)
                UNINSTALL=true
                INTERACTIVE=false
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

ensure_root() {
    if [[ $EUID -ne 0 && "$DRY_RUN" == false ]]; then
        log_error "This script must be run as root to modify the bootloader."
        echo "Try: sudo $0"
        exit 1
    fi
}

do_backup() {
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would backup $LIMINE_CONF"
        return
    fi

    if [[ ! -f "$LIMINE_CONF" ]]; then
        log_error "Limine configuration not found at $LIMINE_CONF"
        return
    fi

    mkdir -p "$BACKUP_DIR"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/limine.conf.bak.${timestamp}"
    
    cp "$LIMINE_CONF" "$backup_file"
    log_success "Created backup: $backup_file"
}

do_uninstall() {
    log_info "Starting restoration..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would restore latest backup from $BACKUP_DIR"
        return
    fi

    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_error "No backups directory found at $BACKUP_DIR"
        return
    fi

    local latest_backup
    latest_backup=$(ls -t "${BACKUP_DIR}"/limine.conf.bak.* 2>/dev/null | head -n1 || true)

    if [[ -z "$latest_backup" ]]; then
        log_error "No backup files found."
        return
    fi

    cp "$latest_backup" "$LIMINE_CONF"
    log_success "Restored from $latest_backup"
}

generate_proposed_config() {
    local target_bg="$CUSTOM_BG"
    local core_globals=""
    local boot_entries=""
    local theme_settings=""

    if [[ -f "$LIMINE_CONF" ]]; then
        # Extract core global settings (timeout, default_entry, etc)
        core_globals=$(grep -E '^(timeout|default_entry|remember_last_entry):' "$LIMINE_CONF" || true)
        
        # Extract boot entries (everything from the first line starting with '/')
        boot_entries=$(awk '/^\// {found=1} {if(found) print}' "$LIMINE_CONF" || true)
    fi

    if [[ -f "$THEME_FILE" ]]; then
        theme_settings=$(cat "$THEME_FILE" || true)
    else
        theme_settings="# Missing theme.conf"
    fi

    # Apply custom branding
    theme_settings=$(echo "$theme_settings" | sed "s/interface_branding:.*/interface_branding: \"$CUSTOM_BRANDING\"/")

    # Apply custom palette
    if [[ "$CUSTOM_PALETTE" == "Kawaii" ]]; then
        theme_settings=$(echo "$theme_settings" | sed "s/term_background:.*/term_palette: 1e1e2e;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4\nterm_foreground: cdd6f4\nterm_background: FF1e1e2e/")
    fi

    echo "# =========================================================="
    echo "# Limine Configuration (Managed by J0X Theme Installer)"
    echo "# =========================================================="
    echo ""
    echo "$core_globals"
    echo ""
    echo "$theme_settings"
    echo "wallpaper: boot():/limine-bg.jpeg"
    echo ""
    echo "$boot_entries"
}

build_new_config() {
    local target_bg="$CUSTOM_BG"
    
    if [[ ! -f "$target_bg" ]]; then
        log_error "Background image not found: $target_bg"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would copy $target_bg to /boot/limine-bg.jpeg"
    else
        cp "$target_bg" /boot/limine-bg.jpeg
        log_success "Installed background image."
    fi

    log_info "Parsing existing boot entries..."

    local new_config
    new_config=$(generate_proposed_config)

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would generate new $LIMINE_CONF"
    else
        echo "$new_config" > "$LIMINE_CONF"
        log_success "Successfully injected theme into $LIMINE_CONF"
    fi
}

view_bootloader_layout() {
    echo ""
    echo -e "  ${CYAN}${BOLD}Current Bootloader Hierarchy:${RESET}"
    echo "  ────────────────────────────────────────────────────────────────"
    if command -v limine-entry-tool >/dev/null 2>&1; then
        limine-entry-tool --tree || log_error "Failed to run limine-entry-tool."
    else
        if [[ -f "$LIMINE_CONF" ]]; then
            awk '/^\// {print "  " $0}' "$LIMINE_CONF"
        else
            echo "  $LIMINE_CONF not found."
        fi
    fi
    echo "  ────────────────────────────────────────────────────────────────"
    echo ""
    read -rp "  Press Enter to continue..."
}

view_proposed_config() {
    echo ""
    echo -e "  ${CYAN}${BOLD}Proposed /boot/limine.conf:${RESET}"
    echo "  ────────────────────────────────────────────────────────────────"
    generate_proposed_config | while IFS= read -r line; do
        echo "  $line"
    done
    echo "  ────────────────────────────────────────────────────────────────"
    echo ""
    read -rp "  Press Enter to continue..."
}

interactive_menu() {
    while true; do
        print_header
        echo -e "  ${BOLD}Current Settings:${RESET}"
        echo -e "    Branding : ${CYAN}$CUSTOM_BRANDING${RESET}"
        echo -e "    Palette  : ${CYAN}$CUSTOM_PALETTE${RESET}"
        echo -e "    Wallpaper: ${CYAN}$CUSTOM_BG${RESET}"
        echo ""
        echo "  1) Install Theme"
        echo "  2) Customize Branding Text"
        echo "  3) Change Color Palette"
        echo "  4) View Current Bootloader Layout"
        echo "  5) Preview Proposed Configuration"
        echo "  6) Restore Previous Backup"
        echo "  0) Exit"
        echo ""
        read -rp "  Select an option [0-6]: " choice

        case $choice in
            1)
                ensure_root
                do_backup
                build_new_config
                print_results
                exit 0
                ;;
            2)
                read -rp "  Enter new branding text: " new_branding
                if [[ -n "$new_branding" ]]; then
                    CUSTOM_BRANDING="$new_branding"
                fi
                ;;
            3)
                echo ""
                echo "  Available Palettes:"
                echo "  1) Pitch Black (Minimalist)"
                echo "  2) Kawaii (Catppuccin-inspired)"
                read -rp "  Select palette [1-2]: " pal_choice
                case $pal_choice in
                    1) CUSTOM_PALETTE="Pitch Black" ;;
                    2) CUSTOM_PALETTE="Kawaii" ;;
                    *) echo "  Invalid selection." ; sleep 1 ;;
                esac
                ;;
            4)
                view_bootloader_layout
                ;;
            5)
                view_proposed_config
                ;;
            6)
                ensure_root
                do_uninstall
                print_results
                exit 0
                ;;
            0)
                echo "  Exiting..."
                exit 0
                ;;
            *)
                echo "  Invalid option."
                sleep 1
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    
    if [[ "$INTERACTIVE" == true ]]; then
        interactive_menu
    else
        print_header
        if [[ "$UNINSTALL" == true ]]; then
            ensure_root
            do_uninstall
            print_results
            exit 0
        fi

        ensure_root
        log_info "Starting silent installation..."
        do_backup
        build_new_config
        print_results
    fi
}

main "$@"
