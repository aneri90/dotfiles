# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Prerequisites

- [GNU Stow](https://www.gnu.org/software/stow/)
  ```bash
  # macOS
  brew install stow

  # Arch Linux
  sudo pacman -S stow

  # Debian/Ubuntu
  sudo apt install stow
  ```

## Installation

```bash
git clone <repo-url> ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh
```

Or install specific packages:
```bash
stow nvim zsh tmux
```

## Packages

| Package | Description | Target |
|---------|-------------|--------|
| `nvim` | Neovim config (LazyVim) | `~/.config/nvim` |
| `zsh` | Zsh shell config with Zinit | `~/.zshrc`, `~/.shell_*` |
| `tmux` | Tmux config | `~/.tmux.conf` |
| `starship` | Starship prompt | `~/.config/starship.toml` |
| `localbin` | Custom scripts | `~/.local/bin/` |

## Usage

```bash
stow <package>      # Install package
stow -D <package>   # Uninstall package
stow -R <package>   # Reinstall package
```

## Uninstalling

Remove symlinks for specific packages:
```bash
stow -D nvim tmux
```

Remove all packages:
```bash
stow -D */
```

This only removes the symlinks, not the actual config files in this repo.

## Adding New Configs

1. Create a new directory with the package name
2. Mirror the target structure inside it
3. Run `./install.sh` or `stow <package>`

Example for adding alacritty:
```
alacritty/
└── .config/
    └── alacritty/
        └── alacritty.toml
```
