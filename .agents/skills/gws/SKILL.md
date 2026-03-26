---
name: gws
description: "Google Workspace CLI (gws): Manage Gmail, Drive, Calendar, Sheets, Docs, Chat, Tasks, and more. Use when the user wants to interact with any Google Workspace service."
---

# gws — Google Workspace CLI

One CLI for all of Google Workspace. Dynamic command surface built from Google's Discovery Service — when Google adds an API endpoint, `gws` picks it up automatically. All output is structured JSON.

**Repo:** https://github.com/googleworkspace/cli

## Install

```bash
npm install -g @googleworkspace/cli
```

Or via Homebrew: `brew install googleworkspace-cli`

## Authentication

```bash
gws auth setup       # one-time: creates Cloud project, enables APIs, logs you in (requires gcloud)
gws auth login       # subsequent logins — pick scopes with -s drive,gmail,sheets
```

For headless/CI, export credentials:
```bash
gws auth export --unmasked > credentials.json
export GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=/path/to/credentials.json
```

Pre-obtained token: `export GOOGLE_WORKSPACE_CLI_TOKEN=$(gcloud auth print-access-token)`

## CLI Syntax

```bash
gws <service> <resource> [sub-resource] <method> [flags]
```

### Global Flags

| Flag | Description |
|------|-------------|
| `--params '{"key": "val"}'` | URL/query parameters |
| `--json '{"key": "val"}'` | Request body |
| `--dry-run` | Preview request without calling the API |
| `--upload <PATH>` | Upload file (multipart) |
| `-o, --output <PATH>` | Save binary response to file |
| `--page-all` | Auto-paginate (NDJSON output) |
| `--page-limit <N>` | Max pages (default: 10) |

### Discovering Commands

```bash
gws <service> --help                          # browse resources and methods
gws schema <service>.<resource>.<method>      # inspect params, types, defaults
```

## Shell Tips

- **zsh `!` expansion:** Use double quotes for sheet ranges: `--range "Sheet1!A1:D10"`
- **JSON args:** Wrap `--params` and `--json` in single quotes to preserve inner double quotes

## Security Rules

- **Never** output secrets (API keys, tokens)
- **Confirm with user** before executing write/delete commands
- Prefer `--dry-run` for destructive operations

## Helper Commands (+ prefix)

Shortcut commands for common operations. Run `gws <service> --help` to see all.

### Gmail

```bash
gws gmail +send --to alice@example.com --subject "Hello" --body "Hi there"
gws gmail +send --to alice@example.com --subject "Report" --body "See attached" -a report.pdf
gws gmail +send --to a@ex.com --subject "Bold" --body "<b>Hi</b>" --html
gws gmail +reply --message-id MSG_ID --body "Thanks!"
gws gmail +reply-all --message-id MSG_ID --body "Noted"
gws gmail +forward --message-id MSG_ID --to bob@example.com
gws gmail +triage                              # unread inbox summary
gws gmail +read --message-id MSG_ID            # read message body/headers
gws gmail +watch                               # stream new emails as NDJSON
```

### Drive

```bash
gws drive files list --params '{"pageSize": 10}'
gws drive +upload ./report.pdf --name "Q1 Report"
gws drive files create --json '{"name": "report.pdf"}' --upload ./report.pdf
gws drive files list --params '{"pageSize": 100}' --page-all | jq -r '.files[].name'
```

### Calendar

```bash
gws calendar +agenda                           # upcoming events (auto-detects timezone)
gws calendar +agenda --today --timezone America/New_York
gws calendar +insert --summary "Standup" --start "2025-01-15T09:00:00" --end "2025-01-15T09:30:00"
```

### Sheets

```bash
gws sheets +read --spreadsheet SPREADSHEET_ID --range "Sheet1!A1:D10"
gws sheets +append --spreadsheet SPREADSHEET_ID --values "Alice,95"
gws sheets spreadsheets create --json '{"properties": {"title": "Q1 Budget"}}'
gws sheets spreadsheets values get \
  --params '{"spreadsheetId": "ID", "range": "Sheet1!A1:C10"}'
gws sheets spreadsheets values append \
  --params '{"spreadsheetId": "ID", "range": "Sheet1!A1", "valueInputOption": "USER_ENTERED"}' \
  --json '{"values": [["Name", "Score"], ["Alice", 95]]}'
```

### Docs

```bash
gws docs +write --document DOC_ID --text "Appended text"
```

### Chat

```bash
gws chat +send --space SPACE_ID --text "Deploy complete."
```

### Tasks

```bash
gws tasks tasklists list --params '{}'
gws tasks tasks list --params '{"tasklist": "TASKLIST_ID"}'
```

### Workflows (cross-service)

```bash
gws workflow +standup-report       # today's meetings + open tasks
gws workflow +meeting-prep         # next meeting: agenda, attendees, linked docs
gws workflow +email-to-task        # convert Gmail message → Google Tasks entry
gws workflow +weekly-digest        # week summary: meetings + unread count
gws workflow +file-announce        # announce a Drive file in a Chat space
```

## All Available Services

`gws` supports: `drive`, `gmail`, `calendar`, `sheets`, `docs`, `slides`, `tasks`, `people`, `chat`, `classroom`, `forms`, `keep`, `meet`, `events`, `admin-reports`, `modelarmor`, `workflow`.

Run `gws <service> --help` for any service to discover its resources and methods.

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | API error (4xx/5xx) |
| `2` | Auth error |
| `3` | Validation error (bad args) |
| `4` | Discovery error |
| `5` | Internal error |

## Detailed Skills Index

When you need deeper info on a specific service, helper, recipe, or persona, fetch the upstream skill file:

```bash
curl -s https://raw.githubusercontent.com/googleworkspace/cli/main/skills/<skill-name>/SKILL.md
```

### Core Services

| Skill | Description |
|-------|-------------|
| `gws-shared` | Shared patterns: auth, global flags, output formatting |
| `gws-drive` | Google Drive: files, folders, shared drives |
| `gws-sheets` | Google Sheets: read and write spreadsheets |
| `gws-gmail` | Gmail: send, read, manage email |
| `gws-calendar` | Google Calendar: calendars and events |
| `gws-admin-reports` | Admin SDK: audit logs and usage reports |
| `gws-docs` | Google Docs: read and write documents |
| `gws-slides` | Google Slides: read and write presentations |
| `gws-tasks` | Google Tasks: task lists and tasks |
| `gws-people` | Google People: contacts and profiles |
| `gws-chat` | Google Chat: spaces and messages |
| `gws-classroom` | Google Classroom: classes, rosters, coursework |
| `gws-forms` | Google Forms: read and write forms |
| `gws-keep` | Google Keep: notes |
| `gws-meet` | Google Meet: conferences |
| `gws-events` | Workspace Events: subscriptions |
| `gws-modelarmor` | Model Armor: content safety filtering |
| `gws-workflow` | Cross-service productivity workflows |

### Helpers

| Skill | Description |
|-------|-------------|
| `gws-drive-upload` | Drive: upload a file with automatic metadata |
| `gws-sheets-append` | Sheets: append a row |
| `gws-sheets-read` | Sheets: read values |
| `gws-gmail-send` | Gmail: send an email |
| `gws-gmail-triage` | Gmail: unread inbox summary |
| `gws-gmail-reply` | Gmail: reply to a message |
| `gws-gmail-reply-all` | Gmail: reply-all |
| `gws-gmail-forward` | Gmail: forward a message |
| `gws-gmail-read` | Gmail: read message body/headers |
| `gws-gmail-watch` | Gmail: watch for new emails (NDJSON stream) |
| `gws-calendar-insert` | Calendar: create a new event |
| `gws-calendar-agenda` | Calendar: show upcoming events |
| `gws-docs-write` | Docs: append text |
| `gws-chat-send` | Chat: send a message |
| `gws-events-subscribe` | Events: subscribe and stream as NDJSON |
| `gws-events-renew` | Events: renew subscriptions |
| `gws-modelarmor-sanitize-prompt` | Model Armor: sanitize a user prompt |
| `gws-modelarmor-sanitize-response` | Model Armor: sanitize a model response |
| `gws-modelarmor-create-template` | Model Armor: create a template |
| `gws-workflow-standup-report` | Workflow: standup summary |
| `gws-workflow-meeting-prep` | Workflow: meeting preparation |
| `gws-workflow-email-to-task` | Workflow: email → task |
| `gws-workflow-weekly-digest` | Workflow: weekly summary |
| `gws-workflow-file-announce` | Workflow: announce Drive file in Chat |

### Recipes (multi-step sequences)

| Skill | Description |
|-------|-------------|
| `recipe-label-and-archive-emails` | Label + archive Gmail messages |
| `recipe-draft-email-from-doc` | Doc content → Gmail draft |
| `recipe-organize-drive-folder` | Create Drive folder structure and move files |
| `recipe-share-folder-with-team` | Share Drive folder with collaborators |
| `recipe-email-drive-link` | Share Drive file + email the link |
| `recipe-create-doc-from-template` | Copy Docs template, fill, share |
| `recipe-create-expense-tracker` | Sheets expense tracker setup |
| `recipe-copy-sheet-for-new-month` | Duplicate Sheets tab for new month |
| `recipe-block-focus-time` | Recurring Calendar focus time blocks |
| `recipe-reschedule-meeting` | Move Calendar event + notify attendees |
| `recipe-create-gmail-filter` | Create Gmail filter (label, star, categorize) |
| `recipe-schedule-recurring-event` | Recurring Calendar event with attendees |
| `recipe-find-free-time` | Calendar free/busy query for scheduling |
| `recipe-bulk-download-folder` | Download all files from Drive folder |
| `recipe-find-large-files` | Find large Drive files by quota |
| `recipe-create-shared-drive` | Create Shared Drive + add members |
| `recipe-log-deal-update` | Append deal update to Sheets tracker |
| `recipe-collect-form-responses` | Retrieve Google Form responses |
| `recipe-post-mortem-setup` | Doc + Calendar review + Chat notification |
| `recipe-create-task-list` | New Tasks list with initial tasks |
| `recipe-review-overdue-tasks` | Find past-due Tasks |
| `recipe-watch-drive-changes` | Subscribe to Drive change notifications |
| `recipe-create-classroom-course` | Classroom course + invite students |
| `recipe-create-meet-space` | Create Meet space + share join link |
| `recipe-review-meet-participants` | Review Meet attendance and duration |
| `recipe-create-presentation` | Slides presentation with initial slides |
| `recipe-save-email-attachments` | Gmail attachments → Drive folder |
| `recipe-send-team-announcement` | Announce via Gmail + Chat |
| `recipe-create-feedback-form` | Forms feedback form + share via Gmail |
| `recipe-sync-contacts-to-sheet` | Contacts → Sheets export |
| `recipe-share-event-materials` | Share Drive files with Calendar attendees |
| `recipe-create-vacation-responder` | Gmail out-of-office auto-reply |
| `recipe-create-events-from-sheet` | Sheets rows → Calendar events |
| `recipe-plan-weekly-schedule` | Review Calendar week, fill gaps |
| `recipe-share-doc-and-notify` | Share Doc + email collaborators |
| `recipe-backup-sheet-as-csv` | Export Sheets as local CSV |
| `recipe-save-email-to-doc` | Gmail message → Google Doc |
| `recipe-compare-sheet-tabs` | Compare two Sheets tabs for diffs |
| `recipe-batch-invite-to-event` | Add attendees to existing Calendar event |
| `recipe-forward-labeled-emails` | Forward labeled Gmail to another address |
| `recipe-generate-report-from-sheet` | Sheets data → formatted Docs report |

### Personas (role-based bundles)

| Skill | Description |
|-------|-------------|
| `persona-exec-assistant` | Executive schedule, inbox, communications |
| `persona-project-manager` | Tasks, meetings, doc sharing |
| `persona-hr-coordinator` | Onboarding, announcements, employee comms |
| `persona-sales-ops` | Deals, calls, client comms |
| `persona-it-admin` | Security monitoring, Workspace config |
| `persona-content-creator` | Create, organize, distribute content |
| `persona-customer-support` | Tickets, responses, escalations |
| `persona-event-coordinator` | Scheduling, invitations, logistics |
| `persona-team-lead` | Standups, task coordination, communication |
| `persona-researcher` | References, notes, collaboration |
