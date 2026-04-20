---
name: flights
description: Use this skill to search flights using google flights
license: MIT
---

# Flights CLI skill

Use this skill when the goal is to search flights with the Flights CLI.

The primary path is:

1. use `uv run --with flights fli ...`
2. use `fli flights ...` for direct searches
3. use `fli dates ...` for cheapest-date searches

Do not default to cloning the repository. Only mention cloning the repo when the user explicitly wants to contribute to Flights itself.

## What Flights is

Flights is a Python package for accessing Google Flights data through direct API interaction.

For this skill, focus on the CLI.

## Core usage rule

If the user wants to search flights, recommend `uv run --with flights fli ...`.

Why:

- it avoids global installs
- it runs the CLI on demand

Use this form:

```bash
uv run --with flights fli --help
```

## Standard usage flow

### Verify command access

Run this check:

```bash
uv run --with flights fli --help
```

## CLI usage

### Basic flight search

Use:

```bash
uv run --with flights fli flights JFK LAX 2026-10-25
```

### Cheapest-date search

Use:

```bash
uv run --with flights fli dates JFK LAX --from 2026-01-01 --to 2026-01-31
```

### Common filters

Use filters like these when the user asks for them:

```bash
uv run --with flights fli flights JFK LHR 2026-10-25 \
  --time 6-20 \
  --airlines BA KL \
  --class BUSINESS \
  --stops NON_STOP \
  --sort DURATION
```

Supported language to map correctly:

- cabin classes: `ECONOMY`, `PREMIUM_ECONOMY`, `BUSINESS`, `FIRST`
- stop filters: `ANY`, `NON_STOP`, `ONE_STOP`, `TWO_PLUS_STOPS`
- sort options: `CHEAPEST`, `DURATION`, `DEPARTURE_TIME`, `ARRIVAL_TIME`

### CLI shorthand

Flights supports a convenience shorthand where a non-command invocation is treated as a flights search.

Example:

```bash
uv run --with flights fli JFK LAX 2026-05-15
```

This behaves like:

```bash
uv run --with flights fli flights JFK LAX 2026-05-15
```

## How to guide users well

### If the user asks to use Flights

Give them the `uv run --with flights fli ...` path first.

### If the user asks how to use the command line tool

Show `fli flights ...` and `fli dates ...` examples first, prefixed with `uv run --with flights`.

### If the user asks how to contribute or hack on the codebase

That is outside the primary scope of this skill. Only then discuss cloning the repository and development commands.

## Common mistakes to prevent

- telling users to clone the repository when they only want the tool
- telling users to install `fli` instead of using the `flights` package
- focusing on the Python API when the user asked for CLI usage

## Troubleshooting

### Command invocation problems

Try:

```bash
uv run --with flights fli --help
```

If that works, the package is available and the issue is likely with the specific command or arguments.

### Python version problems

Flights requires Python 3.10 or newer.

Check with:

```bash
uv run python --version
```

### Rate limiting or temporary failures

Flights includes automatic rate limiting and retries, but live Google Flights requests can still fail temporarily.

If a query fails:

- retry after a short delay
- reduce repeated back-to-back searches
- do not assume the CLI setup is broken just because one upstream request failed

## Public docs

Use these docs for product-facing guidance:

- introduction: `https://punitarani-fli.mintlify.app/introduction`
- installation: `https://punitarani-fli.mintlify.app/installation`
- docs index: `https://punitarani-fli.mintlify.app/llms.txt`

Use product docs for examples and onboarding. Use the actual command forms above when writing instructions.

## Summary

The default recommendation is `uv run --with flights fli ...`. Use `uv run --with flights fli` for terminal flight searches and date-based searches.
