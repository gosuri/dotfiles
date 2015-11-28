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

# ================================================================
# BASH COMPLETION 
# ================================================================
bash=${BASH_VERSION%.*}; bmajor=${bash%.*}; bminor=${bash#*.}
test -n "$PS1" && test $bmajor -gt 1 && {
  # search for a bash_completion file to source
  for f in /usr/local/etc/bash_completion.d \
           /usr/pkg/etc/bash_completion     \
           /opt/local/etc/bash_completion   \
           /etc/bash_completion
  do
      test -f $f && {
          . $f
          break
      }
      test -d $f && . $f/*
  done
}
unset bash bmajor bminor

# ================================================================
# GIT PROMPT
# ================================================================
test -x "$HOME/.dotfiles/bin/git-prompt.sh" && {
  source $HOME/.dotfiles/bin/git-prompt.sh
}

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
    }

    test -x /usr/pkg -a ! -L /usr/pkg && {
        PATH="/usr/pkg/sbin:/usr/pkg/bin:$PATH"
        MANPATH="/usr/pkg/share/man:$MANPATH"
    }
fi

# Use the color prompt by default when interactive
test -n "$PS1" && prompt_color

source $HOME/.dotfiles/.shellrc
