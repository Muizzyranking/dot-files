# import this file in bashrc
# 	. ~/.config/bash/bash.bashrc

bind 'set completion-ignore-case on'

alias v='nvim'
alias cl='clear'
alias ff='fdfind --type f --hidden --exclude .git | fzf-tmux -p --reverse'
alias of='fdfind --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs nvim'
alias td='tmux detach'
alias lg='lazygit'

export PATH=~/.config/scripts:$PATH
export STARSHIP_CONFIG=~/.config/starship.toml

eval "$(starship init bash)"
