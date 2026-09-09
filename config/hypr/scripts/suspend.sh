#!/bin/bash

# Music / Audio
players=("spotify" "vlc" "mpv" "firefox" "chromium")

for player in "${players[@]}"; do
    if playerctl -p "$player" status 2>/dev/null | grep -q "Playing"; then
        echo "Music playing on $player, not suspending"
        exit 0
    fi
done

if pactl list sink-inputs | grep -q "RUNNING"; then
    echo "Audio activity detected, not suspending"
    exit 0
fi

DOWNLOAD_DIRS=("$HOME/Downloads")

for dir in "${DOWNLOAD_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        if find "$dir" -maxdepth 1 -name "*.part" -o -name "*.crdownload" -o -name "*.tmp" | grep -q .; then
            echo "Browser download in progress (incomplete file in $dir), not suspending"
            exit 0
        fi
    fi
done

echo "No blocking activity, suspending"
systemctl suspend
