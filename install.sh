#!/bin/bash
set -e
cd "$(dirname "$0")"

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

# Install the tools these dotfiles configure, before symlinking their configs
if [ -f Brewfile ]; then
    if command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew packages from Brewfile"
        brew bundle --file=Brewfile
    else
        echo "WARNING: Homebrew not found, skipping Brewfile."
        echo "         Install it from https://brew.sh then re-run this script."
    fi
fi

# Find all directories (packages) excluding hidden dirs
packages=$(ls -d */ 2>/dev/null | sed 's/\///' | sort | tr '\n' ' ')

echo "Installing packages: $packages"

# Check for conflicts using dry-run
conflicts=$(stow -n $packages 2>&1 | grep "existing target" | sed 's/.*: //' || true)

if [ -n "$conflicts" ]; then
    echo "Found existing files, backing up to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    for file in $conflicts; do
        target="$HOME/$file"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$file")"
            mv "$target" "$BACKUP_DIR/$file"
            echo "  Backed up: $file"
        fi
    done
fi

stow $packages
echo "Done!"
