#!/bin/sh

if [ -z "$HOME" ]; then
	echo "\$HOME is not set"
	exit 1
fi

if [ ! -d "$HOME" ]; then
	echo "\$HOME directory doesn't exist"
	exit 1
fi

required_binaries="git node nvim tmux"

for binary in $required_binaries; do
	if ! which $binary >/dev/null 2>&1; then
		echo "${binary} not found"
		exit 1
	fi
done

mydir=$(realpath $(dirname $0 ))
os=$(uname -s)

conf_files="gitconfig gitconfig-work gitconfig-personal git_template tmux.conf"

if [ -d "${HOME}/bin" ]; then
	echo "${HOME}/bin is a directory, skipping... "
else
	ln -sf $mydir/bin $HOME/
fi

if [ "$os" = "FreeBSD" ]; then
	mkdir -p $HOME/.config/i3status $HOME/.config/sway
	ln -sf $mydir/wallpaper.jpg $HOME/.wallpaper.jpg
	ln -sf $mydir/i3status-config $HOME/.config/i3status/config
	ln -sf $mydir/sway-config $HOME/.config/sway/config

	# .login_conf is better being a hardlink
	ln -f $mydir/login_conf $HOME/.login_conf

	sudo mkdir -p /usr/local/etc/polkit-1/rules.d
	sudo cp -f 60-garga.rules /usr/local/etc/polkit-1/rules.d

	conf_files="${conf_files} XCompose"
fi

for conf_file in $conf_files; do
	ln -sf $mydir/$conf_file $HOME/.$conf_file
done

if [ -d "${HOME}/.zprezto" ]; then
	echo "${HOME}/.zprezto is a directory, skipping... "
else
	if ! git clone --recursive git@github.com:rbgarga/prezto.git \
	    ${HOME}/.zprezto; then
		echo "Error cloning prezto"
		exit 1
	fi

	git -C $HOME/.zprezto remote add upstream \
	    git@github.com:sorin-ionescu/prezto.git

	for f in zlogin zlogout zpreztorc zprofile zshenv zshrc; do
		ln -sf $HOME/.zprezto/runcoms/$f $HOME/.$f
	done
fi

${mydir}/vim-install.sh
