#!/bin/sh

# shellcheck disable=SC2209
if [ -f /usr/local/bin/exctags ]; then
	ctags=exctags
else
	ctags=ctags
fi

# pfSense
if [ -f ./build.sh ]; then
	params="--languages=PHP,JavaScript --langmap=PHP:.php.inc"
else
	params=""
fi

set -e
PATH="/opt/local/bin:$PATH"
git_dir=$(git rev-parse --git-dir)
tmp="${git_dir}/tags.$$"
# EXIT also fires on set -e failures, so no (non-POSIX) ERR trap is needed
trap 'rm -f "$tmp"' EXIT
trap 'exit 1' HUP INT TERM
# $params is intentionally unquoted: it holds several ctags options
# shellcheck disable=SC2086
$ctags --tag-relative -Rf "$tmp" --exclude=.git $params >/dev/null 2>&1
mv "$tmp" "${git_dir}/tags"
