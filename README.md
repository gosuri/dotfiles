# dotfiles

Greg Osuri's dotfiles

## Installation

Clone the source and link desired shell configs

```
git clone git://github.com/gosuri/dotfiles.git ~/.dotfiles
ln -s ~/.dotfiles/.shellrc ~/.shellrc
ln -s ~/.dotfiles/.bashrc ~/.bashrc
ln -s ~/.dotfiles/.zshrc ~/.zshrc
$ # vim config
$ ln -s ~/.dotfiles/.vimrc ~/.vimrc
```

## zsh 

Optionally setup zsh; zsh comes packaged on OSX, if not you can install with homebrew: `brew install zsh`. On ubuntu/debian: `sudo apt-get install zsh`

Change the shell to zsh:

```
chsh -s /bin/zsh
```

## Git

Git comes packages on OSX, if not you can install with homebrew: `brew install git`. On ubuntu/debian: `sudo apt-get install git`. Link git profile using:

```
ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
```

Make sure to update your name and signature from `.gitconfig`. The default looks like the below:

```
[user]
	name = Greg Osuri
	email = me@gregosuri.com
	signingkey = 688B0D3791621BF3
```

### vim (~>v8.0) with lua

Using brew for macos: `brew install vim`

### Dien

Install using:

```sh
$ curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
$ sh ./installer.sh ~/.vim/.cache/dein
```
