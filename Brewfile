# Homebrew bundle for this dotfiles repo.
#
#   brew bundle --file=Brewfile      # install.sh runs this automatically
#   brew bundle check --file=Brewfile   # report what is missing
#
# Scope: the tools these dotfiles configure, plus the CLIs the Claude Code
# skills in claude/ depend on at runtime. This is a deliberate list, NOT a full
# `brew bundle dump` of the machine — add entries on purpose.

tap "hashicorp/tap"
tap "nikitabobko/tap"

# --- bootstrap: dotfile management itself ---
brew "stow"

# --- shell (zsh/, starship/) ---
brew "zsh"
brew "zsh-autosuggestions"
brew "starship"
brew "direnv"
brew "fzf"
brew "fd"
brew "ripgrep"

# --- terminal multiplexer (tmux/) ---
brew "tmux"

# --- editor (nvim/) ---
brew "neovim"
brew "tree-sitter-cli"

# --- window management + key remapping (aerospace/, karabiner/) ---
cask "aerospace"
cask "karabiner-elements"

# --- nerd fonts for the terminal setup ---
cask "font-caskaydia-cove-nerd-font"
cask "font-jetbrains-mono-nerd-font"

# --- git and forge CLIs (the /commit skill; GitLab is the company forge) ---
brew "git"
brew "gh"
brew "glab"

# --- IaC and Kubernetes (the /infra-diagram and /triage skills) ---
brew "hashicorp/tap/terraform"
brew "helm"
brew "helmfile"
brew "kubernetes-cli"
brew "k9s"
brew "kubeconform"

# --- cloud CLIs ---
brew "azure-cli"
cask "gcloud-cli"

# --- general CLI utilities used across the skills ---
brew "jq"
brew "yamllint"
brew "uv"

# --- diagrams ---
# draw.io Desktop provides the `drawio` CLI, which converts Mermaid to native
# .drawio files. Required by the /infra-diagram skill and the drawio@drawio
# plugin; without it they fall back to hand-authored XML.
cask "drawio"
