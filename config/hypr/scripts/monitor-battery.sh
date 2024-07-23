#!/bin/bash

# Set the battery level thresholds
BATTERY_LOW=20
BATTERY_CRITICAL=10
BATTERY_VERY_CRITICAL=5
BATTERY_SUSPEND=2

while true
do
    # Get battery percentage and status using cat
    battery_level=$(cat /sys/class/power_supply/BAT*/capacity)
    battery_status=$(cat /sys/class/power_supply/BAT*/status)
    
    if [ "$battery_status" = "Discharging" ]; then
        if [ $battery_level -le $BATTERY_SUSPEND ]; then
            notify-send -u critical "Battery Critical" "Battery level is ${battery_level}%! Suspending..."
            sleep 1
            systemctl suspend
        elif [ $battery_level -le $BATTERY_VERY_CRITICAL ]; then
            notify-send -u critical "Battery Very Critical" "Battery level is ${battery_level}%!"
            sleep_time=1
        elif [ $battery_level -le $BATTERY_CRITICAL ]; then
            notify-send -u critical "Battery Critical" "Battery level is ${battery_level}%!"
            sleep_time=5
        elif [ $battery_level -le $BATTERY_LOW ]; then
            notify-send -u normal "Battery Low" "Battery level is ${battery_level}%"
            sleep_time=10
        else
            sleep_time=30 
        fi
    else
        sleep_time=30  # Normal check interval when charging
    fi
    
    sleep $sleep_time
done
