#!/usr/bin/env bash

set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
LOCAL_DIR="$HOME/.local"
HOME_SRC="$DOTS_DIR/home"
BACKUP_DIR="$HOME/config_backup"
BACKUP_TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
_BACKUP_SEQ=0

source "$DOTS_DIR/scripts/utils.sh"

# Entries here are never linked and never listed
IGNORE_LIST=()

# Tasks with custom handling instead of a plain link
SPECIAL_TASKS=("zsh" "git")

# Home files with custom handling, skipped by generic discovery
SPECIAL_HOME_FILES=(".zshrc")

# Set by parse_args
LIST_ONLY=false
WANT_ALL=false
TASKS=()

cleanup() {
    echo
    print_message info "Script interrupted."
    exit 1
}

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        if mkdir -p "$dir"; then
            print_message info "Created directory: $dir"
        else
            print_message error "Failed to create directory: $dir"
            return 1
        fi
    fi
}

is_in() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

is_ignored() {
    is_in "$1" ${IGNORE_LIST[@]+"${IGNORE_LIST[@]}"}
}

# Prints the names of the entries of type $2 (d or f) directly inside $1
list_names() {
    local dir="$1" type="$2"
    [[ -d "$dir" ]] || return 0
    find "$dir" -mindepth 1 -maxdepth 1 -type "$type" -printf '%f\n' | sort
}

# ---------------------------------------------------------------------------
# Linking
# ---------------------------------------------------------------------------

backup_item() {
    local target="$1"
    local name
    name="$(basename "$target")"
    _BACKUP_SEQ=$((_BACKUP_SEQ + 1))
    local backup_name="${name}.bk-${BACKUP_TIMESTAMP}-${_BACKUP_SEQ}"

    ensure_dir "$BACKUP_DIR" || return 1

    if mv "$target" "$BACKUP_DIR/$backup_name"; then
        print_message warning "Backed up: $target → $BACKUP_DIR/$backup_name"
    else
        print_message error "Failed to backup: $target"
        return 1
    fi
}

link_item() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$source" ]]; then
        print_message error "Source does not exist: $source"
        return 1
    fi

    if [[ -L "$target" ]]; then
        local current_link
        current_link="$(readlink "$target")"
        if [[ "$current_link" == "$source" ]]; then
            print_message info "Skipping: $target already links to $source"
            return 0
        fi
        print_message warning "Relinking: $target (was → $current_link)"
        unlink "$target"
    elif [[ -e "$target" ]]; then
        backup_item "$target" || return 1
    fi

    ensure_dir "$(dirname "$target")" || return 1

    if ln -s "$source" "$target"; then
        print_message success "Linked: $source → $target"
    else
        print_message error "Failed to link: $target"
        return 1
    fi
}

link_config_folder() {
    local name="$1"
    link_item "$DOTS_DIR/config/$name" "$CONFIG_DIR/$name"
}

link_home_file() {
    local filename="$1"
    link_item "$HOME_SRC/$filename" "$HOME/$filename"
}

update_desktop_db() {
    local apps_dir="$1"
    [[ -d "$apps_dir" ]] || return 0
    command -v update-desktop-database &>/dev/null || return 0

    if update-desktop-database "$apps_dir" 2>/dev/null; then
        print_message info "Updated desktop database for $apps_dir."
    else
        print_message warning "Could not update desktop database for $apps_dir."
    fi
}

link_local_entry() {
    local name="$1"
    local src="$DOTS_DIR/local/$name"
    local dest="$LOCAL_DIR/$name"

    print_message info "Processing ~/.local/$name..."
    link_item "$src" "$dest" || return 1
    update_desktop_db "$dest/applications"
}

link_zsh() {
    print_message info "Processing Zsh configuration..."
    link_home_file ".zshrc"
    link_config_folder "zsh"
}

link_git() {
    print_message info "Processing Git configuration..."

    local global_git_config="$HOME/.gitconfig"
    if [[ -f "$global_git_config" && ! -L "$global_git_config" ]]; then
        print_message warning "Found .gitconfig at $global_git_config, backing up..."
        backup_item "$global_git_config" || return 1
    fi

    link_config_folder "git"
}

# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

discover_config_names() {
    local name
    list_names "$DOTS_DIR/config" d | while IFS= read -r name; do
        is_in "$name" "${SPECIAL_TASKS[@]}" || printf '%s\n' "$name"
    done
}

discover_home_names() {
    local name
    list_names "$HOME_SRC" f | while IFS= read -r name; do
        is_in "$name" "${SPECIAL_HOME_FILES[@]}" || printf '%s\n' "$name"
    done
}

discover_local_names() {
    list_names "$DOTS_DIR/local" d
}

all_tasks() {
    {
        printf '%s\n' "${SPECIAL_TASKS[@]}"
        discover_config_names
        discover_home_names
        discover_local_names
    } | sort -u | while IFS= read -r name; do
        is_ignored "$name" || printf '%s\n' "$name"
    done
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

run_task() {
    local item="$1"

    case "$item" in
    zsh) link_zsh ;;
    git) link_git ;;
    *)
        if [[ -d "$DOTS_DIR/config/$item" ]]; then
            link_config_folder "$item"
        elif [[ -f "$HOME_SRC/$item" ]]; then
            link_home_file "$item"
        elif [[ -d "$DOTS_DIR/local/$item" ]]; then
            link_local_entry "$item"
        else
            print_message warning "Unknown config or task: $item"
            return 1
        fi
        ;;
    esac
}

run_tasks() {
    local item failed=0

    for item in "$@"; do
        if is_ignored "$item"; then
            print_message info "Ignored: $item"
            continue
        fi
        run_task "$item" || failed=$((failed + 1))
    done

    if [[ $failed -gt 0 ]]; then
        print_message warning "$failed task(s) failed."
        return 1
    fi
    print_message success "Linking complete."
}

dedupe_tasks() {
    local item
    local -A seen=()
    local -a unique=()

    for item in ${TASKS[@]+"${TASKS[@]}"}; do
        if [[ -z "${seen[$item]+x}" ]]; then
            seen[$item]=1
            unique+=("$item")
        fi
    done

    TASKS=(${unique[@]+"${unique[@]}"})
}

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

parse_args() {
    local arg
    for arg in "$@"; do
        case "$arg" in
        -l | --list)
            LIST_ONLY=true
            ;;
        all)
            WANT_ALL=true
            ;;
        -*)
            print_message error "Unknown option: $arg"
            exit 1
            ;;
        *)
            TASKS+=("$arg")
            ;;
        esac
    done
}

list_tasks() {
    all_tasks
}

main() {
    trap cleanup INT TERM

    parse_args "$@"

    if $LIST_ONLY; then
        list_tasks
        exit 0
    fi

    if [[ $# -eq 0 ]] || $WANT_ALL; then
        local name
        while IFS= read -r name; do
            TASKS+=("$name")
        done < <(all_tasks)
    fi

    dedupe_tasks

    setup_logging
    print_header "Linking dotfiles"

    run_tasks ${TASKS[@]+"${TASKS[@]}"}
}

main "$@"
