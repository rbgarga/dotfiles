#!/bin/sh
# List URLs across all panes of the window the popup was opened on, and
# copy the picked one to the local clipboard via OSC 52. Formats are not
# expanded in display-popup -E commands, so the window is resolved from
# inside the popup rather than passed by the binding.

win=$(tmux display-message -p '#{window_id}' 2>/dev/null)
panes=$(tmux list-panes -t "$win" -F '#{pane_id}' 2>/dev/null)
[ -n "$panes" ] || panes=$(tmux list-panes -F '#{pane_id}' 2>/dev/null)

urls=$(for p in $panes; do tmux capture-pane -p -J -S - -t "$p" 2>/dev/null; done | grep -oE '(https?|ftp)://[^[:space:]"<>)]+' | sort -u)
[ -n "$urls" ] || { tmux display-message "No URLs found"; exit 0; }

url=$(printf '%s\n' "$urls" | fzf --prompt 'URL> ')
[ -n "$url" ] || exit 0
url=$(printf '%s' "$url" | sed -E "s/[.,;:'\"()]+$//")
printf '%s' "$url" | tmux load-buffer -w -
tmux display-message "URL copied to mac clipboard: $url"
