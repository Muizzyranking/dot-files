#!/usr/bin/env bash
systemctl --user stop xdg-desktop-portal-hyprland
systemctl --user stop xdg-desktop-portal-gtk
systemctl --user stop xdg-desktop-portal
sleep 2
systemctl --user start xdg-desktop-portal-hyprland
systemctl --user start xdg-desktop-portal-gtk
systemctl --user start xdg-desktop-portal

