# Codex image tool

A personal pi extension inspired by [pi-imagegen](https://github.com/Jon-Vii/pi-imagegen). It adds only the `imagegen` tool. No commands, studio, presets, or metadata database.

Run `/reload` in pi, select an `openai-codex` model, then ask for an image. The tool disappears when you select another provider and rejects execution outside Codex.

It uses pi's existing Codex login and the selected model to request an image from `gpt-image-2`. Run `/login` if needed. No separate API key or dependencies to install.

## Tool inputs

- `prompt`, required. Describe the image or the edits to make.
- `referencePaths`, optional. Up to four local PNG, JPEG, or WebP images, at most 20 MiB each.
- `outputPath`, optional. A new `.png` file. Relative paths resolve from the session working directory, and `~/` works. Defaults to pi's agent directory under `generated-images/`.
- `size` and `quality`, optional. See `index.ts` for allowed values.

Results include the saved path and an image attachment. Existing files are never overwritten. Requests support cancellation and have a five-minute timeout.

Prompts and reference images are sent to OpenAI. Generation uses your subscription limits. The selected Codex model must be supported by your account's backend. A model appearing in pi's catalog does not guarantee access. This uses an unofficial Codex backend and may break when OpenAI changes it.
