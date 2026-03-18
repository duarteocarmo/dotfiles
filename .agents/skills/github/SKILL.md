---
name: github
description: "Interact with GitHub using the `gh` CLI. Use `gh issue`, `gh pr`, `gh run`, and `gh api` for issues, PRs, CI runs, and advanced queries. To read a file from GitHub, do NOT use gh or markitdown — convert the blob URL to a raw URL (raw.githubusercontent.com) and fetch it directly with curl or the Read tool."
---

# GitHub Skill

Use the `gh` CLI to interact with GitHub. Always specify `--repo owner/repo` when not in a git directory, or use URLs directly.

## Reading Files

To read a file from GitHub, convert the blob URL to a raw URL and fetch directly — no `gh`, no markitdown:

```
https://github.com/user/repo/blob/branch/path/file.ts
→ https://raw.githubusercontent.com/user/repo/branch/path/file.ts
```

```bash
curl https://raw.githubusercontent.com/user/repo/branch/path/file.ts
```

## Pull Requests

Check CI status on a PR:
```bash
gh pr checks 55 --repo owner/repo
```

List recent workflow runs:
```bash
gh run list --repo owner/repo --limit 10
```

View a run and see which steps failed:
```bash
gh run view <run-id> --repo owner/repo
```

View logs for failed steps only:
```bash
gh run view <run-id> --repo owner/repo --log-failed
```

## API for Advanced Queries

The `gh api` command is useful for accessing data not available through other subcommands.

Get PR with specific fields:
```bash
gh api repos/owner/repo/pulls/55 --jq '.title, .state, .user.login'
```

## JSON Output

Most commands support `--json` for structured output.  You can use `--jq` to filter:

```bash
gh issue list --repo owner/repo --json number,title --jq '.[] | "\(.number): \(.title)"'
```
