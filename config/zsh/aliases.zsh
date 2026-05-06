#!/usr/bin/env zsh

alias cd='z'
alias -- -='cd -'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

alias ls='eza --color=always --icons=always --group-directories-first'
alias la='eza -la --color=always --icons=always --group-directories-first'
alias ll='eza -l --color=always --icons=always --group-directories-first'
alias lt='eza --tree --level=2 --color=always --icons=always'
alias tree='eza --tree --group-directories-first --git-ignore --color=always --icons=always'

alias cat='bat --paging=never'
alias v='nv'
alias v2='NVIM_APPNAME=nv12 nv'

alias df='df -h'
alias du='du -h'
alias dus='du -sh * | sort -h'

alias myip='curl -s ifconfig.me'

alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -10'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gg='lazygit'

alias ae='$EDITOR ~/.config/zsh/aliases.zsh'
alias zshrc='$EDITOR $ZSHRC'
alias zshenv='$EDITOR $ZSHENV'
alias nvimrc='$EDITOR $NVIMRC'
alias tmuxrc='$EDITOR $TMUXRC'

alias ff='find_file'
