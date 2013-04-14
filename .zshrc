ZSH=$HOME/.oh-my-zsh
ZSH_THEME="sorin"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"
#
# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how many often would you like to wait before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git)

source $ZSH/oh-my-zsh.sh

# notify of bg job completion immediately
set -o notify

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
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

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
# NodeJS setup
# ================================================================

if test -n "$(command -v npm)"
then
  export NODE_PATH="/usr/local/lib/node_modules:$HOME/node_modules";
  PATH="$PATH:/usr/local/lib/node_modules/npm/bin:$HOME/node_modules/.bin";
  PATH="$PATH:/usr/local/share/npm/bin"
fi

# ================================================================
# AWS EC2 Setup
# ================================================================
# Your certificate download:http://aws-portal.amazon.com/gp/aws/developer/account/index.html?action=access-key
# Download two ".pem" files, one starting with `pk-`, and one starting with `cert-`.
# You need to put both into a folder in your home directory, `~/.ec2`.
if [ -f "$HOME"/.ec2/pk-*.pem ]; then
  EC2_PRIVATE_KEY="$(/bin/ls "$HOME"/.ec2/pk-*.pem | /usr/bin/head -1)"
fi

if [ -f "$HOME"/.ec2/cert-*.pem ]; then
  EC2_CERT="$(/bin/ls "$HOME"/.ec2/cert-*.pem | /usr/bin/head -1)"
fi

test -d  /usr/local/Library/LinkedKegs/ec2-api-tools/jars &&
  EC2_HOME="/usr/local/Library/LinkedKegs/ec2-api-tools/jars"

export EC2_HOME EC2_PRIVATE_KEY EC2_CERT


test -n "$INTERACTIVE" -a -n "$LOGIN" && {
    uname -npsr
    uptime
}


if [ -f "$HOME"/.env ]; then
  source $HOME/.env
fi
