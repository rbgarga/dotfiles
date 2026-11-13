#!/bin/sh
# Claude Code status line: reads the session JSON on stdin and prints one
# line: model, effort, directory, git branch, MR/PR, context usage, rate
# limits and lines changed.
# Colors follow ~/.claude/themes/gruvbox.json.

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
	printf '%s\n' "${PWD##*/}"
	exit 0
fi

esc=$(printf '\033')
c() { printf '%s[38;2;%sm' "$esc" "$1"; }
reset="${esc}[0m"
orange=$(c '254;128;25')
yellow=$(c '250;189;47')
green=$(c '184;187;38')
red=$(c '251;73;52')
blue=$(c '131;165;152')
aqua=$(c '142;192;124')
gray=$(c '146;131;116')

# One jq call; fields are tab separated, "-" stands for absent/null.
# Fields never contain tabs, but read would collapse empty ones, hence "-".
fields=$(printf '%s' "$input" | jq -r '
	def v: if . == null or . == "" then "-" else tostring end;
	[
		(.model.display_name | v),
		(.effort.level | v),
		(.fast_mode // false | tostring),
		(.workspace.current_dir // .cwd | v),
		(.workspace.git_worktree | v),
		(.pr.number | v),
		(.pr.review_state | v),
		(.context_window.used_percentage | if . == null then "-" else floor | tostring end),
		(.rate_limits.five_hour.used_percentage | if . == null then "-" else floor | tostring end),
		(.rate_limits.five_hour.resets_at | v),
		(.rate_limits.seven_day.used_percentage | if . == null then "-" else floor | tostring end),
		(.cost.total_lines_added | v),
		(.cost.total_lines_removed | v)
	] | join("\t")')

IFS='	' read -r model effort fast dir worktree pr_num pr_state ctx h5 h5_reset d7 \
	added removed <<EOF
$fields
EOF

# The session JSON only carries rate_limits once this session got its
# first API response (they come from response headers), and never the
# per-model weekly windows (e.g. Fable). Both come from the claude.ai
# usage endpoint behind /usage, fetched in the background and cached
# for all sessions, so the status line never waits for it.
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline
usage_cache=$cache_dir/usage.json
usage_stamp=$cache_dir/usage.stamp
usage_ttl_min=2

oauth_token() {
	if [ "$(uname)" = Darwin ]; then
		security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null
	else
		cat "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json" 2>/dev/null
	fi | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null
}

refresh_usage() {
	mkdir -p "$cache_dir" 2>/dev/null || return
	[ -n "$(find "$usage_stamp" -mmin -"$usage_ttl_min" 2>/dev/null)" ] && return
	# A lock left behind by a killed refresh must not block the next ones.
	find "$cache_dir" -maxdepth 1 -name lock -mmin +1 -exec rmdir {} + 2>/dev/null
	mkdir "$cache_dir/lock" 2>/dev/null || return
	touch "$usage_stamp"
	(
		trap 'rmdir "$cache_dir/lock"' EXIT
		token=$(oauth_token)
		[ -n "$token" ] || exit 0
		tmp=$usage_cache.$$
		if curl -sf -m 10 -H "Authorization: Bearer $token" \
		    -H 'anthropic-beta: oauth-2025-04-20' \
		    https://api.anthropic.com/api/oauth/usage -o "$tmp" &&
		    jq -e 'type == "object"' "$tmp" >/dev/null 2>&1; then
			mv -f "$tmp" "$usage_cache"
		else
			rm -f "$tmp"
		fi
	) </dev/null >/dev/null 2>&1 &
}

refresh_usage

# Windows whose reset already passed are stale and dropped.
scoped="-"
if [ -s "$usage_cache" ]; then
	usage=$(jq -r '
		def epoch: if type == "string" then
			sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601
			else . end;
		def live: select(. != null and .resets_at != null
			and (.resets_at | epoch) > now);
		def pct: if . == null then "-" else floor | tostring end;
		[
			(.five_hour | live | .utilization | pct) // "-",
			(.five_hour | live | .resets_at | epoch | tostring) // "-",
			(.seven_day | live | .utilization | pct) // "-",
			([.limits[]? | select(.kind == "weekly_scoped") | live
				| "\(.scope.model.display_name | ascii_downcase)=\(.percent | pct)"]
				| if length == 0 then "-" else join(";") end)
		] | join("\t")' "$usage_cache" 2>/dev/null)
	IFS='	' read -r u_h5 u_h5_reset u_d7 scoped <<EOF
$usage
EOF
	if [ "$h5" = "-" ] && [ -n "$u_h5" ]; then
		h5=$u_h5
		h5_reset=$u_h5_reset
	fi
	[ "$d7" = "-" ] && [ -n "$u_d7" ] && d7=$u_d7
	[ -z "$scoped" ] && scoped="-"
fi

sep="  "
cols=${COLUMNS:-80}

line=""
add() { line="${line:+$line$sep}$1"; }

m="${orange}${model}${reset}"
[ "$effort" != "-" ] && m="$m${gray} · ${reset}${yellow}${effort}${reset}"
[ "$fast" = "true" ] && m="$m ${yellow}⚡${reset}"
[ "$model" != "-" ] && add "$m"

if [ "$dir" != "-" ]; then
	short=$dir
	case $dir in "$HOME"*) short="~${dir#"$HOME"}" ;; esac
	add "${blue}${short}${reset}"

	if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
		branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
		[ -z "$branch" ] && branch=$(git -C "$dir" --no-optional-locks \
			rev-parse --short HEAD 2>/dev/null)
		g="${green}${branch}${reset}"
		if [ -n "$(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null | head -n 1)" ]; then
			g="$g${yellow}*${reset}"
		fi
		counts=$(git -C "$dir" --no-optional-locks \
			rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)
		if [ -n "$counts" ]; then
			behind=${counts%%[!0-9]*}
			ahead=${counts##*[!0-9]}
			[ "${ahead:-0}" -gt 0 ] && g="$g ${aqua}↑${ahead}${reset}"
			[ "${behind:-0}" -gt 0 ] && g="$g ${red}↓${behind}${reset}"
		fi
		[ "$worktree" != "-" ] && g="$g ${gray}(wt:${worktree})${reset}"
		add "$g"
	fi
fi

if [ "$pr_num" != "-" ]; then
	p="${blue}!${pr_num}${reset}"
	[ "$pr_state" != "-" ] && p="$p ${gray}${pr_state}${reset}"
	add "$p"
fi

if [ "$ctx" != "-" ]; then
	if [ "$ctx" -ge 85 ]; then
		col=$red
	elif [ "$ctx" -ge 60 ]; then
		col=$yellow
	else
		col=$green
	fi
	filled=$((ctx / 10))
	bar=""
	i=0
	while [ "$i" -lt 10 ]; do
		if [ "$i" -lt "$filled" ]; then bar="${bar}█"; else bar="${bar}░"; fi
		i=$((i + 1))
	done
	add "${gray}ctx${reset} ${col}${bar} ${ctx}%${reset}"
fi

if [ "$h5" != "-" ]; then
	r="${gray}5h${reset} ${h5}%"
	if [ "$h5_reset" != "-" ]; then
		t=$(date -r "$h5_reset" +%H:%M 2>/dev/null || date -d "@$h5_reset" +%H:%M 2>/dev/null)
		[ -n "$t" ] && r="$r${gray} → ${t}${reset}"
	fi
	add "$r"
fi
[ "$d7" != "-" ] && add "${gray}7d${reset} ${d7}%"

if [ "$scoped" != "-" ]; then
	old_ifs=$IFS
	IFS=';'
	for s in $scoped; do
		[ "${s#*=}" != "-" ] && add "${gray}${s%%=*}${reset} ${s#*=}%"
	done
	IFS=$old_ifs
fi

# Dropped first on narrow terminals.
if [ "$cols" -ge 100 ]; then
	if [ "$added" != "-" ] || [ "$removed" != "-" ]; then
		add "${green}+${added}${reset} ${red}-${removed}${reset}"
	fi
fi

[ -n "$line" ] && printf '%s\n' "$line"
exit 0
