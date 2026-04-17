#!/usr/bin/env zsh

typeset -U path

export PNPM_HOME="/home/muizzyranking/.local/share/pnpm"

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

export EDITOR=nvim
export SUDO_EDITOR=$EDITOR

export DOTFILES=~/dot-files
export CONFIG=$DOTFILES/config

export NVIMRC=$DOTFILES/config/nvim
export ZSHRC=$DOTFILES/home/.zshrc
export ZSHENV=$CONFIG/zsh/.zshenv
export ALIASES=$CONFIG/zsh/.zsh_aliases
export TMUXRC=$CONFIG/tmux/tmux.conf

export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/.local/share/pnpm"
export NVM_DIR="$HOME/.nvm"

if [[ -f "$HOME/.cache/nvim/lazygit-theme.yml" ]]; then
    export LG_CONFIG_FILE="$HOME/.cache/nvim/lazygit-theme.yml"
fi

export FZF_DEFAULT_OPTS="
--color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
--color=fg+:#c0caf5,bg+:#283457,hl+:#7dcfff
--color=info:#7aa2f7,prompt:#f7768e,pointer:#bb9af7
--color=marker:#9ece6a,spinner:#bb9af7,header:#7aa2f7
--color=border:#565f89,label:#7aa2f7,query:#c0caf5
--border=rounded
--prompt='🔍 '
--pointer='▶'
--marker='✓'
"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

nvm() {
    unset -f nvm node npm npx
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    nvm "$@"
}
node() { nvm && node "$@" }
npm() { nvm && npm "$@" }
npx() { nvm && npx "$@" }
