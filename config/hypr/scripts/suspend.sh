#!/bin/bash

# Check multiple music players
players=("spotify" "vlc" "mpv" "firefox" "chromium")

for player in "${players[@]}"; do
    if playerctl -p "$player" status 2>/dev/null | grep -q "Playing"; then
        echo "Music playing on $player, not suspending"
        exit 0
    fi
done

# Check for audio activity
if pactl list sink-inputs | grep -q "RUNNING"; then
    echo "Audio activity detected, not suspending"
    exit 0
fi

echo "No music detected, suspending"
systemctl suspend

