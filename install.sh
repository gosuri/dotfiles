#!/bin/sh
DOTFILES=$HOME/.dotfiles
BASH_COMPLETION=.bash_completion
BASH_PROFILE=.bash_profile
BASHRC=.bashrc
GITCONFIG=.gitconfig
TMUX_CONF=.tmux.conf
VIMRC=.vimrc
VIM=.vim
ZSHRC=.zshrc

function makeLink() {
  TIMESTAMP=$(date "+%s")
  SOURCE=$DOTFILES/$1
  TARGET=$HOME/$1

  # backup if the file exist
  if [ -f $TARGET ]; then
    echo "--> detected existing $TARGET"
    mv $TARGET $TARGET-$TIMESTAMP
    echo "--> backed up $TARGET to $TARGET-$TIMESTAMP"
  fi

  ln -nsf $SOURCE $TARGET
  echo "--> linked $SOURCE to $TARGET"
}

makeLink $BASH_COMPLETION
makeLink $BASH_PROFILE
makeLink $BASHRC
makeLink $GITCONFIG
makeLink $TMUX_CONF
makeLink $VIMRC
makeLink $VIM
makeLink $ZSHRC
