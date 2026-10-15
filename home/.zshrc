#!/usr/bin/env zsh

[[ -o interactive ]] || return

ZSH_CONFIG="${ZSH_CONFIG:-$HOME/.config/zsh}"

load() {
    local f="$ZSH_CONFIG/$1"
    [[ -f "$f" ]] && source "$f"
}

eval_if_exists() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null || return 0

    local output
    output="$("$@")" || {
        print "eval_if_exists: '$*' failed" >&2
        return 1
    }
    eval "$output"
}

load "env.zsh"

typeset -U path PATH

path=(
    ~/.local/custom-bin
    ~/.local/bin
    ~/.cargo/bin
    ~/.npm-global/bin
    ~/bin/lua_ls/bin
    /usr/local/go/bin
    ~/.bun/bin
    ~/.spicetify
    ~/.opencode/bin
    ~/.kilo/bin
    /snap/bin
    $PNPM_HOME
    $PNPM_HOME/bin
    $path
)

load "options.zsh"
load "keybinds.zsh"
load "plugin_manager.zsh"

load_plugin "zsh-users/zsh-autosuggestions"
load_plugin "zsh-users/zsh-history-substring-search"
load_plugin "Aloxaf/fzf-tab"
load_plugin "hlissner/zsh-autopair"
load_plugin "zdharma-continuum/fast-syntax-highlighting"

load "oh_my_posh.zsh"

eval_if_exists zoxide init zsh
eval_if_exists fzf --zsh
eval_if_exists uv generate-shell-completion zsh
eval_if_exists pay-respects zsh --alias fuck

[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

load "aliases.zsh"
load "functions.zsh"
# load "fahh.zsh"
