#!/bin/bash

# Get a list of available Wi-Fi networks
get_networks() {
    nmcli -f SSID,SECURITY,BARS device wifi list | tail -n +2 | sed 's/\s*$//' | sort -u
}

# Connect to a Wi-Fi network
connect_to_network() {
    ssid="$1"
    if nmcli -f NAME connection show | grep -q "^$ssid "; then
        nmcli connection up "$ssid"
    else
        password=$(echo "" | rofi -dmenu -p "Enter password for $ssid" -password -theme ~/.config/rofi/network.rasi)
        if [ -n "$password" ]; then
            nmcli device wifi connect "$ssid" password "$password"
        fi
    fi
}

# Toggle Wi-Fi
toggle_wifi() {
    if nmcli radio wifi | grep -q "enabled"; then
        nmcli radio wifi off
    else
        nmcli radio wifi on
    fi
}

# Main menu
main_menu() {
    options="Toggle Wi-Fi\nShow Available Networks"
    chosen=$(echo -e "$options" | rofi -dmenu -p "Network Menu" -i -theme ~/.config/rofi/network.rasi)

    case $chosen in
        "Toggle Wi-Fi")
            toggle_wifi
            ;;
        "Show Available Networks")
            show_networks
            ;;
    esac
}

# Show available networks
show_networks() {
    networks=$(get_networks)
    chosen_network=$(echo -e "$networks" | rofi -dmenu -p "Select Network" -i -theme ~/.config/rofi/network.rasi)

    if [ -n "$chosen_network" ]; then
        ssid=$(echo "$chosen_network" | cut -d' ' -f1)
        connect_to_network "$ssid"
    fi
}

# Run the main menu
main_menu
