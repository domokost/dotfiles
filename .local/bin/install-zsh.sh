#!/usr/bin/env bash

set -eu
printf '\n'

BOLD="$(tput bold 2>/dev/null || printf '')"
GREY="$(tput setaf 0 2>/dev/null || printf '')"
UNDERLINE="$(tput smul 2>/dev/null || printf '')"
RED="$(tput setaf 1 2>/dev/null || printf '')"
GREEN="$(tput setaf 2 2>/dev/null || printf '')"
YELLOW="$(tput setaf 3 2>/dev/null || printf '')"
BLUE="$(tput setaf 4 2>/dev/null || printf '')"
MAGENTA="$(tput setaf 5 2>/dev/null || printf '')"
NO_COLOR="$(tput sgr0 2>/dev/null || printf '')"

info() {
  printf '%s\n' "${BOLD}${GREY}>${NO_COLOR} $*"
}

warn() {
  printf '%s\n' "${YELLOW}! $*${NO_COLOR}"
}

error() {
  printf '%s\n' "${RED}x $*${NO_COLOR}" >&2
}

completed() {
  printf '%s\n' "${GREEN}✓${NO_COLOR} $*"
}

has() {
  command -v "$1" 1>/dev/null 2>&1
}

elevate_priv() {
  if ! has sudo; then
    error 'Could not find the command "sudo", needed to get permissions for install.'
    info "If you are on Windows, please run your shell as an administrator, then"
    info "rerun this script. Otherwise, please run this script as root, or install"
    info "sudo."
    exit 1
  fi
  if ! sudo -v; then
    error "Superuser not granted, aborting installation"
    exit 1
  fi
}

install_zsh() {

  if ! [ "$EUID" -ne 0 ]; then
    sudo=""
    msg="Updating and installing zsh, please wait…"
  else
    warn "Escalated permissions are required to continue."
    elevate_priv
    sudo="sudo"
    msg="Updating and installing zsh as root, please wait…"
  fi
  info "$msg"
  # shellcheck source=./os.sh
  source ~/.local/bin/os.sh info

  case $OS in
  Ubuntu)
    export DEBIAN_FRONTEND=noninteractive
    ${sudo} apt update
    ${sudo} apt -y upgrade
    ${sudo} apt install -y zsh 
    ${sudo} apt autoremove
    ${sudo} apt autoclean
    ${sudo} apt clean
    ;;
  Debian*)
    export DEBIAN_FRONTEND=noninteractive
    ${sudo} apt update
    ${sudo} apt -y upgrade
    ${sudo} apt install -y zsh 
    ${sudo} apt autoremove
    ${sudo} apt autoclean
    ${sudo} apt clean
    ;;
  Fedora*)
    ${sudo} dnf check-update
    ${sudo} dnf update -y
    ${sudo} dnf install -y zsh 
    ;;
  Arch*)
    ${sudo} pacman -Syu --noconfirm zsh 
    ;;
  esac
  info "Installing oh-my-zsh..."

  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # syntax hightlight
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

  # autosuggest
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

  # completions
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
  
  info "Setting zsh as the default shell"
  sh -s $(which zsh) 
}



install_zsh
