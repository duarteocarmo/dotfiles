import { FooterComponent, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { spawn, type ChildProcess } from "node:child_process";

let caffeinate: ChildProcess | undefined;
let enabled = false;

function stop(): void {
	const child = caffeinate;
	caffeinate = undefined;
	if (child && child.exitCode === null && !child.killed) {
		child.kill("SIGTERM");
	}
}

function start(ctx: ExtensionContext): void {
	if (process.platform !== "darwin") {
		ctx.ui.notify("No Sleep requires macOS.", "error");
		return;
	}
	if (caffeinate) return;

	const child = spawn("caffeinate", ["-d", "-w", String(process.pid)], {
		stdio: "ignore",
	});
	child.unref();
	caffeinate = child;

	child.once("error", (error) => {
		if (caffeinate !== child) return;
		caffeinate = undefined;
		enabled = false;
		ctx.ui.notify(`No Sleep failed: ${error.message}`, "error");
	});

	child.once("exit", (code, signal) => {
		if (caffeinate !== child) return;
		caffeinate = undefined;
		enabled = false;
		ctx.ui.notify(`No Sleep stopped unexpectedly (${code ?? signal}).`, "warning");
	});
}

export default function noSleepExtension(pi: ExtensionAPI): void {
	const originalFooterRender = FooterComponent.prototype.render;
	const renderFooter = function (this: FooterComponent, width: number): string[] {
		const lines = originalFooterRender.call(this, width);
		if (!caffeinate) return lines;

		const lineIndex = lines.findIndex((line) => line.includes("(auto)"));
		if (lineIndex === -1) return lines;

		const marker = "(auto)";
		const indicator = " ☕";
		const markerEnd = lines[lineIndex].indexOf(marker) + marker.length;
		let line = `${lines[lineIndex].slice(0, markerEnd)}${indicator}${lines[lineIndex].slice(markerEnd)}`;
		const overflow = visibleWidth(line) - width;
		if (overflow > 0) {
			const suffixStart = markerEnd + indicator.length;
			const suffix = line.slice(suffixStart);
			const padding = suffix.match(/ +/);
			if (padding && padding[0].length > overflow) {
				const paddingStart = suffixStart + (padding.index ?? 0);
				line = `${line.slice(0, paddingStart)}${padding[0].slice(overflow)}${line.slice(paddingStart + padding[0].length)}`;
			}
		}
		lines[lineIndex] = truncateToWidth(line, width, "");
		return lines;
	};
	FooterComponent.prototype.render = renderFooter;

	process.once("exit", () => stop());

	pi.on("session_shutdown", () => {
		stop();
		if (FooterComponent.prototype.render === renderFooter) {
			FooterComponent.prototype.render = originalFooterRender;
		}
	});

	pi.registerCommand("no-sleep", {
		description: "Toggle macOS display sleep prevention",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			if (enabled) {
				start(ctx);
			} else {
				stop();
			}
			ctx.ui.notify(`No Sleep ${enabled ? "on ☕" : "off"}.`, "info");
		},
	});
}
