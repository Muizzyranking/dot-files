if [ -z "$TMUX" ]; then
  tmux attach || tmux
fi
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh" # Path to oh-my-zsh installation.

ZSH_THEME="powerlevel10k/powerlevel10k" #Theme
HYPHEN_INSENSITIVE="true" # Case-sensitive completion
ENABLE_CORRECTION="true" # auto correction


plugins=( git sudo fzf fzf-tab zsh-history-substring-search history copypath zsh-autosuggestions zsh-syntax-highlighting encode64)
# source oh-my-zsh after theme
source $ZSH/oh-my-zsh.sh
# You may need to manually set your language environment
# export LANG=en_US.UTF-8
config_dir="$HOME/.config/zsh"
# ZSH ALIASES
# Stored in $ALIASES 
if [ -f "$config_dir/.zsh_alaises" ]; then
   source "$config_dir/.zsh_alaises"
fi

#ZSH ENV for easy navigation
if [ -f "$config_dir/.zshenv" ]; then
   source "$config_dir/.zshenv"

fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source "$HOME/.p10k.zsh"

fpath+=${ZDOTDIR:-~}/.zsh_functions
# fpath=(~/.zsh/completions "$fpath")
# autoload -U compinit
# compinit

eval "$(thefuck --alias)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)
# pnpm
export PNPM_HOME="/home/muizzyranking/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
f() {
  local dir=$(
    zoxide query --list --score |
    fzf --height 40% --layout reverse --info inline \
        --nth 2.. --tac --no-sort --query "$*" \
        --bind 'enter:become:echo {2..}'
  ) && cd "$dir"
}
