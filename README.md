# dotfiles

Greg Osuri's dotfiles

## Installation

Fetch the source: 

```sh
git clone git://github.com/gosuri/dotfiles.git ~/.dotfiles
```

Link primary shell config:

```sh
ln -s ~/.dotfiles/.shellrc ~/.shellrc
```

Link desired shell configs:

```sh
# for bash
ln -s ~/.dotfiles/.bashrc ~/.bashrc

# for zsh
ln -s ~/.dotfiles/.zshrc ~/.zshrc
```

## zsh 

Optionally setup zsh; zsh comes packaged on OSX, if not you can install with homebrew: `brew install zsh`. On ubuntu/debian: `sudo apt-get install zsh`

Change the shell to zsh:

```
sudo chsh -s /bin/zsh
```

## Git

Git comes packaged on OSX, if not you can install with homebrew: `brew install git`. On ubuntu/debian: `sudo apt-get install git`. Link git profile using:

```
ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
```

Make sure to update your name, email and signature from `.gitconfig`. The default looks like the below:

```
[user]
	name = Greg Osuri
	email = me@gregosuri.com
	signingkey = 688B0D3791621BF3
```

## vim (~>v8.0) with lua

Using brew for macos: `brew install vim`.

Link `.vimrc` config file:

```sh
ln -s ~/.dotfiles/.vimrc ~/.vimrc
```

### dien for Vim

[Dien](https://github.com/Shougo/dein.vim) is a package manager for `vim`.

Install using:

```sh
# download install script
curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh

# run install script
sh ./installer.sh ~/.cache/dein

# clean up
rm installer.sh
```

Open vim to ensure the plugins are installed properly.
