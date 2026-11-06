#!/bin/sh
set -eu

config_dir="$HOME/.config/rex"

case "$(uname -s)" in
	Darwin)
		label=com.duarteocarmo.rex-session-names
		domain="gui/$(id -u)"
		state_dir="$HOME/.local/state/rex"
		destination="$HOME/Library/LaunchAgents/$label.plist"
		mkdir -p "$(dirname "$destination")" "$state_dir"
		temporary=$(mktemp)
		trap 'rm -f "$temporary"' EXIT HUP INT TERM
		cp "$config_dir/services/session-names.plist" "$temporary"
		plutil -insert ProgramArguments.1 -string "$config_dir/scripts/session-names.sh" "$temporary"
		plutil -replace StandardOutPath -string "$state_dir/session-names.log" "$temporary"
		plutil -replace StandardErrorPath -string "$state_dir/session-names.log" "$temporary"
		plutil -lint "$temporary"
		launchctl bootout "$domain/$label" 2>/dev/null || true
		install -m 644 "$temporary" "$destination"
		launchctl enable "$domain/$label"
		launchctl bootstrap "$domain" "$destination"
		printf 'Installed and started %s.\n' "$label"
		;;
	Linux)
		destination="$HOME/.config/systemd/user/rex-session-names.service"
		mkdir -p "$(dirname "$destination")"
		install -m 644 "$config_dir/services/session-names.service" "$destination"
		systemctl --user daemon-reload
		systemctl --user enable rex-session-names.service
		systemctl --user restart rex-session-names.service
		systemctl --user is-active rex-session-names.service
		printf 'Installed and started rex-session-names.service.\n'
		if [ "$(loginctl show-user "$(id -u)" -p Linger --value)" != yes ]; then
			printf 'Enable startup without login: sudo loginctl enable-linger %s\n' "$(id -un)"
		fi
		;;
	*)
		printf 'Unsupported operating system.\n' >&2
		exit 1
		;;
esac
