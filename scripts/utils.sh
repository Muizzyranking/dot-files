#!/bin/bash

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print message with color based on type
print_message() {
    case "$1" in
    error) echo -e "${RED}$2${NC}" ;;
    warning) echo -e "${YELLOW}$2${NC}" ;;
    success) echo -e "${GREEN}$2${NC}" ;;
    info) echo -e "${BLUE}$2${NC}" ;;
    *) echo "$2" ;;
    esac
}

is_package_installed() {
    local package="$1"
    rpm -q "$package" &>/dev/null
}

install_package() {
    local package="$1"

    # Check if the package is already installed
    if is_package_installed "$package"; then
        print_message warning "Package $package already installed, skipping..."
        return 0
    else
        # Attempt to install the package
        print_message info "Installing package $package..."
        if sudo dnf install -y -q "$package"; then
            print_message success "Successfully installed package $package."
            return 0
        else
            print_message error "Failed to install package $package."
            return 1
        fi
    fi
}

install_packages() {
    local packages=("$@")
    local failed_packages=()

    for package in "${packages[@]}"; do
        if ! install_package "$package"; then
            failed_packages+=("$package")
        fi
    done

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        print_message error "Failed to install: ${failed_packages[*]}"
        return 1
    fi

    return 0
}

safe_git_clone() {
    local repo="$1"
    local dest="$2"
    local max_attempts="${3:-3}"
    local attempt=0

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    while ((attempt < max_attempts)); do
        if git clone --depth=1 --filter=blob:none --quiet "$repo" "$dest" 2>/dev/null; then
            print_message success "Successfully cloned $repo"
            return 0
        fi
        ((attempt++))
        if ((attempt < max_attempts)); then
            print_message warning "Git clone failed (attempt $attempt/$max_attempts), retrying..."
            sleep 2
        fi
    done

    print_message error "Failed to clone $repo after $max_attempts attempts"
    return 1
}

safe_download() {
    local url="$1"
    local dest="$2"
    local max_attempts="${3:-3}"
    local attempt=0

    while ((attempt < max_attempts)); do
        if curl -fsSL --connect-timeout 30 --max-time 300 "$url" -o "$dest"; then
            print_message success "Successfully downloaded $url"
            return 0
        fi
        ((attempt++))
        if ((attempt < max_attempts)); then
            print_message warning "Download failed (attempt $attempt/$max_attempts), retrying..."
            sleep 2
        fi
    done

    print_message error "Failed to download $url after $max_attempts attempts"
    return 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

add_repo() {
    local repo_name="$1"
    local repo_url="$2"
    local repo_file="/etc/yum.repos.d/${repo_name}.repo"

    if [[ -f "$repo_file" ]]; then
        print_message warning "Repository $repo_name already exists, skipping..."
        return 0
    fi

    print_message info "Adding repository $repo_name..."
    echo "$repo_url" | sudo tee "$repo_file" >/dev/null

    if [[ -f "$repo_file" ]]; then
        print_message success "Repository $repo_name added successfully."
        return 0
    else
        print_message error "Failed to add repository $repo_name."
        return 1
    fi
}

enable_copr() {
    local copr_repo="$1"

    if sudo dnf copr list --enabled | grep -q "$copr_repo"; then
        print_message warning "COPR repository $copr_repo already enabled, skipping..."
        return 0
    fi

    print_message info "Enabling COPR repository $copr_repo..."
    if sudo dnf copr enable "$copr_repo" -y; then
        print_message success "COPR repository $copr_repo enabled successfully."
        return 0
    else
        print_message error "Failed to enable COPR repository $copr_repo."
        return 1
    fi
}

check_system_requirements() {
    print_message info "Checking system requirements..."

    # Check if running Fedora
    if ! grep -q "Fedora" /etc/os-release; then
        print_message error "This script is designed for Fedora Linux only."
        return 1
    fi

    # Check internet connectivity
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        print_message error "No internet connection detected."
        return 1
    fi

    print_message success "System requirements check passed."
    return 0
}
