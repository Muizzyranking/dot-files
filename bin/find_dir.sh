#!/bin/bash
# Find and change to a directory interactively using `fd` and `fzf`

selected_dir=$(fd --type d --hidden --exclude .git | fzf-tmux -p --reverse)
if [ -n "$selected_dir" ]; then
    cd "$selected_dir" || echo "Failed to change directory to $selected_dir"
fi

