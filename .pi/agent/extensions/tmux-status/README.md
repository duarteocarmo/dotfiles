# Pi and tmux status

The extension shows whether each Pi session is working or done. The status appears in tmux and in the macOS menu bar. Selecting a session in the menu opens its tmux pane in Ghostty.

## Requirements

You need macOS, Pi, and tmux. You also need [SwiftBar](https://swiftbar.app/) for the menu bar item and Ghostty for the current jump script. If Pi, tmux, and Ghostty are already installed, SwiftBar is the only extra application to install.

You can install SwiftBar with Homebrew:

```sh
brew install --cask swiftbar
```

## Setup

First, place the extension and scripts from this repository at the following paths. Create the parent folders if they don't exist.

```text
~/.pi/agent/extensions/tmux-status/index.ts
~/.local/bin/pi-tmux-jump
~/Library/Application Support/SwiftBar/Plugins/pi-status.2s.sh
```

Copy the four Pi status settings from the `# Themes` section of this repository's `.tmux.conf` into your own `~/.tmux.conf`. Then make the two scripts executable:

```sh
chmod +x ~/.local/bin/pi-tmux-jump
chmod +x ~/Library/Application\ Support/SwiftBar/Plugins/pi-status.2s.sh
```

The scripts use paths for an Apple silicon Mac and this repository's owner. Change `TMUX_BIN`, `JUMP`, and `GHOSTTY` in the scripts if tmux, the jump script, or Ghostty are elsewhere on your computer.

Open SwiftBar and select `~/Library/Application Support/SwiftBar/Plugins` as its plugin folder. Reload the tmux configuration with `tmux source-file ~/.tmux.conf`, and restart Pi or run `/reload` in Pi.

## Files

`index.ts` sets the current tmux pane status when Pi starts or finishes work. `.tmux.conf` shows the Pi name and status in tmux. `pi-status.2s.sh` lists every Pi status in SwiftBar. `pi-tmux-jump` focuses Ghostty and selects the chosen tmux pane.
