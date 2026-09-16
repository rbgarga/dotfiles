#!/bin/sh

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
trap "rm -f ${git_dir}/tags.$$" HUP INT TERM ERR EXIT
$ctags --tag-relative -Rf ${git_dir}/tags.$$ --exclude=.git $params >/dev/null 2>&1
mv ${git_dir}/tags.$$ ${git_dir}/tags
