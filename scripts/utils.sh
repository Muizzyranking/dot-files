#!/bin/bash

# --- Colors ---
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

export DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export STATE_FILE="$HOME/.fedora_setup_state"

# --- Logging ---
print_message() {
    local type="$1"
    local msg="$2"
    case "$type" in
    info) echo -e "${BLUE}[INFO]${NC} $msg" ;;
    success) echo -e "${GREEN}[SUCCESS]${NC} $msg" ;;
    warning) echo -e "${YELLOW}[WARNING]${NC} $msg" ;;
    error) echo -e "${RED}[ERROR]${NC} $msg" ;;
    step) echo -e "${MAGENTA}[STEP]${NC} $msg" ;;
    *) echo -e "$msg" ;;
    esac
}

# --- State Management ---
is_step_complete() {
    local step="$1"
    if [[ -f "$STATE_FILE" ]] && grep -q "^$step$" "$STATE_FILE"; then
        return 0
    fi
    return 1
}

mark_step_complete() {
    local step="$1"
    echo "$step" >>"$STATE_FILE"
}

clear_state() {
    rm -f "$STATE_FILE"
}

# --- System Checks ---
check_fedora() {
    if ! grep -q "Fedora" /etc/os-release; then
        print_message error "This script is designed for Fedora Linux only."
        exit 1
    fi
}

check_internet() {
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        print_message error "No internet connection detected."
        exit 1
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

request_reboot() {
    print_message warning "A system reboot is required to continue."
    read -rp "Reboot now? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        print_message info "Rebooting..."
        sudo reboot
    else
        print_message info "Please reboot manually and run the script again to continue."
        exit 0
    fi
}

# --- Package Management ---
is_package_installed() {
    local package="$1"
    if rpm -q "$package" &>/dev/null; then
        return 0
    fi
    return 1
}

install_package() {
    local package="$1"
    if is_package_installed "$package"; then
        print_message success "$package is already installed."
        return 0
    fi

    print_message info "Installing package: $package..."
    if sudo dnf install -y "$package"; then
        print_message success "Installed $package"
        return 0
    else
        print_message error "Failed to install $package"
        return 1
    fi
}

install_many() {
    local install_func="$1"
    local type="$2"
    shift 2
    local items=("$@")
    local failed=()
    for item in "${items[@]}"; do
        if ! "$install_func" "$item"; then
            failed+=("$item")
        fi
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        print_message error "Failed to install $type: ${failed[*]}"
        return 1
    fi
}

install_packages() {
    install_many install_package "packages" "$@"
}

# install_packages() {
#     local packages=("$@")
#     local failed=()
#
#     for pkg in "${packages[@]}"; do
#         if ! install_package "$pkg"; then
#             failed+=("$pkg")
#         fi
#     done
#
#     if [[ ${#failed[@]} -gt 0 ]]; then
#         print_message error "Failed to install: ${failed[*]}"
#         return 1
#     fi
# }

install_flatpak() {
    local app="$1"
    if flatpak list --app | grep -q "$app"; then
        print_message success "Flatpak $app is already installed."
        return 0
    fi

    print_message info "Installing Flatpak: $app..."
    flatpak install flathub "$app" -y
}

install_flatpaks() {
    install_many install_flatpak "Flatpaks" "$@"
}

# install_flatpaks() {
#     local apps=("$@")
#     local failed=()
#
#     for app in "${apps[@]}"; do
#         if ! install_flatpak "$app"; then
#             failed+=("$app")
#         fi
#     done
#
#     if [[ ${#failed[@]} -gt 0 ]]; then
#         print_message error "Failed to install Flatpaks: ${failed[*]}"
#         return 1
#     fi
# }

enable_copr() {
    local repo="$1"
    print_message info "Enabling COPR repository: $repo..."
    sudo dnf copr enable -y "$repo"
}

add_repo() {
    local name="$1"
    local source="$2"
    local file="/etc/yum.repos.d/${name}.repo"

    if [[ -f "$file" ]]; then
        print_message success "Repository $name already exists."
        return 0
    fi

    print_message info "Adding repository $name..."

    if [[ "$source" =~ ^https?://.*\.repo$ ]]; then
        sudo dnf config-manager --add-repo "$source"
    else
        echo "$source" | sudo tee "$file" >/dev/null
    fi
    if [[ -f "$repo_file" ]]; then
        print_message success "Repository $repo_name added successfully."
        return 0
    else
        print_message error "Failed to add repository $repo_name."
        return 1
    fi
}

# --- File Operations ---
safe_git_clone() {
    local repo="$1"
    local dest="$2"

    if [[ -d "$dest" ]]; then
        if [[ -d "$dest/.git" ]]; then
            print_message info "Updating existing repository at $dest..."
            git -C "$dest" pull --quiet
        else
            print_message warning "Directory $dest exists but is not a git repo."
        fi
        return 0
    fi

    print_message info "Cloning $repo..."
    git clone --depth=1 --filter=blob:none --quiet "$repo" "$dest"
}

safe_download() {
    local url="$1"
    local dest="$2"

    print_message info "Downloading $url..."
    curl -fL --connect-timeout 30 --max-time 300 "$url" -o "$dest"
}
