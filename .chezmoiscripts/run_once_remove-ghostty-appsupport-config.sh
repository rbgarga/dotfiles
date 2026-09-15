#!/bin/sh
# Ghostty on macOS loads BOTH the XDG config (~/.config/ghostty/config,
# managed by chezmoi) and the App Support file. Move the latter aside so
# only the chezmoi-managed one applies.
dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
if [ -f "$dir/config" ]; then
    mv "$dir/config" "$dir/config.pre-chezmoi"
fi
