#!/bin/sh
dir="${XDG_RUNTIME_DIR:-/tmp}/omp-shells"
[ -d "$dir" ] || exit 0
for f in "$dir"/*; do
    [ -e "$f" ] || continue
    pid="${f##*/}"
    kill -0 "$pid" 2>/dev/null && kill -USR1 "$pid" || rm -f "$f"
done
