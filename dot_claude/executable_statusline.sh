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

# Dropped first on narrow terminals.
if [ "$cols" -ge 100 ]; then
	if [ "$added" != "-" ] || [ "$removed" != "-" ]; then
		add "${green}+${added}${reset} ${red}-${removed}${reset}"
	fi
fi

[ -n "$line" ] && printf '%s\n' "$line"
exit 0
