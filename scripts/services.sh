#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

enable_service() {
    local service="$1"
    local scope="${2:-system}"

    if [[ "$scope" == "user" ]]; then
        if systemctl --user is-enabled "$service" &>/dev/null; then
            print_message info "Already enabled (user): $service"
            return 0
        fi
        run_cmd "Enabling user service: $service" systemctl --user enable --now "$service"
    else
        if systemctl is-enabled "$service" &>/dev/null; then
            print_message info "Already enabled: $service"
            return 0
        fi
        run_cmd "Enabling service: $service" sudo systemctl enable --now "$service"
    fi
}

add_user_to_group() {
    local group="$1"
    if groups "$USER" | grep -q "\b${group}\b"; then
        print_message info "Already in group: $group"
        return 0
    fi
    run_cmd "Adding $USER to group: $group" sudo usermod -aG "$group" "$USER"
    print_message warning "Re-login required for group '$group' to take effect"
}

main() {
    setup_logging
    print_header "Services & Groups"

    enable_service "bluetooth"
    enable_service "docker"
    # enable_service "sshd"

    add_user_to_group "docker"
    # add_user_to_group "video"
    # add_user_to_group "input"
    # add_user_to_group "audio"

    print_message success "Services configured"
    print_message warning "Some group changes require logout to take effect"
}

main "$@"
