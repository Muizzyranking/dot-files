#!/usr/bin/env zsh

# ============================================
# History
# ============================================
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt EXTENDED_HISTORY       # Save timestamp and duration
setopt HIST_EXPIRE_DUPS_FIRST # Remove oldest duplicates first
setopt HIST_IGNORE_ALL_DUPS   # Remove duplicate entries
setopt HIST_FIND_NO_DUPS      # Don't show duplicates in search
setopt HIST_IGNORE_SPACE      # Don't save commands starting with space
setopt HIST_VERIFY            # Show command before executing history expansion
setopt SHARE_HISTORY          # Share history between sessions
setopt APPEND_HISTORY         # Append to history file
setopt INC_APPEND_HISTORY     # Write immediately

# ============================================
# Directories
# ============================================
setopt AUTO_CD                # Type dir name to cd
setopt AUTO_PUSHD             # Push old dir to stack
setopt PUSHD_IGNORE_DUPS      # No duplicate stack entries
setopt PUSHD_SILENT           # Don't print stack

# ============================================
# Completion
# ============================================
setopt COMPLETE_IN_WORD       # Complete from both ends
setopt ALWAYS_TO_END          # Move cursor to end after completion
setopt AUTO_MENU              # Show menu on successive tab
setopt AUTO_LIST              # List choices on ambiguous completion
setopt MENU_COMPLETE          # Insert first match immediately

# ============================================
# Globbing
# ============================================
setopt NO_CASE_GLOB           # Case-insensitive globbing
setopt EXTENDED_GLOB          # Enable extended glob patterns

# ============================================
# Input/Output
# ============================================
setopt CORRECT                # Command correction
setopt NO_BEEP                # No beep on error
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shell

# ============================================
# Completion System
# ============================================

fpath+=("$HOME/.zsh/completions" "${ZDOTDIR:-~}/.zsh_functions")

autoload -Uz compinit

# Cache compinit for speed
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Menu selection
zstyle ':completion:*' menu select

# Group completions
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'

# Faster completion
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
