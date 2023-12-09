# import this file in bashrc
# bind 'set completion-ignore-case on'
# if [ -f ~/.config/bash/bash.bashrc ]; then
# 	. ~/.config/bash/bash.bashrc
# fi

alias v='nvim'
alias cl='clear'
alias ff='fdfind --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs nvim'
alias td='tmux detach'

export PATH=~/.config/scripts:$PATH
export PATH=~/.local/bin:$PATH
eval "$(oh-my-posh init bash --config ~/.config/bash/neg.omp.json)"
