ERROR_SOUND_DIR="${0:A:h}"

_play_error_sound() {
    local EXIT_CODE=$?
    local SOUND_PATH="$ERROR_SOUND_DIR/sound/fahh.mp3"

    if [[ $EXIT_CODE -ne 0 && $EXIT_CODE -ne 130 ]]; then
        if [[ -f "$SOUND_PATH" ]]; then
            (paplay "$SOUND_PATH" > /dev/null 2>&1 &!)
        fi
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _play_error_sound
