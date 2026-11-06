# Subagents

The `subagent` tool delegates one task to a fresh Pi session in the same working directory. The child does not see the parent conversation, but shares the filesystem. Independent calls can run in parallel.

The tool's prompt guidance encourages delegation for exploration, research, debugging, scoped implementation, and independent review of nontrivial changes. Trivial tasks and user requests not to delegate are exceptions.

## Arguments

- `title` is the progress label.
- `prompt` supplies complete context and the expected result.
- `thinkingLevel` optionally selects `low`, `medium`, or `high` reasoning. Omit it for the default in `index.ts`.

The model and default reasoning level are constants in `index.ts`. There is no config file. Children inherit all compatible active parent tools, including codemode and MCP support. Subagent delegation and user questions are excluded. The progress display shows the model and reasoning level.

Children must perform one current task without sleeping, polling, or monitoring. Parallel coding tasks should have non-overlapping file ownership.

Run `/reload` in existing Pi sessions after changing the extension. See `index.ts` for defaults, the tool schema, and delegation guidance.
