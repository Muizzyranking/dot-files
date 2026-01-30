#!/bin/bash

scripts="$HOME/.config/hypr/scripts"

shutdown="⏻"
reboot="󰑓"
lock=""
suspend="⏾"
hibernate=""
logout="󰍃"

options="$lock\n$suspend\n$logout\n$hibernate\n$reboot\n$shutdown"

chosen=$(echo -e "$options" | rofi -dmenu -config ~/.config/rofi/power-menu.rasi -p "Power" -format 'i')

if [ -z "$chosen" ]; then
    exit 0
fi

case $chosen in
0) # Lock
    "$scripts/lockscreen.sh"
    ;;
1) # Suspend
    "$scripts/suspend.sh"
    ;;
2) # Logout
    hyprctl dispatch exit
    ;;
3) # Hibernate
    systemctl hibernate
    ;;
4) # Reboot
    systemctl reboot
    ;;
5)
    "$scripts/shutdown.sh"
    ;;
esac
