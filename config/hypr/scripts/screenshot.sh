#!/bin/bash
DIR="$HOME/Pictures/Screenshots"
SCRIPTS="$HOME/.config/hypr/scripts"
NAME="Screenshot_$(date +%d%b_%H-%M-%S)_${RANDOM}.png"
ACTIVE_WINDOW_FILE="Screenshot_$(date +%d%b_%H-%M-%S)_$(hyprctl -j activewindow | jq -r '(.class)').png"
notify_cmd_shot="notify-send -h string:x-canonical-private-synchronous:shot-notify -u low -i $HOME/.config/swaync/icons/picture.png"
option1="Selected area"
option2="Fullscreen"
option3="Current window"
option4="Current display"
options="$option1\n$option2\n$option3\n$option4"

# Function to close Rofi
close_rofi() {
    pkill rofi
}

# Check if hyprshade is active
current_hyprshade=""
if [ ! -z $(hyprshade current) ]; then
    current_hyprshade=$(hyprshade current)
    hyprshade off
fi

choice=$(echo -e "$options" | rofi -dmenu -config ~/.config/rofi/screenshot.rasi -p "Take Screenshot" -l 4)
close_rofi

case $choice in
    $option1)
        sleep 0.5
        temp_file=$(mktemp)
        grim -g "$(slurp)" "$temp_file"
        if [ -s "$temp_file" ]; then
            mv "$temp_file" "$DIR/$NAME"
            wl-copy < "$DIR/$NAME"
            "${SCRIPTS}/sounds.sh" --screenshot
            ${notify_cmd_shot} "Screenshot Saved" "Mode: Selected area"
            swappy -f "$DIR/$NAME"
        else
            rm "$temp_file"
        fi
    ;;
    $option2)
        sleep 0.5
        grim "$DIR/$NAME"
        wl-copy < "$DIR/$NAME"
        "${SCRIPTS}/sounds.sh" --screenshot
        ${notify_cmd_shot} "Screenshot Saved" "Mode: Fullscreen"
        swappy -f "$DIR/$NAME"
    ;;
    $option3)
        sleep 0.5
        active_window_geometry=$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        grim -g "$active_window_geometry" "$DIR/$ACTIVE_WINDOW_FILE"
        wl-copy < "$DIR/$ACTIVE_WINDOW_FILE"
        "${SCRIPTS}/sounds.sh" --screenshot
        ${notify_cmd_shot} "Screenshot Saved" "Mode: Current window"
        swappy -f "$DIR/$ACTIVE_WINDOW_FILE"
    ;;
    $option4)
        sleep 0.5
        monitor=$(hyprctl monitors | grep -B 4 "focused: yes" | awk '/^Monitor/{print $2}')
        grim -o "$monitor" "$DIR/$NAME"
        wl-copy < "$DIR/$NAME"
        "${SCRIPTS}/sounds.sh" --screenshot
        ${notify_cmd_shot} "Screenshot Saved" "Mode: Current display"
        swappy -f "$DIR/$NAME"
    ;;
esac

# Restore hyprshade if it was active
if [ ! -z $current_hyprshade ]; then
    hyprshade on $current_hyprshade
fi

exit 0
