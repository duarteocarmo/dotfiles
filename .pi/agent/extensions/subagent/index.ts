import { spawn } from "node:child_process";
import * as fs from "node:fs/promises";
import * as os from "node:os";
import * as path from "node:path";
import { Type } from "@sinclair/typebox";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import type { Message } from "@mariozechner/pi-ai";

const WORKER_PROMPT_PATH = path.join(os.homedir(), ".pi", "agent", "agents", "worker.md");
const MAX_TASKS = 8;
const MAX_CONCURRENCY = 3;

type TaskStatus = "pending" | "running" | "done" | "failed";

interface TaskState {
	index: number;
	task: string;
	status: TaskStatus;
	messages: Message[];
	output: string;
	stderr: string;
	exitCode: number | null;
}

function stripFrontmatter(markdown: string): string {
	if (!markdown.startsWith("---\n")) return markdown;
	const end = markdown.indexOf("\n---\n", 4);
	if (end === -1) return markdown;
	return markdown.slice(end + 5);
}

function getFinalAssistantText(messages: Message[]): string {
	for (let index = messages.length - 1; index >= 0; index--) {
		const message = messages[index];
		if (message.role !== "assistant") continue;
		for (const content of message.content) {
			if (content.type === "text") return content.text;
		}
	}
	return "";
}

function getPiInvocation(args: string[]): { command: string; args: string[] } {
	if (process.argv[1]) {
		return { command: process.execPath, args: [process.argv[1], ...args] };
	}
	return { command: "pi", args };
}

function renderProgress(states: TaskState[], launchReason: string | null): string {
	const done = states.filter((state) => state.status === "done" || state.status === "failed").length;
	const running = states.filter((state) => state.status === "running").length;
	let text = `Subagents: ${done}/${states.length} done, ${running} running`;
	if (launchReason) text += `\nReason: ${launchReason}`;

	for (const state of states) {
		const icon =
			state.status === "done"
				? "✓"
				: state.status === "failed"
					? "✗"
					: state.status === "running"
						? "⏳"
						: "·";
		const outputPreview = state.output ? ` - ${state.output.split("\n")[0].slice(0, 90)}` : "";
		text += `\n${icon} [${state.index + 1}] ${state.task.slice(0, 60)}${outputPreview}`;
	}

	return text;
}

async function runTask(options: {
	state: TaskState;
	promptPath: string;
	cwd: string;
	signal: AbortSignal | undefined;
	onProgress: () => void;
}): Promise<void> {
	const { state, promptPath, cwd, signal, onProgress } = options;
	state.status = "running";
	onProgress();

	const args = ["--mode", "json", "-p", "--no-session", "--append-system-prompt", promptPath, `Task: ${state.task}`];
	const invocation = getPiInvocation(args);
	let buffer = "";

	state.exitCode = await new Promise<number>((resolve) => {
		const processHandle = spawn(invocation.command, invocation.args, {
			cwd,
			shell: false,
			stdio: ["ignore", "pipe", "pipe"],
		});

		const processLine = (line: string) => {
			if (!line.trim()) return;
			try {
				const event = JSON.parse(line);
				if (event.type === "message_end" && event.message) {
					state.messages.push(event.message as Message);
					state.output = getFinalAssistantText(state.messages);
					onProgress();
				}
			} catch {
				return;
			}
		};

		processHandle.stdout.on("data", (chunk) => {
			buffer += chunk.toString();
			const lines = buffer.split("\n");
			buffer = lines.pop() || "";
			for (const line of lines) processLine(line);
		});

		processHandle.stderr.on("data", (chunk) => {
			state.stderr += chunk.toString();
		});

		processHandle.on("close", (code) => {
			if (buffer.trim()) processLine(buffer);
			resolve(code ?? 0);
		});

		processHandle.on("error", () => {
			resolve(1);
		});

		if (signal) {
			const kill = () => {
				processHandle.kill("SIGTERM");
				setTimeout(() => {
					if (!processHandle.killed) processHandle.kill("SIGKILL");
				}, 5000);
			};
			if (signal.aborted) kill();
			else signal.addEventListener("abort", kill, { once: true });
		}
	});

	state.status = state.exitCode === 0 ? "done" : "failed";
	if (!state.output) state.output = getFinalAssistantText(state.messages);
	onProgress();
}

async function runTasksWithConcurrencyLimit(options: {
	tasks: TaskState[];
	promptPath: string;
	cwd: string;
	signal: AbortSignal | undefined;
	onProgress: () => void;
}): Promise<void> {
	const { tasks, promptPath, cwd, signal, onProgress } = options;
	const concurrency = Math.min(MAX_CONCURRENCY, tasks.length);
	let nextIndex = 0;

	const workers = new Array(concurrency).fill(null).map(async () => {
		while (true) {
			const index = nextIndex;
			nextIndex += 1;
			if (index >= tasks.length) return;
			await runTask({ state: tasks[index], promptPath, cwd, signal, onProgress });
		}
	});

	await Promise.all(workers);
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "subagent",
		label: "Subagent",
		description:
			"Delegate tasks to separate pi subprocesses with isolated context. Use this when the user asks to use/delegate/run a subagent, including 'Use subagent with task: ...'.",
		promptSnippet: "Delegate work to isolated subagent process(es).",
		promptGuidelines: [
			"Use this tool when the user asks to delegate work to a subagent.",
			"If the user says 'Use subagent with task: ...', pass everything after 'task:' as the task parameter.",
			"For multiple parallel subagents, use tasks: [task1, task2, ...].",
		],
		parameters: Type.Object({
			task: Type.Optional(Type.String({ description: "Single task to run in one subagent" })),
			tasks: Type.Optional(Type.Array(Type.String({ description: "Task to run in a subagent" }))),
			reason: Type.Optional(Type.String({ description: "Why this subagent launch is happening" })),
		}),
		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			const hasTask = typeof params.task === "string" && params.task.trim().length > 0;
			const hasTasks = Array.isArray(params.tasks) && params.tasks.length > 0;

			if (Number(hasTask) + Number(hasTasks) !== 1) {
				return {
					content: [{ type: "text", text: "Provide exactly one of: task or tasks." }],
					isError: true,
				};
			}

			const taskList = hasTask ? [params.task!.trim()] : (params.tasks || []).map((task) => task.trim()).filter(Boolean);
			const launchReason = typeof params.reason === "string" && params.reason.trim() ? params.reason.trim() : null;
			if (taskList.length === 0) {
				return {
					content: [{ type: "text", text: "No tasks provided." }],
					isError: true,
				};
			}
			if (taskList.length > MAX_TASKS) {
				return {
					content: [{ type: "text", text: `Too many tasks (${taskList.length}). Max is ${MAX_TASKS}.` }],
					isError: true,
				};
			}

			const workerMarkdown = await fs.readFile(WORKER_PROMPT_PATH, "utf-8");
			const workerPrompt = stripFrontmatter(workerMarkdown).trim();
			const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "pi-subagent-"));
			const promptPath = path.join(tmpDir, "worker-prompt.md");
			await fs.writeFile(promptPath, workerPrompt, { encoding: "utf-8", mode: 0o600 });

			const states: TaskState[] = taskList.map((task, index) => ({
				index,
				task,
				status: "pending",
				messages: [],
				output: "",
				stderr: "",
				exitCode: null,
			}));

			const emitProgress = () => {
				onUpdate?.({
					content: [{ type: "text", text: renderProgress(states, launchReason) }],
					details: { states, launchReason },
				});
			};

			emitProgress();

			try {
				await runTasksWithConcurrencyLimit({
					tasks: states,
					promptPath,
					cwd: ctx.cwd,
					signal,
					onProgress: emitProgress,
				});
			} finally {
				await fs.rm(tmpDir, { recursive: true, force: true });
			}

			if (states.length === 1) {
				const state = states[0];
				if (state.status === "failed") {
					return {
						content: [{ type: "text", text: `Subagent failed: ${state.stderr || state.output || "unknown error"}` }],
						isError: true,
						details: { states, launchReason },
					};
				}
				return {
					content: [{ type: "text", text: state.output || "(no output)" }],
					details: { states, launchReason },
				};
			}

			const successCount = states.filter((state) => state.status === "done").length;
			const summary = states
				.map((state) => {
					const status = state.status === "done" ? "completed" : "failed";
					const preview = (state.output || state.stderr || "(no output)").split("\n")[0].slice(0, 120);
					return `[${state.index + 1}] ${status}: ${preview}`;
				})
				.join("\n");

			const reasonLine = launchReason ? `Reason: ${launchReason}\n\n` : "";
			return {
				content: [
					{ type: "text", text: `Parallel subagents: ${successCount}/${states.length} succeeded\n\n${reasonLine}${summary}` },
				],
				isError: successCount !== states.length,
				details: { states, launchReason },
			};
		},
	});
}
