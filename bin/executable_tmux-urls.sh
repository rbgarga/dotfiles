#!/bin/sh
# List URLs across all panes in the current window (full scrollback,
# wrapped lines joined) and copy the picked one to the local clipboard
# via OSC 52.

win=${1:-}
[ -n "$win" ] || win=$(tmux display-message -p '#{window_id}')

urls=$(for pane in $(tmux list-panes -t "$win" -F '#{pane_id}'); do
    tmux capture-pane -p -J -S - -t "$pane" 2>/dev/null
done | grep -oE '(https?|ftp)://[^[:space:]"<>)]+' | sort -u)
[ -n "$urls" ] || { tmux display-message "No URLs found"; exit 0; }

url=$(printf '%s\n' "$urls" | fzf --prompt 'URL> ')
[ -n "$url" ] || exit 0
url=$(printf '%s' "$url" | sed -E "s/[.,;:'\"()]+$//")
printf '%s' "$url" | tmux load-buffer -w -
tmux display-message "URL copied to mac clipboard: $url"
