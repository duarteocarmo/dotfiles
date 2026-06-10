---
name: mac-notify
description: Send a macOS notification when the user asks to be notified, alerted, pinged, or reminded that something is done.
---

# mac-notify

Use NotifiCLI for macOS notifications.

```bash
notificli -icon 'Terminal' -title 'Pi' -message 'Your message here'
```

Keep the Terminal icon by default. Customize `-title` and `-message` to match the user's request.

If `notificli` is missing:

```bash
brew tap saihgupr/notificli && brew install --cask notificli
```
