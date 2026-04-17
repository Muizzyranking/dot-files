#!/usr/bin/env zsh

PLUGIN_DIR="${PLUGIN_DIR:-$HOME/.zsh/plugins}"
mkdir -p "$PLUGIN_DIR"

typeset -gA _plugin_registry   # name -> path
typeset -gA _plugin_sources    # name -> original src (github slug / url / local path)

_pm_detect_type() {
    local src="$1"
    [[ "$src" == /* || "$src" == ~* ]]  && { echo "local";      return }
    [[ "$src" == git@* || "$src" == ssh://* ]] && { echo "git-ssh";   return }
    [[ "$src" == *://* || "$src" == *.*/* ]]   && { echo "git-https"; return }
    echo "github"
}

_pm_clone_url() {
    local src="$1" type="$2"
    case "$type" in
        git-ssh)   echo "$src" ;;
        git-https) echo "https://$src" ;;
        github)    echo "https://github.com/$src" ;;
        *)         echo "$src" ;;
    esac
}

_pm_default_file() {
    local _path="$1" name="$2"                          # ← was: path
    local candidates=( "$name.zsh" "$name.plugin.zsh" "$name.zsh-theme" "$name.sh" "zsh-$name.zsh" )
    for f in $candidates; do
        [[ -f "$_path/$f" ]] && { echo "$f"; return }
    done
    local found=$(find "$_path" -maxdepth 1 -name "*.zsh" -print -quit 2>/dev/null)
    [[ -n "$found" ]] && { echo "${found:t}"; return }
    echo "$name.zsh"
}


load_plugin() {
    local src="$1" file="${2:-}"
    local type=$(_pm_detect_type "$src")
    local name="${src:t:r}"
    local _path

    if [[ "$type" == "local" ]]; then
        _path="${src/#\~/$HOME}"
        _path="${_path:A}"
        [[ -d "$_path" ]] || { print -u2 "⚠️  local plugin not found: $_path"; return 1 }
    else
        _path="$PLUGIN_DIR/$name"
        if [[ ! -d "$_path" ]]; then
            local url=$(_pm_clone_url "$src" "$type")
            print "📦 installing $name …"
            git clone --depth=1 "$url" "$_path" 2>/dev/null \
                || { print -u2 "❌ clone failed: $url"; return 1 }
        fi
    fi

    [[ -z "$file" ]] && file=$(_pm_default_file "$_path" "$name")
    local full="$_path/$file"
    [[ -f "$full" ]] || { print -u2 "⚠️  file not found: $full"; return 1 }

    source "$full"
    _plugin_registry[$name]="$_path"
    _plugin_sources[$name]="$src"
}

plugin_update() {
    local names=(${(k)_plugin_registry})
    (( ${#names} == 0 )) && { print "no plugins loaded"; return 1 }

    local git_plugins=()
    for name in $names; do
        [[ -d "${_plugin_registry[$name]}/.git" ]] && git_plugins+=($name)
    done

    (( ${#git_plugins} == 0 )) && { print "no git plugins found"; return 1 }

    # Show numbered list
    print "Plugins:"
    local i=1
    for name in $git_plugins; do
        printf "  %d) %s\n" $i $name
        (( i++ ))
    done
    print "  a) all"
    print ""
    print -n "Update which? [1-${#git_plugins}/a]: "
    read choice

    local targets=()
    if [[ "$choice" == "a" ]]; then
        targets=($git_plugins)
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#git_plugins} )); then
        targets=($git_plugins[$choice])
    else
        print "cancelled"; return 0
    fi

    print ""
    for name in $targets; do
        local _path="${_plugin_registry[$name]}"
        print -n "  $name … "
        git -C "$_path" fetch -q 2>/dev/null
        local behind=$(git -C "$_path" rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
        if (( behind == 0 )); then
            print "up to date"
        else
            git -C "$_path" pull --ff-only -q 2>/dev/null && print "✓ updated ($behind commits)" || print "✗ failed"
        fi
    done
}
