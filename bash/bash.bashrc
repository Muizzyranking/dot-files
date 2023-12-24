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

eval "$(starship init bash)"
export STARSHIP_CONFIG=~/.config/starship.toml
