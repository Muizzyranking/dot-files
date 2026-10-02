#!/usr/bin/env zsh

source "$HOME/.config/zsh/utils.sh" 2>/dev/null || true

aliases() {
    alias | awk -F= '
        {
            left[NR] = $1
            right[NR] = $2
            if (length($1) > max) max = length($1)
        }
        END {
            for (i = 1; i <= NR; i++) {
                printf "  %-*s => %s\n", max, left[i], right[i]
            }
        }
    ' | bat --language=bash --style=plain
}

update() {
    if ! command -v yay &> /dev/null; then
        echo "yay is not installed."
        return 1
    fi
    yay -Syu --noconfirm --needed
}

bak() {
    [[ -z "$1" ]] && { print_message "Usage: bak <path>"; return 1; }

    local src="${1%/}"
    [[ -e "$src" ]] || { print_message error "'$src' does not exist"; return 1; }

    local dest="${src}.bak"
    local i=1

    while [[ -e "$dest" ]]; do
        dest="${src}.bak.${i}"
        ((i++))
    done

    if [[ "$(uname)" == "Darwin" ]]; then
        cp -pR "$src" "$dest"
    else
        cp -a "$src" "$dest"
    fi

    print_message "Backed up: $src -> $dest"
}

copypath() {
    echo -n "$PWD" | clipcopy
    echo "Copied: $PWD"
}

fdir() {
    local selected_dir
    selected_dir=$(fd --type d --hidden --exclude .git | fzf-tmux -p --reverse -q "$1") || return
    [[ -n "$selected_dir" ]] && builtin cd "$selected_dir"
}

f() {
    local dir
    dir=$(zoxide query --list 2>/dev/null |
        fzf --height 40% --layout reverse --info inline \
            --nth 1.. --tac --no-sort --query "$*" \
            --bind 'enter:become:echo {1}') || return
    [[ -n "$dir" ]] && builtin cd "$dir"
}

mkcd() {
    mkdir -p "$1" && builtin cd "$1"
}

venv-create() {
    if [[ -d ".venv" ]]; then
        echo ".venv exists, activating..."
        source .venv/bin/activate
        return
    fi

    local prompt_name="${1:-}"
    if [[ -n "$prompt_name" ]]; then
        python3 -m venv .venv --prompt="$prompt_name"
    else
        python3 -m venv .venv
    fi

    source .venv/bin/activate
    echo "Created and activated .venv"
}

up() {
    local levels=1
    local target=""
    
    if [[ $# -gt 0 ]]; then
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            levels="$1"
            shift
            target="$*"
        else
            levels=1
            target="$*"
        fi
    fi
    
    [[ "$levels" -eq 0 && -z "$target" ]] && return 0
    
    local path=""
    for ((i=0; i<levels; i++)); do
        path="../$path"
    done
    
    [[ -n "$target" ]] && path="$path$target"
    
    builtin cd "$path" 2>/dev/null || {
        echo "up: can't reach '$path' from '$(pwd)'" >&2
        return 1
    }
}

reload_completions() {
    local zcomp="$HOME/.zcompdump"
    rm -f "$zcomp" "$zcomp.zwc"
    compinit
    print -P "%F{green}✓%f Completions reloaded."
}

alias u='up'
