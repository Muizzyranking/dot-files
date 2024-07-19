#!/bin/bash

# Variables
kvantum_theme="Catppuccin-Mocha"
color_scheme="prefer-dark"
gtk_theme="Catppuccin-Mocha-Standard-Peach-Dark"
icon_theme="Reversal-orange-dark"
cursor_theme="Catppuccin-Mocha-Peach-Cursors"

if [ ! -f ~/.config/hypr/.initial_startup_done ]; then
    sleep 1
     
    gsettings set org.gnome.desktop.interface color-scheme $color_scheme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface gtk-theme $gtk_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface icon-theme $icon_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-theme $cursor_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-size 24 > /dev/null 2>&1 &
    
    kvantummanager --set "$kvantum_theme" > /dev/null 2>&1 &
    touch ~/.config/hypr/.initial_startup_done

    exit
fi

