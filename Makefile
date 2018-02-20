

.PHONY: all
all: bin dotfiles ##etc ## Installs the bin and etc directory files and the dotfiles.

.PHONY: bin
bin: ## Installs the bin directory files.
	# add aliases for things in bin
	for file in $(shell find $(CURDIR)/bin -type f -not -name "*-backlight" -not -name ".*.swp"); do \
		f=$$(basename $$file); \
		sudo ln -sf $$file /usr/local/bin/$$f; \
	done

.PHONY: dotfiles
dotfiles: ## Installs the dotfiles.
	# add aliases for dotfiles
	for file in $(shell find $(CURDIR) -name ".*" -not -name ".gitignore" -not -name ".travis.yml" -not -name ".git" -not -name ".*.swp" -not -name ".gnupg"); do \
		f=$$(basename $$file); \
		ln -sfn $$file $(HOME)/$$f; \
	done; \
	#gpg --list-keys || true;
	#ln -sfn $(CURDIR)/.gnupg/gpg.conf $(HOME)/.gnupg/gpg.conf;
	#ln -sfn $(CURDIR)/.gnupg/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf;
	ln -sfn $CURDIR)/.oh-my-zsh/themes/domokost.zsh-theme $(HOME)/.oh-my-zsh/themes/domokost.zsh-theme
	ln -fn $(CURDIR)/gitignore $(HOME)/.gitignore;
	git update-index --skip-worktree $(CURDIR)/.gitconfig;
	#ln -snf $(CURDIR)/.i3 $(HOME)/.config/sway;
	ln -snf $(CURDIR)/.fonts $(HOME)/.local/share/fonts;

