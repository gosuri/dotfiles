# Debug flag
DF_DEBUG=0
starts=$(date +%s)

export FPATH=/usr/share/zsh/site-functions:$FPATH  

# ================================================================
# OH MY ZSH SETUP
# ================================================================
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="sorin-custom"

# ================================================================
# PLUGINS
# ================================================================
# Plugins are located under ~/.oh-my-zsh/plugins/* and 
# custom plugins should under ~/.oh-my-zsh/custom/plugins/
plugins=(ovrclk aws golang git bundler github git-flow emoji)

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"
#
# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how many often would you like 
# to wait before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

source $ZSH/oh-my-zsh.sh
source $HOME/.dotfiles/.shellrc

# ================================================================
# HANDY ALIASES
# ================================================================
# Rename files using glob, example 'mmv *.dat *.dat_save'
autoload -U zmv
alias mmv='noglob zmv -W'
alias faye='rackup faye.ru -s thin -E production'

# ================================================================
# NO CORRECTS
# ================================================================
# Disable zsh auto correct 
nocorrects=("storm" "rspec" )
for i in "${nocorrects[@]}"
do
  alias $i="nocorrect $i"
done

# Allow [ or ] whereever you want
unsetopt nomatch

# ================================================================
# KEY BINDINGS
# ================================================================
# 
# Binding <ctrl-r> to history search
# <C-R> mv * /target
bindkey '^R' history-incremental-pattern-search-backward

ends=$(date +%s)
[ "${DF_DEBUG}" == "1" ] && echo "${HOME}/.zshrc load elapsed $(($ends - $starts))s"

unalias gb
