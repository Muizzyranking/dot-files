# import this file in bashrc
# 	. ~/.config/bash/bash.bashrc

bind 'set completion-ignore-case on'

alias v='nvim'
alias cl='clear'
alias ff='fd --type f --hidden --exclude .git | fzf-tmux -p --reverse'
alias of='fd --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs nvim'
alias td='tmux detach'
alias lg='lazygit'

tns() {
	tmux new -s $1
}

eval "$(starship init bash)"
export STARSHIP_CONFIG=~/.config/bash/starship.toml
. "$HOME/.cargo/env"
