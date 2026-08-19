import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function tmuxStatusExtension(pi: ExtensionAPI): void {
	const pane = process.env.TMUX_PANE;
	if (!pane) return;

	async function setStatus(status?: "working" | "done"): Promise<void> {
		const args = status
			? ["set-option", "-p", "-t", pane, "@pi_status", status]
			: ["set-option", "-pu", "-t", pane, "@pi_status"];
		await pi.exec("tmux", args);
	}

	pi.on("session_start", () => setStatus("done"));
	pi.on("agent_start", () => setStatus("working"));
	pi.on("agent_settled", () => setStatus("done"));
	pi.on("session_shutdown", () => setStatus());
}
