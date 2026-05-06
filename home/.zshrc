#!/usr/bin/env zsh

_omp_cache="$HOME/.cache/oh-my-posh-init.zsh"
_omp_config="$HOME/.config/oh-my-posh/config.omp.json"

if [[ ! -f "$_omp_cache" || "$_omp_config" -nt "$_omp_cache" ]]; then
    oh-my-posh init zsh --config "$_omp_config" > "$_omp_cache"
fi

source "$_omp_cache"

export PNPM_HOME="$HOME/.local/share/pnpm"
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


ZSH_CONFIG="${ZSH_CONFIG:-$HOME/.config/zsh}"

load(){
    local filename="$1"
    local full_path="$ZSH_CONFIG/$filename"
    if [ -f "$full_path" ]; then
        source "$full_path"
    fi
}

load ".zshenv"
load "options.zsh"
load "keybindings.zsh"
load "plugin_manager.zsh"

# plugins
load_plugin "zsh-users/zsh-autosuggestions"
load_plugin "zsh-users/zsh-history-substring-search"
load_plugin "Aloxaf/fzf-tab"
load_plugin "hlissner/zsh-autopair"
load_plugin "zdharma-continuum/fast-syntax-highlighting"

eval "$(zoxide init zsh)"

if command -v fzf &>/dev/null; then
    eval "$(fzf --zsh)"
fi

[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
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

load "aliases.zsh"
load "functions.zsh"
# load "fahh.zsh"

# ============================================
# Debug
# ============================================
# zprof > ~/.zsh_startup_profile.txt
