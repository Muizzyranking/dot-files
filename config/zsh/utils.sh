#!/bin/env bash

print_message() {
    local type="info"
    local message=""

    if [ $# -eq 1 ]; then
        message="$1"
    elif [ $# -ge 2 ]; then
        type="$1"
        message="$2"
    else
        echo "Usage: print_message [type] <message>"
        exit 1
    fi

    case "$type" in
    error) echo -e "\033[0;31mError: $message\033[0m" ;;
    success) echo -e "\033[0;32mSuccess: $message\033[0m" ;;
    warning) echo -e "\033[0;33mWarning: $message\033[0m" ;;
    info) echo -e "\033[0;34m$message\033[0m" ;;
    *) echo -e "$message" ;;
    esac
}
