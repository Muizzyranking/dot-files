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
    [[ -z "$1" ]] && { echo "Usage: bak <file>"; return 1 }
    cp "$1" "$1.bak"
    echo "Backed up: $1 -> $1.bak"
}

copypath() {
    echo -n "$PWD" | clipcopy
    echo "Copied: $PWD"
}

extract() {
    [[ -f "$1" ]] || { echo "'$1' is not a valid file"; return 1 }

    case "$1" in
        *.tar.bz2|*.tbz2)  tar xjf "$1" ;;
        *.tar.gz|*.tgz)    tar xzf "$1" ;;
        *.tar.xz)          tar xJf "$1" ;;
        *.tar.zst)         tar --zstd -xf "$1" ;;
        *.bz2)             bunzip2 "$1" ;;
        *.rar)             unrar x "$1" ;;
        *.gz)              gunzip "$1" ;;
        *.tar)             tar xvf "$1" ;;
        *.zip)             unzip "$1" ;;
        *.7z)              7z x "$1" ;;
        *.deb)             dpkg-deb -x "$1" . ;;
        *)                 echo "'$1' cannot be extracted via extract()" ;;
    esac
}

fdir() {
    local selected_dir
    selected_dir=$(fd --type d --hidden --exclude .git | fzf-tmux -p --reverse -q "$1") || return
    [[ -n "$selected_dir" ]] && cd "$selected_dir"
}

f() {
    local dir
    dir=$(zoxide query --list 2>/dev/null |
        fzf --height 40% --layout reverse --info inline \
            --nth 1.. --tac --no-sort --query "$*" \
            --bind 'enter:become:echo {1}') || return
    [[ -n "$dir" ]] && cd "$dir"
}

mkcd() {
    mkdir -p "$1" && cd "$1"
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
