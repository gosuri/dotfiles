Greg Osuri's dotfiles

## Installing

clone the source and link desired configs

```
$ git clone git://github.com/gosuri/dotfiles.git ~/.dotfiles
$ # zsh config
$ ln -s ~/.dotfiles/.shellrc ~/.shellrc
$ ln -s ~/.dotfiles/.zshrc ~/.zshrc
$ # vim config
$ ln -s ~/.dotfiles/.vimrc ~/.vimrc
```
## Dependencies

### Git

on ubuntu/debian: `sudo apt-get install git`

git comes packages on OSX, if not you can install with homebrew: `brew install git`

### zsh 

on ubuntu/debian: `sudo apt-get install zsh`

zsh comes packaged on OSX, if not you can install with homebrew: `brew install zsh`

Change the shell to zsh:

```
$ chsh -s /bin/zsh
```

### vim (~>v8.0) with lua

Using brew for macos: `brew install vim`

### Dien

Install using:

```sh
$ curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
$ sh ./installer.sh ~/.vim/.cache/dein
```
