#!/bin/bash
set -e
set -o pipefail

# install.sh
#	This script installs my basic setup for a debian laptop

export DEBIAN_FRONTEND=noninteractive

# Choose a user account to use for this installation
get_user() {
	if [ -z "${TARGET_USER-}" ]; then
		mapfile -t options < <(find /home/* -maxdepth 0 -printf "%f\\n" -type d)
		# if there is only one option just use that user
		if [ "${#options[@]}" -eq "1" ]; then
			readonly TARGET_USER="${options[0]}"
			echo "Using user account: ${TARGET_USER}"
			return
		fi

		# iterate through the user options and print them
		PS3='Which user account should be used? '

		select opt in "${options[@]}"; do
			readonly TARGET_USER=$opt
			break
		done
	fi
}

check_is_sudo() {
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root."
		exit
	fi
}


setup_sources_min() {
	apt update
	apt install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		dirmngr \
		lsb-release \
		--no-install-recommends

	# hack for latest git (don't judge)
	cat <<-EOF > /etc/apt/sources.list.d/git-core.list
	deb http://ppa.launchpad.net/git-core/ppa/ubuntu xenial main
	deb-src http://ppa.launchpad.net/git-core/ppa/ubuntu xenial main
	EOF

	# neovim
	cat <<-EOF > /etc/apt/sources.list.d/neovim.list
	deb http://ppa.launchpad.net/neovim-ppa/unstable/ubuntu xenial main
	deb-src http://ppa.launchpad.net/neovim-ppa/unstable/ubuntu xenial main
	EOF

	# add the git-core ppa gpg key
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys E1DD270288B4E6030699E45FA1715D88E1DF1F24

	# add the neovim ppa gpg key
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 9DBB0BE9366964F134855E2255F96FCF8231B6DD

	# turn off translations, speed up apt update
	mkdir -p /etc/apt/apt.conf.d
	echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations
}

base_min() {
	apt update
	apt -y upgrade

	apt install -y \
		adduser \
		automake \
		bash-completion \
		bc \
		bzip2 \
		ca-certificates \
		coreutils \
		curl \
		dnsutils \
		file \
		findutils \
		gcc \
		git \
		gnupg \
		gnupg2 \
		gnupg-agent \
		grep \
		gzip \
		hostname \
		indent \
		iptables \
		jq \
		less \
		libc6-dev \
		libimobiledevice6 \
		locales \
		lsof \
		make \
		mount \
		net-tools \
		neovim \
		pinentry-curses \
		rxvt-unicode-256color \
		scdaemon \
		silversearcher-ag \
		ssh \
		strace \
		sudo \
		tar \
		tree \
		tzdata \
		usbmuxd \
		unzip \
		xclip \
		xcompmgr \
		xz-utils \
		zip \
		--no-install-recommends

	apt autoremove
	apt autoclean
	apt clean

	install_scripts
}

setup_sources() {
	setup_sources_min;
}

# installs base packages
# the utter bare minimal shit
base() {
	base_min;

	apt update
	apt -y upgrade

	apt install -y \
		azure-cli \
		google-cloud-sdk \
		--no-install-recommends

	# install tlp with recommends
	# apt install -y tlp tlp-rdw

	setup_sudo

	apt autoremove
	apt autoclean
	apt clean
}

setup_sudo() {
	# add user to sudoers
	adduser "$TARGET_USER" sudo

	# add user to systemd groups
	# then you wont need sudo to view logs and shit
	gpasswd -a "$TARGET_USER" systemd-journal
	gpasswd -a "$TARGET_USER" systemd-network
}

# install custom scripts/binaries
install_scripts() {
	# install speedtest
	curl -sSL https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py  > /usr/local/bin/speedtest
	chmod +x /usr/local/bin/speedtest

	# install icdiff
	curl -sSL https://raw.githubusercontent.com/jeffkaufman/icdiff/master/icdiff > /usr/local/bin/icdiff
	curl -sSL https://raw.githubusercontent.com/jeffkaufman/icdiff/master/git-icdiff > /usr/local/bin/git-icdiff
	chmod +x /usr/local/bin/icdiff
	chmod +x /usr/local/bin/git-icdiff

	#git completion
	GIT_VERSION=`git --version | awk '{print $3}'`
	URL="https://raw.github.com/git/git/v$GIT_VERSION/contrib/completion/git-completion.bash"
	echo "Downloading git-completion for git version: $GIT_VERSION..."
	if ! curl "$URL" --silent --output "$HOME/.git-completion.bash"; then
	  echo "ERROR: Couldn't download completion script. Make sure you have a working internet connection." && exit 1
	fi

	#zsh
	sudo apt-get install -y zsh

	# oh-my-zsh install
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	chsh -s $(which zsh)

	# oh-my-zsh plugin install
	git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
	git clone git://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting

	compaudit | xargs chown -R "$(whoami)"
	compaudit | xargs chmod g-w

	# vimrc vundle install
	#git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

	# Pathogen install
	#mkdir -p ~/.vim/autoload ~/.vim/bundle && \
	#curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

	# Nerdtree for vim install
	#git clone https://github.com/scrooloose/nerdtree.git ~/.vim/bundle/nerdtree

	# Vim color scheme install
	#git clone https://github.com/sheerun/vim-wombat-scheme.git ~/.vim/colors/wombat
	#mv ~/.vim/colors/wombat/colors/* ~/.vim/colors/
}

get_dotfiles() {
	# create subshell
	(
	cd "$HOME"

	# install dotfiles from repo
	#git clone git@github.com:domokost/dotfiles.git "${HOME}/dotfiles"
	cd "${HOME}/dotfiles"

	# installs all the things
	make

	# enable dbus for the user session
	# systemctl --user enable dbus.socket

	)

	install_vim;
}

install_vim() {
	# create subshell
	(
	cd "$HOME"

	# install .vim files
	git clone --recursive git@github.com:jessfraz/.vim.git "${HOME}/.vim"
	ln -snf "${HOME}/.vim/vimrc" "${HOME}/.vimrc"
	sudo ln -snf "${HOME}/.vim" /root/.vim
	sudo ln -snf "${HOME}/.vimrc" /root/.vimrc

	# alias vim dotfiles to neovim
	mkdir -p "${XDG_CONFIG_HOME:=$HOME/.config}"
	ln -snf "${HOME}/.vim" "${XDG_CONFIG_HOME}/nvim"
	ln -snf "${HOME}/.vimrc" "${XDG_CONFIG_HOME}/nvim/init.vim"
	# do the same for root
	sudo mkdir -p /root/.config
	sudo ln -snf "${HOME}/.vim" /root/.config/nvim
	sudo ln -snf "${HOME}/.vimrc" /root/.config/nvim/init.vim

	# update alternatives to neovim
	sudo update-alternatives --install /usr/bin/vi vi "$(which nvim)" 60
	sudo update-alternatives --config vi
	sudo update-alternatives --install /usr/bin/vim vim "$(which nvim)" 60
	sudo update-alternatives --config vim
	sudo update-alternatives --install /usr/bin/editor editor "$(which nvim)" 60
	sudo update-alternatives --config editor

	# install things needed for deoplete for vim
	sudo apt update

	sudo apt install -y \
		python3-pip \
		python3-setuptools \
		--no-install-recommends

	pip3 install -U \
		setuptools \
		wheel \
		neovim
	)
}

usage() {
	echo -e "install.sh\\n\\tThis script installs my basic setup for a debian laptop\\n"
	echo "Usage:"
	echo "  base                                - setup sources & install base pkgs"
	echo "  basemin                             - setup sources & install base min pkgs"
	echo "  dotfiles                            - get dotfiles"
	echo "  vim                                 - install vim specific dotfiles"
	echo "  scripts                             - install scripts"
}

main() {
	local cmd=$1

	if [[ -z "$cmd" ]]; then
		usage
		exit 1
	fi

	if [[ $cmd == "base" ]]; then
		check_is_sudo
		get_user

		# setup /etc/apt/sources.list
		setup_sources

		base
	elif [[ $cmd == "basemin" ]]; then
		check_is_sudo
		get_user

		# setup /etc/apt/sources.list
		setup_sources_min

		base_min
	elif [[ $cmd == "dotfiles" ]]; then
		get_user
		get_dotfiles
	elif [[ $cmd == "vim" ]]; then
		install_vim
	elif [[ $cmd == "scripts" ]]; then
		install_scripts
	else
		usage
	fi
}

main "$@"

