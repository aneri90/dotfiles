# Shared with zsh. Loaded before the interactive check so non-interactive shells
# (Claude Code's Bash tool snapshot) get the same PATH and credentials.
[ -f ~/.shell_secrets ] && . ~/.shell_secrets
[ -f ~/.shell_exports ] && . ~/.shell_exports

[ -s /usr/share/nvm/init-nvm.sh ] && . /usr/share/nvm/init-nvm.sh
[ -s /opt/homebrew/opt/nvm/nvm.sh ] && . /opt/homebrew/opt/nvm/nvm.sh
[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && . "$HOME/.sdkman/bin/sdkman-init.sh"

case $- in
    *i*) ;;
    *) return ;;
esac

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

