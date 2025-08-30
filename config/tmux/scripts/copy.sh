#!/bin/bash

if command -v clip.exe >/dev/null 2>&1; then
    clip.exe
elif command -v wslclip >/dev/null 2>&1; then
    wslclip
elif command -v wl-copy >/dev/null 2>&1; then
    wl-copy
elif command -v xclip >/dev/null 2>&1; then
    xclip -in -selection clipboard
else
    cat > "/tmp/tmux-buffer-$(whoami)"
    echo "No clipboard utility found, saved to /tmp/tmux-buffer-$(whoami)" >&2
fi
