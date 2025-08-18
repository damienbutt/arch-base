# Custom .bashrc for Arch Linux Development Container
# This file is copied to the container during build

# Source the default bashrc if it exists
[ -f /etc/bash.bashrc ] && source /etc/bash.bashrc

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

# Make sure we have colors
export TERM=xterm-256color

# Enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias glog='git log --oneline --graph --decorate'

# Go development aliases
alias gob='go build'
alias gor='go run'
alias got='go test'
alias gom='go mod'
alias gomt='go mod tidy'
alias gov='go vet'
alias gof='go fmt'

# Make aliases
alias mb='make build'
alias mr='make run'
alias mt='make test'
alias mc='make clean'
alias mf='make fmt'
alias ml='make lint'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'

# Utility aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%d-%m-%Y"'

# Make and navigation helpers
alias mkd='mkdir -pv'
alias which='type -a'

# GPG helper
alias setup-gpg='~/setup-gpg.sh'

# Custom prompt with git branch info (fallback if Starship not available)
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Initialize Starship prompt if available, otherwise use custom prompt
if command -v starship > /dev/null 2>&1; then
    eval "$(starship init bash)"
else
    # Fallback to custom colorful prompt
    export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
fi

# Go environment
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin

# GPG environment
export GPG_TTY=$(tty)
export GNUPGHOME=$HOME/.gnupg

# Add workspace bin to PATH if it exists
[ -d "/workspace/bin" ] && export PATH="/workspace/bin:$PATH"

# Development environment indicators
echo "🐧 Arch Linux Development Container"
echo "📁 Workspace: $(pwd)"
echo "🐹 Go version: $(go version 2>/dev/null | cut -d' ' -f3 || echo 'not installed')"
if command -v starship > /dev/null 2>&1; then
    echo "⭐ Starship prompt: enabled"
else
    echo "⭐ Starship prompt: not available (using fallback)"
fi
if command -v gpg > /dev/null 2>&1; then
    echo "🔐 GPG: available ($(gpg --version | head -1 | cut -d' ' -f3 || echo 'unknown version'))"
    # Check if we have any GPG keys
    if gpg --list-secret-keys &>/dev/null; then
        echo "🗝️  GPG keys: found (ready for commit signing)"
        # Auto-configure GPG if enabled and not already done
        if [ "$AUTO_SETUP_GPG" = "true" ] && [ -z "$(git config --global user.signingkey 2>/dev/null)" ]; then
            echo "🔧 Auto-configuring GPG for git..."
            /home/vscode/setup-gpg.sh --quiet --auto 2>/dev/null || true
        fi
    else
        echo "🗝️  GPG keys: none found (import your keys to sign commits)"
        if [ "$AUTO_SETUP_GPG" = "true" ]; then
            echo "💡 Tip: Mount your ~/.gnupg directory to auto-configure GPG"
        fi
    fi
else
    echo "🔐 GPG: not available"
fi
echo "🔧 Available make targets: run 'make help' to see options"
echo ""
