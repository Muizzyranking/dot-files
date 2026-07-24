#!/usr/bin/env zsh

[[ -o interactive ]] || return

ZSH_CONFIG="${ZSH_CONFIG:-$HOME/.config/zsh}"

load() {
    local f="$ZSH_CONFIG/$1"
    [[ -f "$f" ]] && source "$f"
}

load ".zshenv"
load "options.zsh"
load "keybinds.zsh"
load "plugin_manager.zsh"

load_plugin "zsh-users/zsh-autosuggestions"
load_plugin "zsh-users/zsh-history-substring-search"
load_plugin "Aloxaf/fzf-tab"
load_plugin "hlissner/zsh-autopair"
load_plugin "zdharma-continuum/fast-syntax-highlighting"

load "oh_my_posh.zsh"

command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

command -v fzf &>/dev/null && eval "$(fzf --zsh)"

[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
nvm() {
    unset -f nvm node npm npx
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    nvm "$@"
}

# node() { nvm && node "$@" }
# npm() { nvm && npm "$@" }
# npx() { nvm && npx "$@" }

command -v uv &>/dev/null && eval "$(uv generate-shell-completion zsh)"
command -v thefuck &>/dev/null && eval "$(thefuck --alias)"

export PNPM_HOME="/home/muizzyranking/.local/share/pnpm/bin"
typeset -U path PATH

path=(
    ~/.local/bin
    ~/.cargo/bin
    ~/.npm-global/bin
    ~/bin/lua_ls/bin
    /usr/local/go/bin
    ~/.bun/bin
    ~/.spicetify
    ~/.opencode/bin
    ~/dot-files/bin
    /snap/bin
    $PNPM_HOME
    $path
)

load "aliases.zsh"
load "functions.zsh"
# load "fahh.zsh"
