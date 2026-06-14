#!/usr/bin/env zsh

: ${OMP_CACHE:="$HOME/.cache/oh-my-posh-init.zsh"}
: ${OMP_CONFIG:="$HOME/.config/oh-my-posh/config.omp.json"}

_omp_generate() {
    mkdir -p "${OMP_CACHE:h}"
    oh-my-posh init zsh --config "$OMP_CONFIG" > "$OMP_CACHE" 2>/dev/null
}

_omp_valid() {
    [[ -s "$OMP_CACHE" ]] && (source "$OMP_CACHE" 2>/dev/null) 2>/dev/null
}

omp_init() {
    if [[ ! -f "$OMP_CACHE" || "$OMP_CONFIG" -nt "$OMP_CACHE" ]]; then
        _omp_generate
    fi

    if ! _omp_valid; then
        print -u2 "[omp] cache corrupted, regenerating..."
        rm -f "$OMP_CACHE"
        _omp_generate
    fi

    source "$OMP_CACHE"
}

omp_reload() {
    rm -f "$OMP_CACHE"
    _omp_generate
    source "$OMP_CACHE"
}

omp_init
