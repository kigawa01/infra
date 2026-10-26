# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export PATH=$PATH:/usr/local/go/bin
export PATH="$PATH:$(go env GOPATH)/bin"

#export PATH="$PATH:$HOME/.nvm/versions/node/v22.19.0/bin"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export IBUS_ENABLE_SYNC_MODE=1
export GTK_IM_MODULE=ibus

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export PATH="${HOME}/.local/bin:${PATH}"

# opencode
export PATH=/home/kigawa/.opencode/bin:$PATH

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/kigawa/.lmstudio/bin"
# End of LM Studio CLI section

#source ~/.profile

# Set BWS_ACCESS_TOKEN in ~/.bash_secrets or via environment variable
# export BWS_ACCESS_TOKEN="<your-1password-token>"
source /home/kigawa/dev/kigawa/kutil-bash/.bashrc
export PATH="/home/kigawa/dev/kigawa/kutil-bash/bin:$PATH"
export KUTIL_SSH_KEY=""
alias lms-headless="tmux has-session -t lms 2>/dev/null || tmux new-session -d -s lms 'xvfb-run -a /opt/LM-Studio/lm-studio --no-sandbox --run-as-service'"

# Set GITHUB_PAT_TOKEN in ~/.bash_secrets or via environment variable
# export GITHUB_PAT_TOKEN='<your-github-pat>'
# Set OP_SERVICE_ACCOUNT_TOKEN in ~/.bash_secrets or via environment variable
# export OP_SERVICE_ACCOUNT_TOKEN='<your-1password-service-account-token>'
export PATH="$HOME/.bun/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Let OpenCode/OpenTUI reach the local Wayland compositor (clipboard)
export WAYLAND_DISPLAY=wayland-0


# strata-idle-aliases
alias strata-start='setsid nohup /fast/strata-data/logs/run-fast.sh >> /fast/strata-data/logs/server.out 2>&1 < /dev/null &'
alias strata-stop='pkill -f "run-coder-iq1_m.sh"; pkill -f "[s]erve/server_intel"; sleep 3; docker rm -f strata-sycl-serve >/dev/null 2>&1'
alias strata-status='curl -s -m 3 http://127.0.0.1:8081/health 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(\"loaded:\",d.get(\"loaded\"),\"/ model:\",d.get(\"model\"))" 2>/dev/null || echo "Strata is not running"'
alias strata-log='tail -10 /fast/strata-data/logs/server.out'
# strata-idle-aliases-end
