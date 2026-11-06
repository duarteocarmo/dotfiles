# Rex input state

Reports Pi custom blocking UI as a separate Rex OSC 7501 record (`id=pi-input`, `kind=question`). It listens to Pi's coalesced `ui_prompt_start` / `ui_prompt_end` events and only emits for custom prompts in a TTY UI. This covers questionnaire-style custom screens without changing Pi's root working/done state.

The record clears on prompt end or session shutdown. No timers, tool-name assumptions, or changes to installed packages are needed. The handler intentionally ignores select/confirm/input/editor prompts; Pi's native terminal reporting remains responsible for those. Because Pi coalesces nested/overlapping prompts, one own active flag is sufficient.

Run `/reload` in existing Pi sessions after syncing this extension. New sessions discover it automatically.

## Smoke test

Launch a fresh Pi instance in a disposable new Rex pane with the extension enabled, for example:

```sh
pi --no-session --no-extensions \
  -e "$HOME/.pi/agent/extensions/rex-input-state/index.ts" \
  -e "$HOME/.pi/agent/extensions/rex-input-state/tests/smoke.ts"
```

Run `/rex-input-smoke`. Rex `program_status` should show a `pi-input` record with `state=blocked` and `kind=question`; press Enter to finish or Escape to cancel, then confirm the `pi-input` record is cleared. This extension only emits the custom Pi input record; it does not control or inspect Rex sessions.
