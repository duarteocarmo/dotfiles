---
name: simplify
description: Review changed code for reuse, quality, and efficiency, then fix any issues found. Use when the user asks to simplify, clean up, or improve current changes.
---

# Simplify: Code Review and Cleanup

Review all changed files for reuse, quality, and efficiency. Fix any issues found.

## Phase 1: Identify Changes

Run `git diff` (or `git diff HEAD` if there are staged changes) to see what changed.

If there are no git changes, review the most recently modified files that the user mentioned or that you edited earlier in this conversation.

## Phase 2: Launch Three Review Agents in Parallel

Use the subagent capability from the installed extension to launch all three review agents concurrently in a single call.

Pass each agent the full diff (or equivalent changed-file context) so each review runs with complete context.

If subagents are unavailable for any reason, run the three reviews sequentially in this same session using the exact same scopes below.

### Agent 1: Code Reuse Review

For each change:

1. Search for existing utilities and helpers that could replace newly written code. Look in utility directories, shared modules, and files adjacent to changed files.
2. Flag any new function that duplicates existing functionality, and suggest the existing function to use.
3. Flag inline logic that could use an existing utility (string manipulation, path handling, env checks, type guards, etc).

### Agent 2: Code Quality Review

Review the same changes for hacky patterns:

1. Redundant state: duplicated state, cached values that should be derived, observers/effects that could be direct calls.
2. Parameter sprawl: adding params instead of generalizing/restructuring existing code.
3. Copy-paste with slight variation: near-duplicate blocks that should be unified.
4. Leaky abstractions: exposing internals or breaking abstraction boundaries.
5. Stringly-typed code: raw strings where constants/unions/branded types exist.
6. Unnecessary UI nesting: wrappers that add no layout value.
7. Unnecessary comments: remove comments that restate obvious behavior; keep only non-obvious WHY.

### Agent 3: Efficiency Review

Review the same changes for efficiency issues:

1. Unnecessary work: redundant computation, repeated reads, duplicate API calls, N+1 patterns.
2. Missed concurrency: independent operations run sequentially.
3. Hot-path bloat: blocking work in startup/per-request/per-render paths.
4. Recurring no-op updates: unconditional updates in loops/handlers; add change detection guards.
5. Unnecessary existence checks: avoid TOCTOU pre-checks; do the operation and handle errors.
6. Memory issues: unbounded data, missing cleanup, listener leaks.
7. Overly broad operations: loading too much data when a subset is enough.

## Phase 3: Aggregate and Fix Issues

Wait for all three subagents to complete. Aggregate findings and fix each issue directly.

If a finding is a false positive or not worth addressing, note it and move on.

When done, briefly summarize what was fixed, or confirm the code was already clean.

## Additional Focus

If the skill was invoked with user arguments (shown as `User: ...`), treat that as additional focus and apply it across all three reviews.
