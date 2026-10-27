import { randomUUID } from "node:crypto";
import { lstat, mkdir, readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { StringEnum } from "@earendil-works/pi-ai";
import { type ExtensionAPI, type ExtensionContext, getAgentDir, withFileMutationQueue } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const PROVIDER = "openai-codex";
const IMAGE_MODEL = "gpt-image-2";

interface ImageResult {
	type: string;
	result?: string;
}

interface ResponseEvent {
	type: string;
	message?: string;
	error?: { message?: string };
	item?: ImageResult;
	response?: {
		output?: ImageResult[];
		error?: { message?: string };
		incomplete_details?: { reason?: string };
	};
}

function localPath({ path, cwd }: { path: string; cwd: string }) {
	return resolve(cwd, path.startsWith("~/") ? join(homedir(), path.slice(2)) : path);
}

function parseFrame({ frame }: { frame: string }): ResponseEvent | undefined {
	const data = frame.split(/\r?\n/)
		.filter((line) => line.startsWith("data:"))
		.map((line) => line.slice(5).trimStart()).join("\n").trim();
	return data && data !== "[DONE]" ? JSON.parse(data) : undefined;
}

async function* readEvents({ response }: { response: Response }) {
	if (!response.body) throw new Error("Codex returned an empty response body.");
	let buffer = "";
	for await (const chunk of response.body.pipeThrough(new TextDecoderStream())) {
		const frames = (buffer + chunk).split(/\r?\n\r?\n/);
		buffer = frames.pop()!;
		for (const frame of frames) {
			const event = parseFrame({ frame });
			if (event) yield event;
		}
	}
	const event = parseFrame({ frame: buffer });
	if (event) yield event;
}

async function readImage({ response }: { response: Response }) {
	let image: ImageResult | undefined;
	for await (const event of readEvents({ response })) {
		if (["error", "response.failed", "response.incomplete"].includes(event.type)) {
			throw new Error(event.response?.error?.message ?? event.error?.message ?? event.message
				?? event.response?.incomplete_details?.reason ?? "Codex image generation failed.");
		}
		if (event.type === "response.output_item.done" && event.item?.type === "image_generation_call") {
			image = event.item;
		}
		if (event.type === "response.completed" || event.type === "response.done") {
			image ??= event.response?.output?.find((item) => item.type === "image_generation_call");
			if (!image?.result) throw new Error("Codex completed without an image. Try a different prompt or Codex model.");
			return image.result;
		}
	}
	throw new Error("Codex image stream ended before completion.");
}

export default function imagegen(pi: ExtensionAPI) {
	pi.registerTool({
		name: "imagegen",
		label: "Image generation",
		defaultActive: false,
		exposure: "direct",
		description: "Generate or edit one image using the selected OpenAI Codex model and your Codex login. Sends the prompt and optional local reference images to OpenAI. Saves a new PNG file and returns an image attachment. Existing files are never overwritten.",
		promptSnippet: "Generate or edit images through your Codex subscription",
		promptGuidelines: ["Use imagegen when the user asks for an AI-generated image. Use referencePaths to edit or take inspiration from existing images."],
		annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: true },
		parameters: Type.Object({
			prompt: Type.String({ minLength: 1, description: "Describe the image to generate, or the edits to make to the references." }),
			referencePaths: Type.Optional(Type.Array(Type.String(), { maxItems: 4, description: "Local PNG, JPEG, or WebP reference images. Paths are relative to the working directory." })),
			outputPath: Type.Optional(Type.String({ description: "New .png file path, relative to the working directory or absolute. Defaults to the pi agent generated-images directory." })),
			size: Type.Optional(StringEnum(["auto", "1024x1024", "1536x1024", "1024x1536"])),
			quality: Type.Optional(StringEnum(["auto", "low", "medium", "high"])),
		}),

		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			if (ctx.model?.provider !== PROVIDER) throw new Error("imagegen requires a selected openai-codex model.");
			const responseModel = ctx.model.id;
			if (!params.prompt.trim()) throw new Error("The image prompt must not be blank.");
			const outputPath = params.outputPath
				? localPath({ path: params.outputPath, cwd: ctx.cwd })
				: join(getAgentDir(), "generated-images", `${randomUUID()}.png`);
			if (!outputPath.toLowerCase().endsWith(".png")) throw new Error("outputPath must end with .png.");
			try {
				await lstat(outputPath);
				throw new Error(`Output already exists: ${outputPath}`);
			} catch (error) {
				if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
			}
			signal?.throwIfAborted();

			const content: Array<{ type: "input_text"; text: string } | { type: "input_image"; image_url: string }> = [
				{ type: "input_text", text: params.prompt },
			];
			for (const path of params.referencePaths ?? []) {
				const data = await readFile(localPath({ path, cwd: ctx.cwd }));
				if (data.length > 20 * 1024 * 1024) throw new Error(`Reference image exceeds 20 MiB: ${path}`);
				const mimeType = data.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])) ? "image/png"
					: data[0] === 0xff && data[1] === 0xd8 && data[2] === 0xff ? "image/jpeg"
					: data.toString("ascii", 0, 4) === "RIFF" && data.toString("ascii", 8, 12) === "WEBP" ? "image/webp" : undefined;
				if (!mimeType) throw new Error(`Reference must be a PNG, JPEG, or WebP image: ${path}`);
				content.push({ type: "input_image", image_url: `data:${mimeType};base64,${data.toString("base64")}` });
			}

			const token = await ctx.modelRegistry.getApiKeyForProvider(PROVIDER);
			if (!token) throw new Error("No Codex login found. Run /login and select OpenAI Codex.");
			let accountId: string | undefined;
			try {
				accountId = JSON.parse(Buffer.from(token.split(".")[1]!, "base64url").toString())["https://api.openai.com/auth"]?.chatgpt_account_id;
			} catch {
				throw new Error("Invalid Codex login token. Run /login again.");
			}
			if (!accountId) throw new Error("Codex login has no account ID. Run /login again.");

			const sessionId = randomUUID();
			const requestSignal = AbortSignal.any([...(signal ? [signal] : []), AbortSignal.timeout(300_000)]);
			const response = await fetch("https://chatgpt.com/backend-api/codex/responses", {
				method: "POST",
				headers: {
					Authorization: `Bearer ${token}`,
					"chatgpt-account-id": accountId,
					originator: "pi-imagegen-extension",
					"OpenAI-Beta": "responses=experimental",
					accept: "text/event-stream",
					"content-type": "application/json",
					session_id: sessionId,
					"x-client-request-id": sessionId,
				},
				body: JSON.stringify({
					model: responseModel,
					store: false,
					stream: true,
					instructions: "Use the image_generation tool to create exactly one image requested by the user. Do not write code.",
					input: [{ role: "user", content }],
					tool_choice: "required",
					parallel_tool_calls: false,
					tools: [{ type: "image_generation", model: IMAGE_MODEL, output_format: "png", size: params.size ?? "auto", quality: params.quality ?? "auto" }],
				}),
				signal: requestSignal,
			});
			if (!response.ok) throw new Error(`Codex image request failed with HTTP ${response.status}: ${(await response.text()).slice(0, 2000)}`);
			const base64 = await readImage({ response });
			requestSignal.throwIfAborted();
			const image = Buffer.from(base64, "base64");
			if (!image.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) {
				throw new Error("Codex returned invalid PNG data. No file was saved.");
			}
			await withFileMutationQueue(outputPath, async () => {
				await mkdir(dirname(outputPath), { recursive: true });
				await writeFile(outputPath, image, { flag: "wx" });
			});
			return {
				content: [
					{ type: "text", text: `Generated image saved to ${outputPath}` },
					{ type: "image", data: base64, mimeType: "image/png" },
				],
				details: { path: outputPath, responseModel, imageModel: IMAGE_MODEL },
			};
		},
	});

	function syncAvailability(ctx: ExtensionContext) {
		const active = pi.getActiveTools();
		const enabled = ctx.model?.provider === PROVIDER;
		if (active.includes("imagegen") === enabled) return;
		pi.setActiveTools(enabled ? [...active, "imagegen"] : active.filter((name) => name !== "imagegen"));
	}
	pi.on("session_start", (_event, ctx) => syncAvailability(ctx));
	pi.on("model_select", (_event, ctx) => syncAvailability(ctx));
	pi.on("before_agent_start", (_event, ctx) => syncAvailability(ctx));
}
