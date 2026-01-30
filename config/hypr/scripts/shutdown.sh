#!/bin/bash

hyprctl clients -j | jq -r '.[].address' | xargs -I {} hyprctl dispatch closewindow address:{}
sleep 2
systemctl poweroff
