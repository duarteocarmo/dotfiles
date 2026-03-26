import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { writeFileSync, unlinkSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { exec } from "node:child_process";
import { marked } from "marked";

const HTML_TEMPLATE = (body: string) => `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Preview</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/holiday.css@0.11.5">
<style>body { max-width: 900px; }</style>
</head>
<body>${body}</body>
</html>`;

const CLEANUP_DELAY_MS = 60_000;

export default function (pi: ExtensionAPI) {
  pi.registerCommand("preview", {
    description: "Preview last assistant message as HTML in the browser",
    handler: async (_args, ctx) => {
      const entries = ctx.sessionManager.getBranch();

      let lastAssistantText = "";
      for (let i = entries.length - 1; i >= 0; i--) {
        const entry = entries[i];
        if (entry.type === "message" && entry.message.role === "assistant") {
          const content = entry.message.content;
          if (typeof content === "string") {
            lastAssistantText = content;
          } else if (Array.isArray(content)) {
            lastAssistantText = content
              .filter((b: any) => b.type === "text")
              .map((b: any) => b.text)
              .join("\n");
          }
          break;
        }
      }

      if (!lastAssistantText) {
        ctx.ui.notify("No assistant message found", "warning");
        return;
      }

      const html = HTML_TEMPLATE(await marked.parse(lastAssistantText));
      const filepath = join(tmpdir(), `pi-preview-${Date.now()}.html`);
      writeFileSync(filepath, html, "utf-8");
      exec(`open "${filepath}"`);
      ctx.ui.notify("Opened preview in browser", "info");

      setTimeout(() => {
        try { unlinkSync(filepath); } catch {}
      }, CLEANUP_DELAY_MS);
    },
  });
}
