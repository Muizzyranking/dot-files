#!/usr/bin/env bash
SAFE_PROCS="bash zsh fish sh ash"
current_dir=$(tmux display-message -p -F "#{pane_current_path}")
panes_info=$(tmux list-panes -F "#{pane_index} | #{pane_current_path} | #{pane_current_command} | #{pane_id}")

fzf_list=$(printf "* | All Panes | * | __ALL__\n%s" "$panes_info")
selected=$(echo "$fzf_list" \
    | fzf --multi --reverse \
          --header="Select panes to change directory (Esc to quit)" \
          --bind "esc:abort" \
          --select-1 \
          --header-lines=0)

if [ $? -ne 0 ] || [ -z "$selected" ]; then
    exit 0
fi

selected_ids=$(echo "$selected" | awk '{print $NF}')

if echo "$selected_ids" | grep -q "__ALL__"; then
    selected_ids=$(tmux list-panes -F "#{pane_id}")
fi

for pane_id in $selected_ids; do
    proc=$(tmux list-panes -F "#{pane_id} #{pane_current_command}" | grep "^$pane_id " | awk '{print $2}')
    if echo "$SAFE_PROCS" | grep -qw "$proc"; then
        tmux send-keys -t "$pane_id" "cd '$current_dir'" Enter
    fi
done
