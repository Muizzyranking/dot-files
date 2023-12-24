# import this file in bashrc
# if [ -f ~/.config/bash/bash.bashrc ]; then
# 	. ~/.config/bash/bash.bashrc
# fi

bind 'set completion-ignore-case on'

alias v='nvim'
alias cl='clear'
alias ff='fdfind --type f --hidden --exclude .git | fzf-tmux -p --reverse'
alias of='fdfind --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs nvim'
alias td='tmux detach'

export PATH=~/.config/scripts:$PATH
export PATH=~/.local/bin:$PATH

#create a symbolic link to starship
ln -s ~/.config/bash/starship.toml ~/.config/starship.toml
eval "$(starship init bash)"
