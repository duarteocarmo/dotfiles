# pi-executor-skills

Loads skills from an [Executor](https://executor.sh) app when Pi starts, so every machine gets the same private set.

- On startup it calls the app's `bundle` tool through the Executor MCP server configured in `mcp.json`. It uses the token from `pi mcp login`, and never refreshes that token itself.
- It caches the skills in `~/.pi/agent/executor-skills/` and registers them.
- If Executor is unreachable or the token has expired, it uses the cache.
- `/executor-skills` syncs on demand and reloads Pi if anything changed.

Environment overrides: `PI_EXECUTOR_SKILLS_SERVER` (default `executor`) and `PI_EXECUTOR_SKILLS_APP` (default `duarte-s-skills`).

The Executor app must expose a `bundle` query that returns `{ hash, unchanged, parts, chunk }`, where the joined chunks are a JSON `{ skills: [{ name, files }] }`. See `index.ts`.
