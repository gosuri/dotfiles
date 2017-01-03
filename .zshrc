#!/bin/zsh
# ================================================================
# PROMPT
# ================================================================
# Rename files using glob, example 'mmv *.dat *.dat_save'
autoload -U colors && colors
export PROMPT="[%{$fg[cyan]%}%m%{$fg[blue]%}/%1d%{$reset_color%}]%{$reset_color%} "
export RPROMPT=''

# ================================================================
# HANDY ALIASES
# ================================================================
# Rename files using glob, example 'mmv *.dat *.dat_save'
autoload -U zmv
alias mmv='noglob zmv -W'

# ================================================================
# KEY BINDINGS
# ================================================================
# 
# Binding <ctrl-r> to history search
# <C-R> mv * /target
bindkey '^R' history-incremental-pattern-search-backward

source $HOME/.shellrc
