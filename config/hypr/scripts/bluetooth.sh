#!/bin/bash

# Check if blueman-manager is running
if pgrep -x "blueman-manager" > /dev/null
then
    # If running, kill it
    killall blueman-manager
else
    # If not running, start it
    blueman-manager
fi

