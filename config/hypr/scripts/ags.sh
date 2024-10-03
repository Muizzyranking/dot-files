#!/usr/bin/bash

# Check if waybar is running and kill it
if pgrep -x "waybar" >/dev/null; then
    pkill waybar || {
        echo "Failed to kill waybar"
        exit 1
    }
fi

# Check if swaync is running and kill it
if pgrep -x "swaync" >/dev/null; then
    pkill swaync || {
        echo "Failed to kill swaync"
        exit 1
    }
fi

# Start ags
if pgrep -x "ags" >/dev/null; then
    pkill ags || {
        echo "Failed to kill AGS"
        exit 1
    }
fi

/usr/bin/ags &
