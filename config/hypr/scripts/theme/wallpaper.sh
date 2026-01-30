#!/usr/bin/env bash

set_wallpaper() {
    local wallpaper="$1"
    
    if [ ! -f "$wallpaper" ]; then
        echo "Warning: Wallpaper not found: $wallpaper"
        return 1
    fi
    
    # Ensure swww daemon is running
    if ! pgrep -x swww-daemon >/dev/null; then
        echo "Starting swww daemon..."
        swww-daemon &
        sleep 1
    fi
    
    echo "Setting wallpaper: $wallpaper"
    swww img "$wallpaper" --transition-type wipe --transition-fps 60 --transition-duration 2
}
