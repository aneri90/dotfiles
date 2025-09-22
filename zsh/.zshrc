# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Shell config
export LANG=en_US.UTF-8

# zsh config & Theme
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git colored-man-pages colorize macos zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Reevaluate the prompt string each time it's displaying a prompt
setopt prompt_subst
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
autoload bashcompinit && bashcompinit
autoload -Uz compinit
compinit

# zsh autosuggestion & bindings
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
#bindkey '^w' autosuggest-execute
#bindkey '^e' autosuggest-accept
bindkey '^ ' autosuggest-accept # this would bind ctrl + space to accept the current suggestion.
bindkey '^u' autosuggest-toggle
#bindkey '^L' vi-forward-word
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search

# zsh autosuggestion options
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#808080,underline'
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=("${(@)ZSH_AUTOSUGGEST_ACCEPT_WIDGETS:#forward-char}") # disable right arrow key for completion

# Allow infinite reverse search history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
HISTSIZE=-1
SAVEHIST=-1

# glab completions
source <(glab completion -s zsh); compdef _glab glab

# Where should I put you?
bindkey -s ^f "tmux-sessionizer\n"

# Load credentials
source $HOME/.secrets.sh

# Neovim
alias v="/opt/homebrew/bin/nvim"
alias vi="/opt/homebrew/bin/nvim"
alias vim="/opt/homebrew/bin/nvim"
alias neovim="/opt/homebrew/bin/nvim"
alias nvc='cd $HOME/.config/nvim && vim' # Neovim config Path shortcuts
export EDITOR=/opt/homebrew/bin/nvim
export VISUAL=/opt/homebrew/bin/nvim

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# qol
alias reload='source ~/.zshrc'
alias fuck='sudo $(history -p \!\!)'
alias gpc='git pull && code .'

## JHIPSTER DOCKER
alias a-jhip-run='docker pull jhipster/jhipster:main && (docker rm jhipster || true) && sudo rm -rf ~/jhipster-main && mkdir ~/jhipster-main && docker container run --name jhipster -v ~/jhipster-main:/home/jhipster/app -d -t jhipster/jhipster:main && docker container exec -it --user root jhipster bash'
alias a-jhip-build-run='docker build -t jhipster/jhipster:main . && (docker rm jhipster || true) && sudo rm -rf ~/jhipster-main && mkdir ~/jhipster-main && docker container run --name jhipster -v ~/jhipster-main:/home/jhipster/app -d -t jhipster/jhipster:main && docker container exec -it --user root jhipster bash'
alias a-jhip-stop='docker rm -f jhipster && sudo chown -R aleneri: ~/jhipster-main'

## ALIAS DOCKER BUILD
alias docker-rebuild='docker compose build && docker compose up -d'

# Git
alias gc="git commit -m"
alias gs="git status"
alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"

# k8s
alias k='kubectl'
alias kco-ls='kubectl config view | grep cluster:'
alias kco-switch='kubectl config use-context'
source <(kubectl completion zsh)

# IDEA LAUNCHER
export PATH="/Applications/IntelliJ\ IDEA.app/Contents/MacOS:$PATH"

# Go binaries in path
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# HOMEBREW CONFIGS
export HOMEBREW_NO_ENV_HINTS=TRUE
# python in path
export PATH=/opt/homebrew/opt/python@3.11/libexec/bin:$PATH

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"


# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"


# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/aleneri/.lmstudio/bin"

# pgdump in Path without postgres (brew install libpq)
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
