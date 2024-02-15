all:
	stow --verbose --target=$$HOME --restow dotfiles

delete:
	stow --verbose --target=$$HOME --delete dotfiles
