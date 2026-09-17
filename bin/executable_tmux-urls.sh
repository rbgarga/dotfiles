#!/bin/sh
# List URLs in the current pane (full scrollback, wrapped lines joined)
# and copy the picked one to the local clipboard via OSC 52.

pane=${1:-}
url=$(tmux capture-pane -p -J -S - ${pane:+-t "$pane"} \
      | grep -oE '(https?|ftp)://[^[:space:]"<>)]+' \
      | sort -u | fzf --prompt 'URL> ')
[ -n "$url" ] || exit 0
url=$(printf '%s' "$url" | sed -E "s/[.,;:'\"()]+$//")
printf '%s' "$url" | tmux load-buffer -w -
tmux display-message "URL copied to mac clipboard: $url"
