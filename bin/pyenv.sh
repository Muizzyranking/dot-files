#!/usr/bin/bash

if [[ $# -eq 0 ]]; then
    python3 -m venv venv && source ./venv/bin/activate
else
    python3 -m venv venv --prompt="$1" && source ./venv/bin/activate
fi
