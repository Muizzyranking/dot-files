#!/bin/bash

while true; do
    clipboard_entries=$(cliphist list)

    # Remove numbers for display but keep full entries for lookup
    formatted_entries=$(echo "$clipboard_entries" | awk '{$1=""; print substr($0,2)}')

    selection=$(echo "$formatted_entries" | rofi -i -dmenu \
        -kb-custom-1 "Control-Delete" \
        -kb-custom-2 "Alt-Delete" \
        -config ~/.config/rofi/clipboard.rasi -p " ")

    case "$?" in
    1) # esc
        exit
        ;;
    0)
        case "$selection" in
        "")
            continue
            ;;
        *)
            # Find the original full entry by matching text
            result=$(echo "$clipboard_entries" | grep -F "$selection")

            # Copy to clipboard using cliphist decode
            if [ -n "$result" ]; then
                cliphist decode <<<"$result" | wl-copy
            fi
            exit
            ;;
        esac
        ;;
    10) # Control-Delete: Delete selected entry
        result=$(echo "$clipboard_entries" | grep -F "$selection")
        if [ -n "$result" ]; then
            cliphist delete <<<"$result"
        fi
        ;;
    11) # Alt-Delete: Wipe clipboard history
        cliphist wipe
        ;;
    esac
done
