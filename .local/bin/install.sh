#!/bin/bash

set -e
set -o pipefail

# install.sh
#	Description: Installs the dotfiles based on OS.

#Source: https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script
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

if command -v sudo &> /dev/null
then
    SUDO=sudo
fi

if ! command -v git &> /dev/null
then
   echo "Installing git"
   case $OS in
   Ubuntu*)
       $SUDO apt update
       $SUDO apt install git -y
       ;;
   Debian*)
       $SUDO apt update
       $SUDO apt install git -y
       ;;
   Fedora*)
       $SUDO dnf check-update
       $SUDO dnf install git -y
       ;;
   Arch*)
       $SUDO pacman -Syu git --noconfirm
       ;;
   esac
fi
REPO=https://github.com/domokost/dotfiles.git
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
echo ".dotfiles" >> .gitignore
git clone --bare $REPO $HOME/.dotfiles
mkdir -p .dotfiles-backup && \
dotfiles checkout 2>&1 | grep -E "\s+\." | awk {'print $1'} | \
xargs -I{} mv {} .dotfiles-backup/{}
dotfiles checkout
dotfiles config status.showUntrackedFiles no