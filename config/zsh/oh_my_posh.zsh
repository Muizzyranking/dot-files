#!/usr/bin/env zsh

: ${OMP_CACHE:="$HOME/.cache/oh-my-posh-init.zsh"}
: ${OMP_CONFIG:="$HOME/.config/oh-my-posh/config.omp.json"}

_omp_check_installed() {
    if ! command -v oh-my-posh >/dev/null 2>&1; then
        print -u2 "[omp] oh-my-posh not found."
        printf "[omp] Install it now? [y/N] "
        read -r reply
        case "$reply" in
        [yY] | [yY][eE][sS])
            curl -s https://ohmyposh.dev/install.sh | bash -s
            if ! command -v oh-my-posh >/dev/null 2>&1; then
                print -u2 "[omp] Install failed or not on PATH. Aborting init."
                return 1
            fi
            ;;
        *)
            print -u2 "[omp] Skipping install. Prompt will not run again for this session."
            return 1
            ;;
        esac
    fi
    return 0
}

_omp_generate() {
    mkdir -p "${OMP_CACHE:h}"
    oh-my-posh init zsh --config "$OMP_CONFIG" >"$OMP_CACHE" 2>/dev/null
}

_omp_valid() {
    [[ -s "$OMP_CACHE" ]] && (source "$OMP_CACHE" 2>/dev/null) 2>/dev/null
}

omp_init() {
    _omp_check_installed || return 1
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
    _omp_check_installed || return 1
    rm -f "$OMP_CACHE"
    _omp_generate
    source "$OMP_CACHE"
}

omp_init
