#!/bin/zsh
source $HOME/.shellrc

# Outputs the name of the current branch
# Usage example: git pull origin $(git_current_branch)
# Using '--quiet' with 'symbolic-ref' will not cause a fatal error (128) if
# it's not a symbolic ref, but in a Git repo.
function git_current_branch() {
  local ref
  ref=$(command git symbolic-ref --quiet HEAD 2> /dev/null)
  local ret=$?
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return  # no git repo.
    ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  fi
  echo ${ref#refs/heads/}
}

# ================================================================
# PROMPT
# ================================================================
autoload -U colors && colors

# Left prompt
export PROMPT="[%{$fg[cyan]%}%m%{$fg[blue]%}:%1d%{$reset_color%}] "

# Righ prompt with git info
setopt prompt_subst
autoload -Uz vcs_info
zstyle ':vcs_info:*' actionformats \
    '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f '
zstyle ':vcs_info:*' formats       \
    '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{5}]%f '
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'
zstyle ':vcs_info:*' enable git cvs svn

# or use pre_cmd, see man zshcontrib
vcs_info_wrapper() {
  vcs_info
  if [ -n "$vcs_info_msg_0_" ]; then
    echo "%{$fg[grey]%}${vcs_info_msg_0_}%{$reset_color%}$del"
  fi
}
export RPROMPT=$'$(vcs_info_wrapper)'

# ================================================================
# HISTORY config
# ================================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
setopt SHARE_HISTORY
setopt BANG_HIST 

# ================================================================
# KEY BINDINGS
# ================================================================
# Rename files using glob, example 'mmv *.dat *.dat_save'
autoload -U zmv
alias mmv='noglob zmv -W'
alias ll='ls -al'

# Binding <ctrl-r> to history search
bindkey '^R' history-incremental-pattern-search-backward

# Edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

# ================================================================
# ZSH Completions
# ================================================================
autoload -U compinit && compinit
fpath=(/usr/local/share/zsh-completions $fpath)
