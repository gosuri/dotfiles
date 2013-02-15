#!/bin/bash
#
# bash environment compiled from various sources
# Greg Osuri <http://gr3g.me/about>

: ${HOME=~}
: ${LOGNAME=$(id -un)}
: ${UNAME=$(uname)}

# complete hostnames from this file
: ${HOSTFILE=~/.ssh/known_hosts}

# readline config
: ${INPUTRC=~/.inputrc}

# git bash completion

: ${GIT_PS1_SHOWDIRTYSTATE=true}
: ${GIT_PS1_SHOWSTASHSTATE=true}
: ${GIT_PS1_SHOWUNTRACKEDFILES=true}

# ================================================================
# SHELL OPTIONS
# ================================================================

# bring in system bashrc
test -r /etc/bashrc &&
      . /etc/bashrc

# notify of bg job completion immediately
set -o notify

# shell opts. see bash(1) for details
shopt -s cdspell >/dev/null 2>&1
shopt -s extglob >/dev/null 2>&1
shopt -s histappend >/dev/null 2>&1
shopt -s hostcomplete >/dev/null 2>&1
shopt -s interactive_comments >/dev/null 2>&1
shopt -u mailwarn >/dev/null 2>&1
shopt -s no_empty_cmd_completion >/dev/null 2>&1

# remove new mail stuff
unset MAILCHECK

# disable core dumps
ulimit -S -c 0

# default umask
umask 0022

# ================================================================
# PATHS
# ================================================================

# we want the various sbins on the path along with /usr/local/bin
PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin"
PATH="/usr/local/bin:$PATH"

# put ~/bin on PATH if you have it
test -d "$HOME/bin" &&
PATH="$HOME/bin:$PATH"

# ================================================================
# ENVIRONMENT CONFIGURATION
# ================================================================

# detect interactive shell
case "$-" in
    *i*) INTERACTIVE=yes ;;
    *)   unset INTERACTIVE ;;
esac

# detect login shell
case "$0" in
    -*) LOGIN=yes ;;
    *)  unset LOGIN ;;
esac

# always use PASSIVE mode ftp
: ${FTP_PASSIVE:=1}
export FTP_PASSIVE


# ================================================================
# RVM and ruby setup
# ================================================================

# Load RVM
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"


# ================================================================
# NodeJS setup
# ================================================================


if test -n "$(command -v npm)"
then
  export NODE_PATH="/usr/local/lib/node_modules:$HOME/node_modules";
  PATH="$PATH:/usr/local/lib/node_modules/npm/bin:$HOME/node_modules/.bin";
  PATH="$PATH:/usr/local/share/npm/bin"
fi


# history config
HISTCONTROL=ignoreboth
HISTFILESIZE=10000
HISTSIZE=10000

# ================================================================
# PAGER / EDITOR
# ================================================================

# EDITOR
if test -n "$(command -v vim)"
then
  export EDITOR=vim
  set -o vi
fi

# PAGER
if test -n "$(command -v less)"
then
    PAGER="less -FirSwX"
    MANPAGER="less -FiRswX"
else
    PAGER=more
    MANPAGER="$PAGER"
fi
export PAGER MANPAGER

# Ack
ACK_PAGER="$PAGER"
ACK_PAGER_COLOR="$PAGER"

# ================================================================
# BASH COMPLETION 
# ================================================================
test -z "$BASH_COMPLETION" && {
    bash=${BASH_VERSION%.*}; bmajor=${bash%.*}; bminor=${bash#*.}
    test -n "$PS1" && test $bmajor -gt 1 && {
        # search for a bash_completion file to source
        for f in /usr/local/etc/bash_completion \
                 /usr/pkg/etc/bash_completion \
                 /opt/local/etc/bash_completion \
                 /etc/bash_completion
        do
            test -f $f && {
                . $f
                break
            }
        done
    }
    unset bash bmajor bminor
}

# ================================================================
# GIT PROMPT
# ================================================================

source $HOME/.dotfiles/git_prompt.sh

# ================================================================
# PROMPT
# ================================================================
MAGENTA="\[\033[1;31m\]"
ORANGE="\033[1;33m"
GREEN="\[\033[1;32m\]"
PURPLE="\[\033[1;35m\]"
WHITE="\[\033[1;37m\]"
RED="\[\033[0;31m\]"
BROWN="\[\033[0;33m\]"
GREY="\[\033[0;97m\]"
BLUE="\[\033[0;34m\]"
RESET="\[\033[m\]"
SCREEN_ESC="\[\033k\033\134\]"

if [ "$LOGNAME" = "root" ]; then
    COLOR1="${RED}"
    COLOR2="${BROWN}"
    P="#"
else
    COLOR1="${BLUE}"
    COLOR2="${BROWN}"
    P="\$"
fi

prompt_simple() {
    unset PROMPT_COMMAND
    PS1="[\u@\h:\w]\$ "
    PS2="> "
}

prompt_compact() {
    unset PROMPT_COMMAND
    PS1="${COLOR1}${P}${RESET} "
    PS2="> "
}

prompt_color() {
    PS1="$BROWN\w $GREEN\$(__git_ps1 '(%s)') $WHITE\n\$ $RESET"
    PS2="\[\033[33;1m\]continue \[\033[0;1m\]> "
}

# override and disable tilde expansion
_expand() {
    return 0
}

# ================================================================
# MACOX SETUP
# ================================================================

if [ "$UNAME" = Darwin ]; then
    # put mac ports on the paths if /opt/local exists
    test -x /opt/local -a ! -L /opt/local && {
        PORTS=/opt/local

        # setup the PATH and MANPATH
        PATH="$PORTS/bin:$PORTS/sbin:$PATH"
        MANPATH="$PORTS/share/man:$MANPATH"

        # nice little port alias
        alias port="sudo nice -n +18 $PORTS/bin/port"
    }

    test -x /usr/pkg -a ! -L /usr/pkg && {
        PATH="/usr/pkg/sbin:/usr/pkg/bin:$PATH"
        MANPATH="/usr/pkg/share/man:$MANPATH"
    }

    # Java setup
    JAVA_HOME="/System/Library/Frameworks/JavaVM.framework/Home"
    ANT_HOME="/Developer/Java/Ant"
    export ANT_HOME JAVA_HOME

    test -d /opt/jruby &&
    JRUBY_HOME="/opt/jruby"
    export JRUBY_HOME

fi

# Use the color prompt by default when interactive
test -n "$PS1" && prompt_color

test -n "$INTERACTIVE" -a -n "$LOGIN" && {
    uname -npsr
    uptime
}

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
