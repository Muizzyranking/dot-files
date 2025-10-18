#!/usr/bin/env bash
export PATH=~/.local/bin:$PATH
export PATH=/snap/bin:$PATH

export EDITOR=nv

dotfile_dir=~/dot-files
# config_dir=${XDG_CONFIG_HOME:-$HOME/.config}

#Config files
export CONFIG=$dotfile_dir/config
export NVIMRC=$dotfile_dir/config/nvim/
export ZSHRC=$dotfile_dir/home/.zshrc
export ZSHENV=$CONFIG/zsh/.zshenv
export ALIASES=~$CONFIG/zsh/.zsh_alaises
export TMUXRC=$CONFIG/tmux/tmux.conf

export PATH=$HOME/.npm-global/bin:$PATH
export PATH=$dotfile_dir/bin:$PATH
export PATH=~/bin/lua_ls/bin:$PATH
export PATH=$HOME/.local/bin:$PATH

export PATH=$HOME/.cargo/bin:$PATH
# export QT_QPA_PLATFORMTHEME=qt5ct
export PATH=$PATH:/usr/local/go/bin

[ -s "/home/muizzyranking/.bun/_bun" ] && source "/home/muizzyranking/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH=$PATH:/home/muizzyranking/.spicetify

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
# PNPM
export PNPM_HOME="/home/muizzyranking/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

# use snacks nvim lazygit-theme
if [ -f "$HOME/.cache/nvim/lazygit-theme.yml" ]; then
    export LG_CONFIG_FILE="$HOME/.cache/nvim/lazygit-theme.yml"
fi
export PATH=$HOME/.npm-global/bin:$PATH

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
