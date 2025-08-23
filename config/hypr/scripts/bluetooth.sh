#!/bin/bash

command_name="blueman-manager"

if ! command -v $command_name &>/dev/null; then
    exit 1
fi

if pgrep $command_name >/dev/null; then
    killall $command_name
else
    $command_name &
fi
