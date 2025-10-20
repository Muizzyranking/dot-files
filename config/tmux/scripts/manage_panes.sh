#!/usr/bin/env bash

if [[ -z "$TMUX" ]]; then
    echo "❌ This script must be run inside a tmux session"
    exit 1
fi

SAFE_PROCS="bash zsh fish sh"

current_dir=$(tmux display-message -p -F "#{pane_current_path}")
current_pane=$(tmux display-message -p -F "#{pane_id}")

get_shell_icon() {
    local proc="$1"
    case "$proc" in
    bash) echo "🐚" ;;
    zsh) echo "⚡" ;;
    fish) echo "🐟" ;;
    nvim | vim) echo "📝" ;;
    node) echo "🟢" ;;
    python*) echo "🐍" ;;
    *) echo "💻" ;;
    esac
}

is_safe_proc() {
    local proc="$1"
    echo "$SAFE_PROCS" | grep -qw "$proc" && echo "✅" || echo " "
}

build_pane_list() {
    tmux list-panes -F "#{pane_index}|#{pane_current_command}|#{pane_current_path}|#{pane_id}" |
        while IFS='|' read -r idx cmd path pane_id; do
            icon=$(get_shell_icon "$cmd")
            safe=$(is_safe_proc "$cmd")

            current_marker=""
            if [[ "$pane_id" == "$current_pane" ]]; then
                current_marker="👉"
            fi

            printf "%-5s | %s %s | %-25s | %-50s | %s %s\n" \
                "$idx" "$icon" "$safe" "$cmd" "$path" "$pane_id" "$current_marker"
        done
}

while true; do
    pane_list=$(build_pane_list)

    if [[ -z "$pane_list" ]]; then
        echo "❌ No panes found"
        exit 0
    fi

    header="PANE  | 🔧    | COMMAND                   | PATH                                               | ID
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 ENTER: cd here | 💬 CTRL-S: send cmd | 💀 CTRL-K: kill | 🔄 CTRL-R: respawn | 🔍 CTRL-Z: zoom | ESC: exit
Current: $current_dir"

    selection=$(echo "$pane_list" |
        fzf --multi \
            --header="$header" \
            --prompt="Select panes 🪟 " \
            --ansi \
            --preview='
                pane_id=$(echo {} | sed "s/.*\(%[0-9]\+\).*/\1/")
                tmux capture-pane -t "$pane_id" -e -p 2>/dev/null || echo "❌ Cannot capture pane content"
            ' \
            --preview-window=up:60%:wrap \
            --expect=ctrl-s,ctrl-k,ctrl-r,ctrl-z)

    key=$(echo "$selection" | head -1)
    selected_panes=$(echo "$selection" | tail -n +2)

    if [[ -z "$selected_panes" ]]; then
        echo "👋 Exiting..."
        exit 0
    fi

    selected_ids=$(echo "$selected_panes" | awk -F ' \\| ' '{split($5,a," "); print a[1]}')

    case "$key" in
    ctrl-s)
        echo "💬 Enter command to send to selected pane(s):"
        read -r custom_cmd
        if [[ -n "$custom_cmd" ]]; then
            for pane_id in $selected_ids; do
                echo "📤 Sending to $pane_id: $custom_cmd"
                tmux send-keys -t "$pane_id" "$custom_cmd" Enter
            done
            echo "✅ Command sent to $(echo "$selected_ids" | wc -w) pane(s)"
            sleep 1
        fi
        ;;
    ctrl-k)
        pane_count=$(echo "$selected_ids" | wc -w)
        echo "⚠️  WARNING: Kill $pane_count pane(s)?"
        read -p "Type 'yes' to confirm: " confirm
        if [[ "$confirm" == "yes" ]]; then
            for pane_id in $selected_ids; do
                if [[ "$pane_id" != "$current_pane" ]]; then
                    echo "💀 Killing pane $pane_id"
                    tmux kill-pane -t "$pane_id"
                else
                    echo "⚠️  Skipping current pane $pane_id"
                fi
            done
            echo "✅ Pane(s) killed"
            sleep 1
        else
            echo "🚫 Cancelled"
            sleep 1
        fi
        ;;
    ctrl-r)
        for pane_id in $selected_ids; do
            echo "🔄 Respawning pane $pane_id"
            tmux respawn-pane -t "$pane_id" -k
        done
        echo "✅ Pane(s) respawned"
        sleep 1
        ;;
    ctrl-z)
        if [[ $(echo "$selected_ids" | wc -w) -eq 1 ]]; then
            pane_id=$(echo "$selected_ids" | head -1)
            echo "🔍 Toggling zoom for pane $pane_id"
            tmux resize-pane -t "$pane_id" -Z
            exit 0
        else
            echo "⚠️  Zoom only works with a single pane"
            sleep 1
        fi
        ;;
    *)
        for pane_id in $selected_ids; do
            proc=$(tmux list-panes -F "#{pane_id} #{pane_current_command}" | grep "^$pane_id " | awk '{print $2}')
            if echo "$SAFE_PROCS" | grep -qw "$proc"; then
                echo "📁 Changing directory in $pane_id ($proc) to: $current_dir"
                tmux send-keys -t "$pane_id" "cd '$current_dir'" Enter
            else
                echo "⚠️  Skipping $pane_id - unsafe process: $proc"
            fi
        done
        echo "✅ Directory changed in safe pane(s)"
        sleep 1
        ;;
    esac
done
