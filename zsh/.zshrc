ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
# Initialize vi-mode immediately to avoid keybinding conflicts
# ZVM_INIT_MODE=sourcing
# zinit light jeffreytse/zsh-vi-mode
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# This pulls just the key-bindings file from the Oh My Zsh library
# It uses your system's terminfo database to automatically map keys (Arrows, Home, End, Delete) correctly for your specific terminal.
zinit snippet OMZL::key-bindings.zsh

# History settings
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
HISTORY_IGNORE="(export *|curl *)"

# The following lines were added by compinstall
zstyle :compinstall filename '$HOME/.zshrc'
autoload -Uz compinit
# Only regenerate completions once per day
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
# End of compinstall


# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# zsh autosuggestion keybind
bindkey '^ ' autosuggest-accept # this would bind ctrl + space to accept the current suggestion.

# Source shared aliases, exports, and integrations
[ -f ~/.shell_secrets ] && source ~/.shell_secrets
[ -f ~/.shell_aliases ] && source ~/.shell_aliases
[ -f ~/.shell_exports ] && source ~/.shell_exports
[ -f ~/.shell_utils ] && source ~/.shell_utils

# NVM (Node Version Manager) integration (Arch based)
[[ -s "/usr/share/nvm/init-nvm.sh" ]] && source /usr/share/nvm/init-nvm.sh
# NVM (Node Version Manager) integration (MacOs based)
[[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# SDKMAN integration
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# direnv integration
if command -v direnv >/dev/null 2>&1; then
    if [ -n "$BASH_VERSION" ]; then
        eval "$(direnv hook bash)"
    elif [ -n "$ZSH_VERSION" ]; then
        eval "$(direnv hook zsh)"
    fi
fi

# Shell integrations
eval "$(fzf --zsh)"
eval "$(starship init zsh)"

# MacOS iTerm2 & Zsh Shell Integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

KEYTIMEOUT=1
