#!/bin/sh
# Remove stale copies of scripts migrated from ~/bin to ~/.local/bin
# (chezmoi does not delete targets removed from the source state).
# Only files whose name also exists in ~/.local/bin are removed, so
# personal scripts left in ~/bin are never touched.

for f in "$HOME"/.local/bin/*; do
    [ -e "$f" ] || continue
    b=$(basename "$f")
    [ -f "$HOME/bin/$b" ] && rm -f "$HOME/bin/$b"
done
rmdir "$HOME/bin" 2>/dev/null || true
exit 0
