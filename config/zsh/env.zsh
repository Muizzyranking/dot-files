#!/usr/bin/env zsh

export EDITOR=nvim
export VISUAL="$EDITOR"
export SUDO_EDITOR=$EDITOR

export DOTFILES=~/dot-files
export DOT_FILES_CONFIG=$DOTFILES/config

export BUN_INSTALL="$HOME/.bun"
export NVM_DIR="$HOME/.nvm"
export PNPM_HOME="$HOME/.local/share/pnpm"

if [[ -f "$HOME/.cache/nvim/lazygit-theme.yml" ]]; then
    export LG_CONFIG_FILE="$HOME/.cache/nvim/lazygit-theme.yml"
fi

[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# fzf colours follow the shell palette; the shells' USR1 reload re-sources this too
[[ -s "$HOME/.config/fzf/colors.sh" ]] && source "$HOME/.config/fzf/colors.sh"

# Plugins vars

# zsh-autosuggestions
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30
ZSH_AUTOSUGGEST_HISTORY_IGNORE="?(#c50,)"
