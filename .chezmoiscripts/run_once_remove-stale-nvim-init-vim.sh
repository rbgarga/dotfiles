#!/bin/sh
# Remove the legacy symlink to the old dotfiles/init.vim, if present.
# Neovim uses ~/.config/nvim/init.lua (LazyVim) now.
if [ -L "$HOME/.config/nvim/init.vim" ]; then
    target=$(readlink "$HOME/.config/nvim/init.vim")
    case "$target" in
        *dotfiles/init.vim) rm -f "$HOME/.config/nvim/init.vim" ;;
    esac
fi
