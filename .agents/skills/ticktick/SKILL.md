---
name: ticktick
description: "Manage TickTick tasks, projects, habits, focus, and tags from the terminal with the `ticktick` CLI. Use when the user asks to create, complete, update, or search tasks, list projects, or manage habits/focus."
---

# TickTick CLI

Use the `ticktick` CLI (installed globally via npm) to interact with TickTick. It wraps the TickTick Open API.

- Package: https://www.npmjs.com/package/@ticktick/ticktick-cli
- Full CLI docs: `ticktick --help` and `ticktick <command> --help`
- Upstream repo: https://github.com/TickTeam/ticktick-cli

## Auth

Already signed in (`ticktick auth status`). If re-auth is needed:

```bash
ticktick auth login          # OAuth PKCE browser login (recommended)
ticktick auth token <token>  # token for headless environments
ticktick auth status
```

## Common commands

```bash
ticktick project list                                # list all projects
ticktick project get <projectId>                     # project details
ticktick task get <projectId> <taskId>               # fetch a task
ticktick task create --title "Buy milk" --project <projectId>
ticktick task create --title "Meeting" --project <projectId> --priority 5 --due-date "2026-03-10T09:00:00+0000" --tags work
ticktick task complete <projectId> <taskId>          # complete a task
ticktick task update <taskId> --id <taskId> --project <projectId> --title "Updated"
ticktick task delete <projectId> <taskId>
ticktick task search "query" --projects <projectId>
ticktick task completed --projects <projectId> --start-date ... --end-date ...
ticktick habit list
ticktick focus list --from ... --to ... --type 0
```

Add `--json` to any command for raw API output (e.g. `ticktick project list --json`).

## Fast today view

When asked for today's tasks, run:

```bash
~/.agents/skills/ticktick/today-table.mjs
```

Return its Markdown table directly. Always use the columns `Item`, `List`, and `Tags` for task lists unless the user requests another format. Timed tasks include the local time in `Item`.

The script fetches the project list and both required date windows in parallel, converts every due date to `Europe/Copenhagen`, removes duplicates, and prints only today's open tasks. Set `TICKTICK_TIME_ZONE` to override the timezone.

## WARNING: all-day task dates are off by one

TickTick stores all-day tasks at **local midnight converted to UTC**. In a UTC+2 timezone (Duarte is in Denmark, CEST in summer), an all-day task dated local day `D` comes back with `dueDate`/`startDate` = `(D-1)T22:00:00.000+0000`. Timed tasks keep their local UTC timestamp (e.g. 09:00 local = `T07:00:00.000+0000`).

Consequences:

- `task filter --start-date YYYY-MM-DD --end-date YYYY-MM-DD` passes the window to the API as **UTC** days. A UTC day `D` therefore returns that day's *timed* tasks but the *next local day's* all-day tasks. Querying "today" can silently return mostly tomorrow's all-day tasks.
- All-day tasks from multiple days look identical (all `isAllDay: true`, often `22:00:00+0000`) - do not bucket them by their UTC date.

Correct approach to list "tasks for local date D" (Duarte's tz = Europe/Copenhagen, +2):

1. Query at least two windows, e.g. `--start-date D-1 --end-date D` **and** `--start-date D --end-date D+1` (use `--json`).
2. Bucket every task by its **local** date: convert `dueDate` (UTC) with `.astimezone()`; an all-day task at `(D-1)T22:00:00+0000` belongs to local date `D`, and its intended date is the day the converted instant falls on (midnight). Timed tasks sort onto their own local day.
3. Only report tasks whose local date equals the day asked about. Expect daily-recurring tasks (e.g. Sonhos, "Brush Allegra's teeth…", Vitamin D) to appear every day.

When in doubt, print each task's `dueDate` + `timeZone` + `isAllDay` and verify against the user before answering.

