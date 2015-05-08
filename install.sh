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

bold=`tput bold`
normal=`tput sgr0`

_log() {
  echo "==> $1"
}

function _setGitAttr() {
	printf "$1: "
	read -r val
	if [ -n "$val" ]; then
		cmd="git config --global --replace-all $2 '$val'"
		_log "exec: $cmd"
		eval "$cmd"
		_log "gitconfig: $2 is $(git config $2)"
    
    # 3rd attribute
		if [ -n "$3" ]; then
			cmd="git config --global $3 $val"
			_log "exec: $cmd"
			eval "$cmd"
		fi
	else
		_log "skipping $2 $3"
	fi
}

function install_gitconfig() {
  _log "${bold}Setting .gitconfig${normal}"
  echo 
  cp $GIT_CONF_TMPL $HOME/.gitconfig
  _setGitAttr "Your name" "user.name"
  echo 
  _setGitAttr "Your email" "user.email" "sendmail.smtpuser"
  echo 
  _setGitAttr "Your github username" "github.username"
}

function install_zsh() {
  if ! [ -n "$(command -v zsh)" ]
  then
    _log "ZSH is not found. Installing ZSH"
    sudo apt-get install zsh
  fi
  chsh -s /bin/zsh
}

function install_omzsh() {
  if test -d $HOME/.oh-my-zsh
  then
    _log "skipping .oh-my-zsh. $HOME/.oh-my-zsh exists"
  else
    _log "installing oh-my-zsh"
    git clone git://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh
  fi

  if test -f $HOME/.oh-my-zsh/themes/sorin-custom.zsh-theme
  then
    _log "skipping: sorin-custom.zsh-theme exists"
  else
    _log "linking sorin-custom zsh theme"
    ln -s $DOTFILES/themes/sorin-custom.zsh-theme $HOME/.oh-my-zsh/themes/sorin-custom.zsh-theme
  fi
  _log "finished: oh-my-zsh"
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
  makeLink $TMUX_CONF
  makeLink $VIMRC
  makeLink $VIM
  makeLink $ZSHRC
  echo "--> finished linking"
}

function main() {
  echo "--> installing dotfiles to $DOTFILES"
  pushd $DOTFILES > /dev/null &2>1
  install_gitconfig
  install_omzsh
  makeAllLinks
  popd > /dev/null
  echo "--> finished installing .dotfiles"
}

main
