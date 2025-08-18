HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=${HISTSIZE}
HISTDUP=erase
setopt extendedglob
setopt notify
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

unsetopt autocd
unsetopt beep
unsetopt nomatch

bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

zstyle :compinstall filename "$HOME/.zshrc"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

autoload -Uz compinit && compinit

# Env
export NVIM_APPNAME=""
export PAGER="less"
export COLORTERM="truecolor"
export GPG_TTY="$(tty)"
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export EDITOR="nvim"
export LESS="FRX"

export LESSOPEN="|lesspipe.sh %s" LESS_ADVANCED_PREPROCESSOR=1

########################################################################
# Aliases
########################################################################
alias cls="clear"
alias vi="nvim"
alias vim="nvim"
alias ls="eza --icons --header --git --group"
alias tree="eza -T -a --icons -I 'node_modules|.git|.history'"
alias mkdir="mkdir -p"
alias cat="bat"
alias grep="rga -. -i"
alias cp="cp -ip"
alias mv="mv -i"
alias rm="rm -i"

## git aliases
function gci { git commit -m "$@"; }
function gaci { git commit -am "$@"; }
alias gc="git commit"
alias gco="git checkout"
alias gsw="git switch"
alias gsm="gsw master"
alias gs="git status"
alias gpull="git pull"
alias gf="git fetch"
alias gfa="git fetch --all"
alias gf="git fetch origin"
alias gpush="git push"
alias gd="git diff"
alias ga="git add"
alias gaa="git add ."
alias gap="git add -p"
alias gb="git branch"
alias gba="git branch -a"
alias gbd="git branch -D"
alias gbr="git branch remote"
alias gfr="git remote update"
alias gbn="git checkout -b"
alias grf="git reflog"
alias grb="git rebase"
alias grp="git remote prune origin"
alias grh="git reset HEAD~" # last commit
alias gac="git commit -a"
alias gr="git restore"
alias grs="git restore --staged"
alias gsu="git gpush --set-upstream origin"
alias gl="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --branches | emojify | less"

# Set the directory for zinit and plugins
export ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download zinit, if it's not there yet
if [ ! -d "${ZINIT_HOME}" ]; then
   mkdir -p "$(dirname ${ZINIT_HOME})"
   git clone https://github.com/zdharma-continuum/zinit.git "${ZINIT_HOME}"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-history-substring-search
zinit light hlissner/zsh-autopair

zinit cdreplay -q

eval "$(starship init zsh)"
eval "$(atuin init zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(fzf --zsh)"

autoload -Uz compinit
compinit
