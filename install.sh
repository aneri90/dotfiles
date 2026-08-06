#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

REPO="$PWD"
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
packages=()
for dir in */; do
    [ -d "$dir" ] || continue
    packages+=("${dir%/}")
done

if [ "${#packages[@]}" -eq 0 ]; then
    echo "No packages found in $REPO"
    exit 1
fi

echo "Installing packages: ${packages[*]}"

# Back up every real (non-symlink) file that stow would have to replace.
# The list is derived by walking the package trees, NOT by parsing stow's
# conflict output: those messages embed the package-side source path as well
# as the target, and a loose parse of them once moved this repo's own tracked
# files into the backup dir.
backed_up=0
for pkg in "${packages[@]}"; do
    while IFS= read -r -d '' src; do
        rel="${src#"$pkg"/}"
        target="$HOME/$rel"

        # Only real files shadow a stow symlink; anything already symlinked is ours
        if [ ! -e "$target" ] || [ -L "$target" ]; then
            continue
        fi

        # Refuse to move anything that resolves inside the repo
        target_dir="$(cd "$(dirname "$target")" && pwd -P)"
        case "$target_dir" in
            "$REPO" | "$REPO"/*)
                echo "  Skipped (inside repo): $rel"
                continue
                ;;
        esac

        if [ "$backed_up" -eq 0 ]; then
            echo "Found existing files, backing up to $BACKUP_DIR"
            backed_up=1
        fi
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        mv "$target" "$BACKUP_DIR/$rel"
        echo "  Backed up: $rel"
    done < <(find "$pkg" \( -type f -o -type l \) -print0)
done

# stow has the final say: it aborts every operation if any conflict remains
stow "${packages[@]}"
echo "Done!"
