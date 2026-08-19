#!/bin/bash

# <xbar.title>Pi tmux status</xbar.title>
# <xbar.version>1.0.0</xbar.version>
# <xbar.author>Duarte O.Carmo</xbar.author>
# <xbar.desc>Shows Pi agent status across tmux and jumps to a selected pane.</xbar.desc>
# <xbar.dependencies>tmux</xbar.dependencies>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>

set -u

TMUX_BIN=/opt/homebrew/bin/tmux
JUMP=/Users/duarteocarmo/.local/bin/pi-tmux-jump

pane_ids=()
labels=()
locations=()
statuses=()
working_count=0
done_count=0

while IFS='|' read -r pane session window pane_index title status; do
	case "$status" in
		working) working_count=$((working_count + 1)) ;;
		done) done_count=$((done_count + 1)) ;;
		*) continue ;;
	esac

	label=${title#* - }
	if [[ -z $label || $label == "$title" ]]; then
		label="$session:$window.$pane_index"
	fi

	pane_ids+=("$pane")
	labels+=("${label//|/¦}")
	locations+=("$session:$window.$pane_index")
	statuses+=("$status")
done < <($TMUX_BIN list-panes -a -F '#{pane_id}|#{session_name}|#{window_index}|#{pane_index}|#{pane_title}|#{@pi_status}' 2>/dev/null)

printf 'π'
if (( working_count > 0 )); then
	printf ' ●%d' "$working_count"
fi
if (( done_count > 0 )); then
	printf ' ✓%d' "$done_count"
fi
printf '\n---\n'

if (( ${#pane_ids[@]} == 0 )); then
	printf 'No Pi sessions\n'
	exit 0
fi

for wanted_status in working done; do
	for index in "${!pane_ids[@]}"; do
		[[ ${statuses[$index]} == "$wanted_status" ]] || continue
		if [[ $wanted_status == working ]]; then
			symbol=●
		else
			symbol=✓
		fi
		printf '%s %s — %s | bash=%s terminal=false refresh=true param0=%s\n' \
			"$symbol" "${labels[$index]}" "${locations[$index]}" "$JUMP" "${pane_ids[$index]}"
	done
done
