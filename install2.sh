#!/usr/bin/env bash

PROGRAM=dotfiles

# defaults
DOTFILES=$HOME/.dotfiles
GITCONFIG=$HOME/.gitconfig

# colors
normal=$(tput sgr0)
reset=$(tput sgr0)
red=$(tput setaf 1)
bold=$(tput bold)

set -o nounset 
set -o errexit 
set -o pipefail

function run() {
  local should_install_zsh=0
  abort_if_missing_command "git" "git is required"

  # abort if the dotfiles directory is missing
  [[ -d $DOTFILES ]] || abort "${DOTFILES} is missing"

  # abort if 

  if [[ "$(uname)" == "Darwin" ]]; then
    if ! [ type "brew" >/dev/null 2>&1 ]; then
      # Ask for ZSH
    fi
    abort_if_missing_command "git" "git is required"
  fi

  info "Installing dotfiles from ${DOTFILES}"
  echo

  # configure git
  config_git

  config_shell
}

function config_shell() {
  # Ask user to for zsh
  case $SHELL in 
    *bash)
      read -e -p "    ${bold}Would you like to use zsh?${reset}: " should_install_zsh
      if [[ "${should_install_zsh}" == "Y" ]]; then
        # install ZSH
        config_shell
      else
        curl -L http://install.ohmyz.sh | sh
        if [[ "$(uname)" == "Darwin" ]]; then
        fi
        log "skipping zsh"
      fi
      ;;
    *zsh)
      ;;
  esac
}

# set_git_attr "Question" "attribute"
# Sets the git config attributes based on user's response
function set_git_attr() {
  local query="$1"
  local val=''
  local attr="$2"
  read -e -p "    ${bold}${query}${reset}: " val
  if [ "${val}" ]; then
    git config --global --replace-all ${attr} "${val}"
  else
    log "[skip] ${attr} not configured"
  fi
}

function config_git() {
  notice "Configuring git under ${GITCONFIG}"
  cp ${DOTFILES}/files/gitconfig $GITCONFIG
  set_git_attr "Your name" "user.name"
  set_git_attr "Your email" "user.email" "sendmail.smtpuser"
  set_git_attr "Your github username" "github.username"

  # enable git credentials helper on mac
  if [[ "$(uname)" == "Darwin" ]]; then
    local path="$(dirname $(which git))/git-credential-osxkeychain"
    if [[ -f ${path} ]]; then
      git config --global credential.helper osxkeychain
    else
      read -e -p "    ${bold}Would you like to install git-credential-osxkeychain plugin?(Y/n): ${reset}" install_git_cred
      if [[ "${install_git_cred}" == "Y" ]]; then
        curl -sLo "${path}" https://github-media-downloads.s3.amazonaws.com/osx/git-credential-osxkeychain
        chmod +x ${path}
        git config --global credential.helper osxkeychain
      fi
    fi
  fi
}

function abort_if_missing_command() {
  local cmd=$1
  type ${cmd} >/dev/null 2>&1 || abort "${2}"
}

function abort() {
  local red=$(tput setaf 1)
  local reset=$(tput sgr0)
  local msg="${red}==> FATAL: $@${reset}"
  echo >&2 -e "${msg}"
  exit 1
}

function info() {
  echo -e "${bold}==> ${*}${reset}"
}

function notice() {
  echo -e "${bold}    ${*}${reset}"
}

function log() {
  echo -e "    ${*}"
}

run
