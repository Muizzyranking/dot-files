setopt CASE_GLOB            # Case-sensitive globbing (default)
setopt NO_CASE_GLOB         # Case-insensitive globbing
setopt CORRECT              # Command correction
setopt HIST_IGNORE_ALL_DUPS # Remove duplicate history entries
setopt HIST_FIND_NO_DUPS    # Don't show duplicates in search
setopt SHARE_HISTORY        # Share history between sessions
setopt APPEND_HISTORY       # Append to history file
setopt INC_APPEND_HISTORY   # Write to history immediately

setopt AUTO_CD           # Just type directory name to cd
setopt AUTO_PUSHD        # Make cd push old directory onto stack
setopt PUSHD_IGNORE_DUPS # Don't push duplicates
setopt PUSHD_SILENT      # Don't print directory stack

# Completion
setopt COMPLETE_IN_WORD     # Complete from both ends
setopt ALWAYS_TO_END        # Move cursor to end after completion
setopt AUTO_MENU            # Show menu on successive tab
setopt AUTO_LIST            # List choices on ambiguous completion
setopt MENU_COMPLETE        # Insert first match immediately

# History
setopt EXTENDED_HISTORY     # Save timestamp and duration
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_SPACE    # Don't save commands starting with space
setopt HIST_VERIFY          # Show command with history expansion before running

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Completion system
fpath+=("$HOME/.zsh/completions/" "$fpath")
fpath+=("${ZDOTDIR:-~}/.zsh_functions")
autoload -Uz compinit
compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select

# ============================================
# Plugin Manager Helper
# ============================================
PLUGIN_DIR="$HOME/.zsh/plugins"

# Usage: plugin_load "username/repo" "/path/to/plugin.zsh"
load_plugin() {
    local repo=$1
    local file=${2:-"${repo##*/}.zsh"}
    local plugin_name="${repo##*/}"
    local plugin_path="$PLUGIN_DIR/$plugin_name"

    if [[ ! -d "$plugin_path" ]]; then
        echo "📦 Installing plugin: $repo"
        git clone --depth=1 "https://github.com/$repo.git" "$plugin_path"
    fi

    # Source the plugin file
    if [[ -f "$plugin_path/$file" ]]; then
        source "$plugin_path/$file"
    else
        echo "⚠️  Warning: Plugin file not found: $plugin_path/$file"
    fi
}

# ============================================
# Load Plugins
# ============================================
# Create plugin directory if it doesn't exist
mkdir -p "$PLUGIN_DIR"

load_plugin "zsh-users/zsh-autosuggestions"
load_plugin "zsh-users/zsh-history-substring-search"
load_plugin "Aloxaf/fzf-tab"
load_plugin "zsh-users/zsh-syntax-highlighting"

# ============================================
# Plugin-specific Configuration
# ============================================

# History substring search keybindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ============================================
# Useful Functions
# ============================================

# sudo - press ESC twice to add sudo
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N sudo-command-line
bindkey "\e\e" sudo-command-line

# ============================================
# Configuration Files
# ============================================
config_dir="$HOME/.config/zsh"

# Load aliases
if [ -f "$config_dir/.zsh_alaises" ]; then
    source "$config_dir/.zsh_alaises"
fi

# Load environment variables
if [ -f "$config_dir/.zshenv" ]; then
    source "$config_dir/.zshenv"
fi

# ============================================
# Tool Integrations
# ============================================

# Zoxide (better cd)
eval "$(zoxide init zsh)"

# FZF
source <(fzf --zsh)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# PNPM
export PNPM_HOME="/home/muizzyranking/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

# UV
eval "$(uv generate-shell-completion zsh)"

# ============================================
# Prompt (Oh My Posh)
# ============================================
eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/config.omp.json")"
