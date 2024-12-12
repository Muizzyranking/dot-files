#!/bin/bash
# Find and display the full path of a file interactively using `fd` and `fzf`

select_file=$(fd --type f --hidden --exclude .git | fzf-tmux -p --reverse)
if [ -n "$select_file" ]; then
    echo "$select_file"
fi

