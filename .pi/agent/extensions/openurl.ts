import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const URL_PATTERN = /https?:\/\/[^\s<>"'`]+/giu;
const BRACKET_PAIRS: Record<string, string> = {
	")": "(",
	"]": "[",
	"}": "{",
};

function trimUrl({ candidate, prefix }: { candidate: string; prefix: string }): string {
	let url = candidate;
	if (/\]\(\s*$/u.test(prefix)) {
		let depth = 0;
		for (let index = 0; index < url.length; index++) {
			if (url[index] === "(") depth++;
			if (url[index] !== ")") continue;
			if (depth === 0) return url.slice(0, index);
			depth--;
		}
	}
	for (const marker of ["**", "__", "~~"]) {
		if (prefix.endsWith(marker) && url.endsWith(marker)) url = url.slice(0, -marker.length);
	}
	url = url.replace(/[.,;:!?]+$/u, "");

	while (true) {
		const closingBracket = url.at(-1);
		if (!closingBracket || !(closingBracket in BRACKET_PAIRS)) break;

		const openingBracket = BRACKET_PAIRS[closingBracket];
		const openingCount = url.split(openingBracket).length - 1;
		const closingCount = url.split(closingBracket).length - 1;
		if (closingCount <= openingCount) break;
		url = url.slice(0, -1);
	}

	return url;
}

export function extractUrls(text: string): string[] {
	const urls = [...text.matchAll(URL_PATTERN)]
		.map((match) => trimUrl({ candidate: match[0], prefix: text.slice(0, match.index) }))
		.filter((candidate) => {
			try {
				const url = new URL(candidate);
				return url.protocol === "http:" || url.protocol === "https:";
			} catch {
				return false;
			}
		});

	return [...new Set(urls)];
}

async function openUrl({ pi, url }: { pi: ExtensionAPI; url: string }): Promise<string | undefined> {
	const command = process.platform === "darwin" ? "open" : process.platform === "win32" ? "cmd" : "xdg-open";
	const args = process.platform === "win32" ? ["/c", "start", "", url] : [url];
	const result = await pi.exec(command, args);

	if (result.code === 0) return;
	return result.stderr.trim() || `The ${command} command exited with code ${result.code}.`;
}

export default function openUrlExtension(pi: ExtensionAPI) {
	for (const action of ["open", "copy"] as const) {
		pi.registerCommand(`${action}url`, {
			description: `${action === "open" ? "Open" : "Copy"} a URL from the last assistant message`,
			handler: async (_args, ctx) => {
				const branch = ctx.sessionManager.getBranch();
				let lastAssistantEntry;
				for (let index = branch.length - 1; index >= 0; index--) {
					const entry = branch[index];
					if (entry.type === "message" && entry.message.role === "assistant") {
						lastAssistantEntry = entry;
						break;
					}
				}

				if (!lastAssistantEntry) {
					ctx.ui.notify("No assistant message found", "error");
					return;
				}

				const text = lastAssistantEntry.message.content
					.filter((content): content is { type: "text"; text: string } => content.type === "text")
					.map((content) => content.text)
					.join("\n");
				const urls = extractUrls(text);

				if (urls.length === 0) {
					ctx.ui.notify("No URLs found in the last assistant message", "error");
					return;
				}

				if (urls.length > 1 && !ctx.hasUI) return;
				const selectedUrl = urls.length === 1 ? urls[0] : await ctx.ui.select(action === "open" ? "Open URL" : "Copy URL", urls);
				if (!selectedUrl) return;

				try {
					if (action === "copy") {
						const { copyToClipboard } = await import("@earendil-works/pi-coding-agent");
						await copyToClipboard(selectedUrl);
					} else {
						const error = await openUrl({ pi, url: selectedUrl });
						if (error) throw new Error(error);
					}
				} catch (error) {
					ctx.ui.notify(`Could not ${action} ${selectedUrl}: ${error instanceof Error ? error.message : String(error)}`, "error");
					return;
				}

				ctx.ui.notify(`${action === "open" ? "Opened" : "Copied"} ${selectedUrl}`, "info");
			},
		});
	}
}
