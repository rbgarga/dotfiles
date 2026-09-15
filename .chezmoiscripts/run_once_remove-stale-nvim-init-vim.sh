#!/bin/sh
# Remove the legacy symlink to the old myconf/init.vim, if present.
# Neovim uses ~/.config/nvim/init.lua (LazyVim) now.
if [ -L "$HOME/.config/nvim/init.vim" ]; then
    target=$(readlink "$HOME/.config/nvim/init.vim")
    case "$target" in
        *myconf/init.vim) rm -f "$HOME/.config/nvim/init.vim" ;;
    esac
fi
