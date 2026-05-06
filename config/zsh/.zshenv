#!/usr/bin/env zsh

export EDITOR=nvim
export SUDO_EDITOR=$EDITOR

export DOTFILES=~/dot-files
export DOT_FILES_CONFIG=$DOTFILES/config

export BUN_INSTALL="$HOME/.bun"
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
