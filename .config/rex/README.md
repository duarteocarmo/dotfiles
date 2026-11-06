# Rex session names

Install Rex and start its server, then run this on each machine after syncing the dotfiles:

```sh
sh ~/.config/rex/install-session-names.sh
```

The installer enables a launchd agent on macOS or a systemd user service on Linux. Run it again after updating the files to restart the watcher. Each watcher connects only to the local Rex server and retries if the server is unavailable. It does not start the Rex server.

New sessions follow the directory of the first pane in their first tab. The watcher uses the shell's reported directory when available and otherwise reads the terminal's main process working directory. It listens for directory reports and process changes, so shells do not need OSC 7 integration. The label uses the Git repository name when inside a repository, the directory name elsewhere, and `~` at home. The dotfiles repository at home is not treated as the parent repository of every directory.

Rename a session yourself to stop automatic updates, including after a watcher restart. Existing sessions without saved naming state are left alone. Rex does not identify custom labels supplied when creating a session, so those initial labels are also replaced. Rename after creation to keep a custom label.

The implementation is in [scripts/session-names.lua](scripts/session-names.lua). Naming state lives under `${XDG_STATE_HOME:-~/.local/state}/rex`, outside Git. The installer copies the service templates from [services](services) and fills in macOS paths for the current user. Generated service files stay outside Git.

## Check the service

On macOS:

```sh
launchctl print gui/$(id -u)/com.duarteocarmo.rex-session-names
tail -n 20 ~/.local/state/rex/session-names.log
```

The agent starts when the user logs in. On Linux:

```sh
systemctl --user status rex-session-names.service
journalctl _SYSTEMD_USER_UNIT=rex-session-names.service "_UID=$(id -u)" -n 20
```

Enable lingering with `sudo loginctl enable-linger "$(id -un)"` if the Linux service must run before login and after logout.

## Test

With a local Rex server running and the naming service stopped:

```sh
uv run ~/.config/rex/tests/session-names.py
```

The test starts an isolated watcher and creates temporary sessions and a real Git repository. It checks directory changes with and without terminal directory reports, repository names, the first tab, manual names, restarts, and state cleanup. It does not change existing sessions.
