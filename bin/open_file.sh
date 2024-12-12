#!/bin/bash
# Find and open a file in `nvim` interactively using `fzf` with a preview

selected_file=$(fzf --tmux 80% --preview="bat --color=always {}")
if [ -n "$selected_file" ]; then
    nvim "$selected_file"
fi

