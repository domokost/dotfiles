#!/usr/bin/env bash

# Only enable these shell behaviours if we're not being sourced
# Approach via: https://stackoverflow.com/a/28776166/8787985
if ! (return 0 2> /dev/null); then
    set -o errexit      # Exit on most errors (see the manual)
    set -o nounset      # Disallow expansion of unset variables
    set -o pipefail     # Use last non-zero exit code in a pipeline
fi

# Enable debug mode, >TRACE=1 ./template.sh
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

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
    error 'Could not find the command "sudo"'
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
    warn "Running as root!"
  else
    warn "Escalated permissions are required to continue."
    elevate_priv
    sudo="sudo"
  fi
}

usage() {
  echo -e "template.sh\\n\\tMinimal, functional bash script template\\n"
  echo "Usage:"
  echo "  -c, --command                           - command to execute" 
  echo "  -h, --help                              - displays this help"
}

# Change the directory to the script's
cd "$(dirname "$0")"

main() {
  cmd="${1:-}"
  
  #Add default value to the first argument
  #cmd="${1:---command}"

  if [[ $cmd =~ ^-*h(elp)?$ ]]; then
    usage
  elif [[ $cmd =~ ^-*c(ommand)?$ ]]; then
    check_priv 
    info "Command to execute"
    user="$(sudo whoami)"
    info "Running as $user"
  else
    usage 
  fi
}

main "$@"
