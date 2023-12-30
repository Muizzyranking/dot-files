# import this file in bashrc
# 	. ~/.config/bash/bash.bashrc

bind 'set completion-ignore-case on'

alias v='nvim'
alias cl='clear'
alias ff='fdfind --type f --hidden --exclude .git | fzf-tmux -p --reverse'
alias of='fdfind --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs nvim'
alias td='tmux detach'
alias lg='lazygit'
alias copy='xsel -ib'
alias paste='xsel -ob'

export PATH=~/.config/scripts:$PATH

eval "$(starship init bash)"
export STARSHIP_CONFIG=~/.config/bash/starship.toml
