#!/usr/bin/env bash

# Only enable these shell behaviours if we're not being sourced
# Approach via: https://stackoverflow.com/a/28776166/8787985
if ! (return 0 2> /dev/null); then
    # A better class of script...
    set -o errexit      # Exit on most errors (see the manual)
    set -o nounset      # Disallow expansion of unset variables
    set -o pipefail     # Use last non-zero exit code in a pipeline
fi

# Get helper functions
# Get OS and ARCH information
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

check_priv() {

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
}

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

# Bits
case $(uname -m) in
x86_64)
    BITS=64
    ;;
i*86)
    BITS=32
    ;;
*)
    BITS=?
    ;;
esac

# CPU architecture
case $(uname -m) in
x86_64)
    ARCH=x64  # or AMD64 or Intel64 or whatever
    ;;
i*86)
    ARCH=x86  # or IA32 or Intel32 or whatever
    ;;
*)
    # leave ARCH as-is
    ;;
esac

if [ "$EUID" -ne 0 ]; then
    USER_HOME=$HOME
else
    USER_HOME=$(eval echo ~"${SUDO_USER}")
fi

info "$OS $VER, $BITS bits and $ARCH."
info "$USER_HOME"

install_git() {
  if ! has git; then
    info "Installing git..."
    case $OS in
      Ubuntu)
        export DEBIAN_FRONTEND=noninteractive
        {sudo} apt update
        {sudo} apt install git -y
        ;;
      Debian*)
        export DEBIAN_FRONTEND=noninteractive
        {sudo} apt update
        {sudo} apt install git -y
        ;;
      Arch*)
        {sudo} pacman -Syu git --noconfirm
        ;;
    esac
  fi
}

install_dotfiles() {
  info "Installing dotfiles..."

  REPO=https://github.com/domokost/dotfiles.git

  function dotfiles {
    /usr/bin/git --git-dir="$USER_HOME/.dotfiles/" --work-tree="$USER_HOME" "$@"
  }

  echo ".dotfiles" >>.gitignore

  git clone --bare "$REPO" "$USER_HOME"/.dotfiles

  mkdir -p "$USER_HOME"/.dotfiles-backup &&
    dotfiles checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' |
    xargs -I{} mv {} "$USER_HOME"/.dotfiles-backup/{}

  dotfiles checkout
  dotfiles config status.showUntrackedFiles no
  chown -R "$SUDO_USER":"$SUDO_USER" "$USER_HOME"/.*
}

install_base_packages() {
  case $OS in
  Ubuntu)
    export DEBIAN_FRONTEND=noninteractive
    ${sudo} apt update
    ${sudo} apt -y upgrade
    ${sudo} apt install -y autoconf automake apt-transport-https bash-completion build-essential ca-certificates coreutils curl dnsutils findutils git gzip grep gnupg gnupg2 gnupg-agent grep gzip hostname keychain less lsb-release make mount neovim net-tools ssh strace sudo tar tmux tree tzdata unzip vim xz-utils zip zsh
    ${sudo} apt autoremove
    ${sudo} apt autoclean
    ${sudo} apt clean
    ;;
  Debian*)
    export DEBIAN_FRONTEND=noninteractive
    ${sudo} apt update
    ${sudo} apt -y upgrade
    ${sudo} apt install -y autoconf automake apt-transport-https bash-completion build-essential ca-certificates coreutils curl dnsutils findutils git gzip grep gnupg gnupg2 gnupg-agent grep gzip hostname keychain less lsb-release make mount neovim net-tools ssh strace sudo tar tmux tree tzdata unzip vim xz-utils zip zsh
    ${sudo} apt autoremove
    ${sudo} apt autoclean
    ${sudo} apt clean
    ;;
  Arch*)
    ${sudo} pacman-key --init
    ${sudo} pacman-key --populate
    ${sudo} pacman -S archlinux-keyring
    ${sudo} pacman -Syu --noconfirm autoconf automake bash-completion ca-certificates coreutils curl dnsutils findutils git gzip grep gnupg grep gzip keychain less lsb-release make neovim net-tools openssh strace sudo tar tmux tree tzdata unzip vim xz zip zsh
    ;;
  esac

  info "Installing brew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # shellcheck disable=SC2016
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>"$HOME"/.profile
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  info "Installing starship..."
  brew install starship
  # install tmux tpm
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

install_nvim() {
  info "Installing nvim..."
  brew install nvim
}


install_zsh() {
  info "Installing zsh..."
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
  Arch*)
    ${sudo} pacman -Syu --noconfirm zsh 
    ;;
  esac
  info "Installing oh-my-zsh..."

  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc --unattended

  # syntax hightlight
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

  # autosuggest
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

  # completions
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
  
  info "Setting zsh as the default shell"
  sh -s $(which zsh) 
}

usage() {
  echo -e "install.sh\\n\\tThis script installs base packages and dotfiles to a new system\\n"
  echo "Usage:"
  echo "  all                                 - installs base, dotfiles and nvim"
  echo "  base                                - setup sources & install base pkgs"
  echo "  dotfiles                            - get dotfiles"
  echo "  nvim                                - install nvim specific dotfiles"
  echo "  help                                - displays this help"
}

main() {
  cmd="${1:-base}"


  if [[ $cmd == "all" ]]; then
    check_priv
    install_git
    install_dotfiles
    install_base_packages
    install_zsh
    install_nvim
  elif [[ $cmd == "base" ]]; then
    check_priv
    install_git
    install_base_packages
  elif [[ $cmd == "dotfiles" ]]; then
    check_priv
    install_git
    install_dotfiles
  elif [[ $cmd == "nvim" ]]; then
    check_priv
    install_git
    install_nvim
  elif [[ $cmd == "help" ]]; then
    usage
  fi
}

main "$@"
