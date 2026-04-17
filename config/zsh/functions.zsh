#!/usr/bin/env zsh

source "$HOME/.config/zsh/utils.sh" 2>/dev/null || true

aliases() {
    alias | sed 's/=/ => /' | bat --language=bash --style=plain
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
    selected_dir=$(fd --type d --hidden --exclude .git | fzf-tmux -p --reverse) || return
    [[ -n "$selected_dir" ]] && cd "$selected_dir"
}

f() {
    local dir
    dir=$(zoxide query --list --score |
        fzf --height 40% --layout reverse --info inline \
            --nth 2.. --tac --no-sort --query "$*" \
        --bind 'enter:become:echo {2..}') || return
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
    local n="${1:-1}"
    
    [[ "$n" =~ ^[0-9]+$ ]] || { echo "Usage: up [number]"; return 1 }
    [[ "$n" -eq 0 ]] && return 0
    
    local target=""
    for ((i=0; i<n; i++)); do
        target="../$target"
    done
    
    cd "$target" 2>/dev/null || { echo "Can't go up $n levels from here"; return 1 }
}

alias u='up'
