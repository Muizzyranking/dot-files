
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

#Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Case-sensitive completion
HYPHEN_INSENSITIVE="true"

# auto correction
ENABLE_CORRECTION="true"

plugins=( git sudo fzf fzf-tab zsh-history-substring-search history copypath zsh-autosuggestions zsh-syntax-highlighting encode64)

source $ZSH/oh-my-zsh.sh


# You may need to manually set your language environment
# export LANG=en_US.UTF-8
dotfiles_dir="$HOME/dot-files"
# ZSH ALIASES
# Stored in $ALIASES 
if [ -f "$dotfiles_dir/shell/.zsh_alaises" ]; then
   source "$dotfiles_dir/shell/.zsh_alaises"
fi

#ZSH ENV for easy navigation
if [ -f "$dotfiles_dir/shell/.zshenv" ]; then
   source "$dotfiles_dir/shell/.zshenv"

fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

fpath+=$"ZDOTDIR:-~"/.zsh_functions

eval "$(thefuck --alias)"
eval "$(zoxide init zsh)"

export PATH=$PATH:/home/muizzyranking/.spicetify


# pnpm
export PNPM_HOME="/home/muizzyranking/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
