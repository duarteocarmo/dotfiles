---
name: executor-skills
description: Add, edit, or remove one of Duarte's skills. Skills live in the "Duarte's Skills" Executor app and sync to pi through the executor-skills extension.
---

# Change a skill

App: slug `duarte-s-skills`, id `app_8d3624e2-a8f7-4f83-8925-26420bc192a9`. Its source is `index.ts`, `package.json` and `skills/<name>/SKILL.md` (plus any files the skill bundles).

1. Inside Executor's `execute`, call `tools.executor.appManagement.source({ path: { app } })` and return only `revision.commit`, `index.ts` and `package.json`. The full source is too large for one result.
2. Copy the skill files from `~/.pi/agent/executor-skills/skills/`. This cache matches the deployed app after a sync.
3. Make the change in a temp folder. The frontmatter `name` must match the folder name.
4. Commit with `mcp__executor__call`, path `tools.executor.appManagement.commit`, input `{ path: { app }, body: { expected: <commit>, files, message } }`. Send every file: omitted files are deleted. Pass the files as call input, not inside `execute` code, which is limited to 64 KB.
5. Deploy with `tools.executor.appManagement.deploy`, input `{ path: { app }, body: { commit } }`.
6. Verify with `mcp__executor__skills({ app: "duarte-s-skills" })`.

pi picks up the change on the next start, `/executor-skills`, or `/reload`.
