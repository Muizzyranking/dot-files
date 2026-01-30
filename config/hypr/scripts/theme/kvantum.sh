#!/usr/bin/env bash

set_kvantum_theme() {
    local kvantum_theme="$1"
    
    if [ -n "$kvantum_theme" ]; then
        mkdir -p "$HOME/.config/Kvantum"
        cat >"$HOME/.config/Kvantum/kvantum.kvconfig" <<EOFKV
[General]
theme=${kvantum_theme}
EOFKV
        echo "Kvantum theme set to: $kvantum_theme"
    fi
}
