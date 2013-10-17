#!/usr/bin/env /bin/bash
#
# Copyright 2013 Greg Osuri <gosuri@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

DOTFILES=$HOME/.dotfiles
GIT_CONF_TMPL=$DOTFILES/templates/gitconfig.template

BASH_COMPLETION=.bash_completion
BASH_PROFILE=.bash_profile
BASHRC=.bashrc
GITCONFIG=.gitconfig
TMUX_CONF=.tmux.conf
VIMRC=.vimrc
VIM=.vim
ZSHRC=.zshrc

# .gitconfig
function getName() {
  printf "Your name: "
  read -r name
}

function getEmail() { 
  printf "Your email: "
  read -r email
}

function getGHUser() {
  printf "Your github username: "
  read -r github_user
}

function renderTempl() {
  cat $GIT_CONF_TMPL | sed "s/@name/$name/g" | sed "s/@email/$email/g" | sed "s/@github_user/$github_user/g"
}

function install_gitconfig() {
  echo "--> installing .gitconfig"
  getName
  getEmail
  getGHUser
  if [ -n "$name" ] && [ -n $email ] && [ -n $github_user ]
  then
    renderTempl > $DOTFILES/.gitconfig
    echo "--> generated $DOTFILES/.gitconfig"
  else
    echo "--> could not install .gitconfig due to missing info"
  fi
  echo "--> finished installing .gitconfig"
}

function install_zsh() {
  if ! [ -n "$(command -v zsh)" ]
  then
    echo "--> ZSH is not found. Installing ZSH"
    sudo apt-get install zsh
  fi
  chsh -s /bin/zsh
}

function install_omzsh() {
  echo "--> installing oh-my-zsh"
  git clone git://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh
  echo "--> finished installing oh-my-zsh"
}

function makeLink() {
  TIMESTAMP=$(date "+%s")
  SOURCE=$DOTFILES/$1
  TARGET=$HOME/$1

  # backup if the file exist
  if test -f $TARGET || test -d $TARGET
  then
    echo "--> detected existing $TARGET"
    mv $TARGET $TARGET-$TIMESTAMP
    echo "--> backed up $TARGET to $TARGET-$TIMESTAMP"
  fi

  ln -nsf $SOURCE $TARGET
  echo "--> linked $SOURCE to $TARGET"
}

function makeAllLinks() {
  echo "--> linking"
  makeLink $BASH_COMPLETION
  makeLink $BASH_PROFILE
  makeLink $BASHRC
  makeLink $GITCONFIG
  makeLink $TMUX_CONF
  makeLink $VIMRC
  makeLink $VIM
  makeLink $ZSHRC
  echo "--> finished linking"
}

function main() {
  echo "--> installing dotfiles to $DOTFILES"
  pushd $DOTFILES > /dev/null
  install_gitconfig
  install_omzsh
  makeAllLinks
  popd > /dev/null
  echo "--> finished installing .dotfiles"
}

main
