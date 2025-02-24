#!/usr/bin/env bash
export PATH=~/.local/bin:$PATH
export PATH=/snap/bin:$PATH

export EDITOR=nvim

dotfile_dir=~/dot-files

#Config files
export CONFIG=$dotfile_dir/config
export NVIMRC=$dotfile_dir/config/nvim/
export ZSHRC=$dotfile_dir/shell/.zshrc
export ZSHENV=$dotfile_dir/shell/.zshenv
export ALIASES=~$dotfile_dir/shell/.zsh_alaises
export TMUXRC=$dotfile_dir/config/tmux/tmux.conf

export PATH=$HOME/.npm-global/bin:$PATH
export PATH=$dotfile_dir/bin:$PATH
export PATH=~/bin/lua_ls/bin:$PATH
export PATH=$HOME/go/bin:$PATH
export PATH=$HOME/.local/bin:$PATH

# export PATH=~/nvim-linux64/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH
# export QT_QPA_PLATFORMTHEME=qt5ct
export PATH=$PATH:/usr/local/go/bin

[ -s "/home/muizzyranking/.bun/_bun" ] && source "/home/muizzyranking/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH=$PATH:/home/muizzyranking/.spicetify

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# use snacks nvim lazygit-theme
if [ -f "$HOME/.cache/nvim/lazygit-theme.yml" ]; then
  export LG_CONFIG_FILE="$HOME/.cache/nvim/lazygit-theme.yml"
fi
