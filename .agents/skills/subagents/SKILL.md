---
name: subagents
description: Run parallel sub-agent tasks using pi CLI with claude-haiku-4-5. Use when a task can be decomposed into independent subtasks that benefit from parallel execution — research, multi-source gathering, batch analysis, or any fan-out/fan-in pattern.
---

# Subagents

Run independent subtasks in parallel using `pi -p` with `claude-haiku-4-5`, then synthesize results.

## How It Works

1. **Decompose** the user's request into independent subtasks
2. **Run** subtasks in parallel via `xargs -P`
3. **Read** outputs and **synthesize** a concise final answer

## Running Parallel Agents

Use this pattern to fan out work:

```bash
printf '%s\n' "query1" "query2" "query3" | xargs -P0 -I{} sh -c \
  'pi -p --no-session --model anthropic/claude-haiku-4-5 "$1" > /tmp/subagent-$(echo "$1" | md5 | head -c 8).txt 2>&1' _ {}
```

- `-P0` runs all jobs in parallel (no limit)
- `--no-session` keeps runs ephemeral
- Output files use an md5 hash of the query for unique naming

For tasks needing tools like bash or file access, the sub-agents have full tool access by default. To restrict:

```bash
pi -p --no-session --model anthropic/claude-haiku-4-5 --tools read,bash "query"
```

## Crafting Sub-Agent Queries

Each sub-agent query must be **self-contained and specific**. The sub-agent has no context about the parent task.

**Good queries:**
- `"List the top 5 headlines from theguardian.com today. Be concise — headline and one-line summary only."`
- `"Read src/auth.py and list all public functions with their signatures. No explanations."`

**Bad queries:**
- `"Get the headlines"` (vague, no source)
- `"Analyze this file"` (which file?)
- `"Do step 3"` (no context)

Rules for queries:
- State exactly what to do and where
- Include the desired output format
- End with a conciseness instruction like "Be concise" or "No explanations"
- Keep each query focused on ONE thing

## Reading Results

After parallel execution completes, read each output file:

```bash
cat /tmp/subagent-*.txt
```

Then delete temp files:

```bash
rm -f /tmp/subagent-*.txt
```

## Synthesis

When presenting the final output to the user:
- Lead with the key takeaway or summary
- Group by theme, not by source (unless sources matter)
- Cut redundancy — if multiple sub-agents return overlapping info, deduplicate
- Keep it concise — the user asked one question, give one cohesive answer

## Examples

### Multi-source research
```bash
printf '%s\n' \
  "List the top 5 headlines from reuters.com today. Headline only, no descriptions." \
  "List the top 5 headlines from bbc.com/news today. Headline only, no descriptions." \
  "List the top 5 headlines from dr.dk today. Headline and English translation." \
  | xargs -P0 -I{} sh -c \
  'pi -p --no-session --model anthropic/claude-haiku-4-5 "$1" > /tmp/subagent-$(echo "$1" | md5 | head -c 8).txt 2>&1' _ {}
```

### Batch file analysis
```bash
find src/ -name "*.py" -maxdepth 1 | head -5 | xargs -P0 -I{} sh -c \
  'pi -p --no-session --model anthropic/claude-haiku-4-5 --tools read "Read {} and list all public functions with signatures. No explanations." > /tmp/subagent-$(echo "{}" | md5 | head -c 8).txt 2>&1' _ {}
```

## Limits

- Each sub-agent is stateless — no shared memory between them
- Each sub-agent has its own context window and tool access
- For tasks with dependencies between steps, run them sequentially, not in parallel
- If a sub-agent fails, its output file will contain the error — check before synthesizing
