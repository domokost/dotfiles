#!/bin/bash

# install.sh
#       Description: Installs the dotfiles based on OS.

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root, or with sudo."
    USER_HOME=$HOME
    exit
else
    USER_HOME=$(eval echo ~"${SUDO_USER}")
fi

echo "$USER_HOME"

#Source: https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    # shellcheck source=/dev/null
    source /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    # shellcheck source=/dev/null
    source /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

echo "$OS $VER"

if ! command -v git &>/dev/null; then
    echo "Installing git"
    case $OS in
    Ubuntu)
        export DEBIAN_FRONTEND=noninteractive
        apt update
        apt install git -y
        ;;
    Debian*)
        export DEBIAN_FRONTEND=noninteractive
        apt update
        apt install git -y
        ;;
    Fedora*)
        dnf check-update
        dnf install git -y
        ;;
    Arch*)
        pacman -Syu git --noconfirm
        ;;
    esac
fi

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
chown -R $SUDO_USER:$SUDO_USER .*
