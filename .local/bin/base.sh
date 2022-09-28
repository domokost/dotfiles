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

install() {

  if ! [ "$EUID" -ne 0 ]; then
    sudo=""
    msg="Updating and installing packages, please wait…"
  else
    warn "Escalated permissions are required to continue."
    elevate_priv
    sudo="sudo"
    msg="Updating and installing packages as root, please wait…"
  fi
  info "$msg"
  # shellcheck source=./os.sh
  source ./os.sh info

  case $OS in
  Ubuntu)
    export DEBIAN_FRONTEND=noninteractive
    ${sudo} apt update
    ${sudo} apt -y upgrade
    ${sudo} apt install -y autoconf automake apt-transport-https bash-completion build-essential ca-certificates coreutils curl dnsutils findutils git gzip grep gnupg gnupg2 gnupg-agent grep gzip hostname less lsb-release make mount neovim net-tools ssh strace sudo tar tmux tree tzdata unzip vim xz-utils zip zsh
    ${sudo} apt autoremove
    ${sudo} apt autoclean
    ${sudo} apt clean
    ;;
  Debian*)
    export DEBIAN_FRONTEND=noninteractive
    ${sudo} apt update
    ${sudo} apt -y upgrade
    ${sudo} apt install -y autoconf automake apt-transport-https bash-completion build-essential ca-certificates coreutils curl dnsutils findutils git gzip grep gnupg gnupg2 gnupg-agent grep gzip hostname less lsb-release make mount neovim net-tools ssh strace sudo tar tmux tree tzdata unzip vim xz-utils zip zsh
    ${sudo} apt autoremove
    ${sudo} apt autoclean
    ${sudo} apt clean
    ;;
  Fedora*)
    ${sudo} dnf check-update
    ${sudo} dnf update -y
    ${sudo} dnf install -y autoconf automake apt-transport-https bash-completion build-essential ca-certificates coreutils curl dnsutils findutils git gzip grep gnupg gnupg2 gnupg-agent grep gzip hostname less lsb-release make mount neovim net-tools ssh strace sudo tar tmux tree tzdata unzip vim xz-utils zip zsh
    ;;
  Arch*)
    ${sudo} pacman-key --init
    ${sudo} pacman-key --populate
    ${sudo} pacman -S archlinux-keyring
    ${sudo} pacman -Syu --noconfirm autoconf automake bash-completion ca-certificates coreutils curl dnsutils findutils git gzip grep gnupg grep gzip less lsb-release make neovim net-tools openssh strace sudo tar tmux tree tzdata unzip vim xz zip zsh
    ;;
  esac
  info "Installing brew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # shellcheck disable=SC2016
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>"$HOME"/.profile
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  info "Installing starship..."
  brew install starship
}

install
