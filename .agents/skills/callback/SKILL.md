---
name: callback
description: Send a macOS desktop notification to call the user back after a long-running command finishes. Use when the user asks to be notified, e.g. "notify me when done", "call me back", "ping me when it's finished".
---

# Callback

Send a native macOS notification after a long-running command completes. Only use when the user explicitly asks to be notified.

## Usage

After the long-running command finishes, use `say` to speak a short summary of what happened:

```bash
say "<message>"
```

The `<message>` should be a brief, human-readable summary of what completed, e.g.:
- "Docker build done"
- "Tests failed, 3 errors in auth module"
- "Deploy to staging complete"
- "Sleep timer done"

## When to Use

- User says "notify me", "call me back", "ping me when done", "let me know when it's finished", etc.
- Do NOT notify on every command — only when explicitly requested
- Run the notification immediately after the command completes, before responding in chat
