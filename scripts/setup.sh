#!/usr/bin/bash

if dnf repolist all | grep -qw '^terra'; then
    echo "Repository 'terra' already exists; skipping repofrompath addition."
else
    dnf install --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra$releasever" terra-release
fi
