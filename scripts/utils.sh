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
        error)   echo -e "${RED}$2${NC}" ;;
        warning) echo -e "${YELLOW}$2${NC}" ;;
        success) echo -e "${GREEN}$2${NC}" ;;
        info)    echo -e "${BLUE}$2${NC}" ;;
        *)       echo "$2" ;;
    esac
}

install_package() {
    local package="$1"

    # Check if the package is already installed
    if dnf list installed "$package" &>/dev/null; then
        print_message warning "Package $package already installed, skipping..."
    else
        # Attempt to install the package
        print_message info "Installing package $package..."
        if sudo dnf install -y -q "$package"; then
            print_message success "Successfully installed package $package."
        else
            print_message error "Failed to install package $package."
        fi
    fi
}
