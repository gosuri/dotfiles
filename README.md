# dotfiles

Greg Osuri's dotfiles. The below instructions are optimized for OSX.

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

### Errors & Warnings

If you get below error:

```
Ignore insecure directories and continue [y] or abort compinit [n]? ncompinit: initialization aborted
```

Fix insecure directories by running:

```
sudo chmod g-w $(compaudit)
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

## Go Lang (optional)

Install using brew:

```sh
brew install golang
```

The shell profile uses a default `GOPATH`. Ensure `$GOPATH` exists:

```sh
mkdir -p $GOPATH
```

### Enable VIM bindings

Open vim and run below:

```
:GoInstallBinaries
```

## Rust (Optional)

Install using Homebrew:

```sh
brew install rust
```

The above command installs `rustc` and `cargo`. The path will include `$HOME/.cargo/bin` automatically.
