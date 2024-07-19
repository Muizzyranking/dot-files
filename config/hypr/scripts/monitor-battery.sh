#!/bin/bash

# Set the battery level at which to notify
BATTERY_LOW=20
BATTERY_CRITICAL=10

while true
do
    battery_level=$(acpi -b | grep -P -o '[0-9]+(?=%)')
    
    if [ $battery_level -le $BATTERY_CRITICAL ]; then
        notify-send -u critical "Battery Critical" "Battery level is ${battery_level}%!"
    elif [ $battery_level -le $BATTERY_LOW ]; then
        notify-send -u normal "Battery Low" "Battery level is ${battery_level}%"
    fi

    sleep 300 # Check every 5 minutes
done

