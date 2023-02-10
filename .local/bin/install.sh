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
source ~/.local/bin/helper-functions
# Get OS and ARCH information
source ~/.local/bin/os

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
