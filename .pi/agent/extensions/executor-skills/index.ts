import { getAgentDir, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { chmod, mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { dirname, join, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const SERVER_NAME = process.env.PI_EXECUTOR_SKILLS_SERVER ?? "executor";
const APP_SLUG = process.env.PI_EXECUTOR_SKILLS_APP ?? "duarte-s-skills";
const SYNC_TIMEOUT_MS = 10_000;
const CACHE_DIR = join(getAgentDir(), "executor-skills");
const SKILLS_DIR = join(CACHE_DIR, "skills");
const OWN_SKILLS_DIR = join(dirname(fileURLToPath(import.meta.url)), "skills");
const META_FILE = join(CACHE_DIR, "meta.json");

type Bundle = { skills: { name: string; files: { path: string; content: string }[] }[] };
type Meta = { hash: string; syncedAt: string; skills: number };
type BundlePart = { hash: string; unchanged: boolean; parts?: number; chunk?: string };
type SyncResult = { status: "updated" | "unchanged" | "offline"; detail?: string; meta?: Meta };

async function readJson<T>(path: string): Promise<T | undefined> {
  try {
    return JSON.parse(await readFile(path, "utf8")) as T;
  } catch {
    return undefined;
  }
}

async function credentialsFor(): Promise<{ url: string; token: string }> {
  const agentDir = getAgentDir();
  const mcpConfig = await readJson<{ mcpServers?: Record<string, { url?: string }> }>(join(agentDir, "mcp.json"));
  const url = mcpConfig?.mcpServers?.[SERVER_NAME]?.url;
  if (!url) throw new Error(`no "${SERVER_NAME}" server with a url in mcp.json`);

  const auth = await readJson<Record<string, { tokens?: { access_token?: string }; tokensExpireAt?: number }>>(
    join(agentDir, "mcp-auth.json"),
  );
  const entry = auth?.[`mcp__${SERVER_NAME}|${url}`];
  const token = entry?.tokens?.access_token;
  if (!token) throw new Error(`not signed in, run: pi mcp login ${SERVER_NAME}`);
  // pi refreshes the token whenever it uses the server; we never refresh it ourselves.
  if (entry.tokensExpireAt && entry.tokensExpireAt < Date.now() + 30_000) throw new Error("token expired");
  return { url, token };
}

async function fetchBundle(
  url: string,
  token: string,
  ifNoneMatch?: string,
): Promise<{ hash: string; unchanged: boolean; bundle?: string }> {
  const signal = AbortSignal.timeout(SYNC_TIMEOUT_MS);
  let sessionId: string | undefined;
  let protocolVersion: string | undefined;
  let nextId = 1;

  async function rpc(method: string, params: unknown, notification = false): Promise<any> {
    const id = notification ? undefined : nextId++;
    const response = await fetch(url, {
      method: "POST",
      signal,
      headers: {
        authorization: `Bearer ${token}`,
        "content-type": "application/json",
        accept: "application/json, text/event-stream",
        ...(sessionId ? { "mcp-session-id": sessionId } : {}),
        ...(protocolVersion ? { "mcp-protocol-version": protocolVersion } : {}),
      },
      body: JSON.stringify({ jsonrpc: "2.0", method, params, ...(id === undefined ? {} : { id }) }),
    });
    sessionId ??= response.headers.get("mcp-session-id") ?? undefined;
    if (!response.ok) throw new Error(`${method}: HTTP ${response.status}`);
    if (id === undefined) return;

    const body = await response.text();
    const messages = (response.headers.get("content-type") ?? "").includes("text/event-stream")
      ? body.split("\n").filter((line) => line.startsWith("data:")).map((line) => JSON.parse(line.slice(5)))
      : [JSON.parse(body)];
    const message = messages.find((m) => m.id === id);
    if (!message) throw new Error(`${method}: no response`);
    if (message.error) throw new Error(`${method}: ${message.error.message}`);
    return message.result;
  }

  const init = await rpc("initialize", {
    protocolVersion: "2025-06-18",
    capabilities: {},
    clientInfo: { name: "pi-executor-skills", version: "0.1.0" },
  });
  protocolVersion = init?.protocolVersion;
  await rpc("notifications/initialized", {}, true);

  async function bundlePart(input: { ifNoneMatch?: string; part?: number }): Promise<BundlePart> {
    const result = await rpc("tools/call", {
      name: "call",
      arguments: { calls: { path: `tools["${APP_SLUG}"].bundle`, input } },
    });
    const text = result?.content?.find((c: { type: string }) => c.type === "text")?.text;
    const call = JSON.parse(text ?? "{}")?.execution?.value;
    if (!call?.ok) throw new Error(call?.error?.message ?? "bundle call failed");
    return call.value;
  }

  try {
    const first = await bundlePart(ifNoneMatch ? { ifNoneMatch } : {});
    if (first.unchanged) return { hash: first.hash, unchanged: true };
    const chunks = [first.chunk ?? ""];
    for (let part = 1; part < (first.parts ?? 1); part++) {
      const next = await bundlePart({ part });
      if (next.hash !== first.hash) throw new Error("bundle changed while syncing");
      chunks.push(next.chunk ?? "");
    }
    return { hash: first.hash, unchanged: false, bundle: chunks.join("") };
  } finally {
    if (sessionId) {
      fetch(url, { method: "DELETE", headers: { authorization: `Bearer ${token}`, "mcp-session-id": sessionId } }).catch(
        () => {},
      );
    }
  }
}

function safeJoin(root: string, relative: string): string {
  const target = resolve(root, relative);
  if (!target.startsWith(root + sep)) throw new Error(`unsafe path in bundle: ${relative}`);
  return target;
}

async function writeCache(hash: string, bundle: Bundle): Promise<Meta> {
  const staging = `${CACHE_DIR}.tmp-${process.pid}`;
  await rm(staging, { recursive: true, force: true });
  const stagingSkills = join(staging, "skills");
  for (const skill of bundle.skills) {
    const skillDir = safeJoin(stagingSkills, skill.name);
    for (const file of skill.files) {
      const target = safeJoin(skillDir, file.path);
      await mkdir(dirname(target), { recursive: true });
      await writeFile(target, file.content);
      if (file.content.startsWith("#!")) await chmod(target, 0o755);
    }
  }
  const meta: Meta = { hash, syncedAt: new Date().toISOString(), skills: bundle.skills.length };
  await writeFile(join(staging, "meta.json"), JSON.stringify(meta, null, 2));

  await rm(CACHE_DIR, { recursive: true, force: true });
  await rename(staging, CACHE_DIR);
  return meta;
}

export async function syncSkills(): Promise<SyncResult> {
  const cached = await readJson<Meta>(META_FILE);
  try {
    const { url, token } = await credentialsFor();
    const value = await fetchBundle(url, token, cached?.hash);
    if (value.unchanged && cached) return { status: "unchanged", meta: cached };
    const meta = await writeCache(value.hash, JSON.parse(value.bundle ?? "") as Bundle);
    return { status: "updated", meta };
  } catch (error) {
    return { status: "offline", detail: error instanceof Error ? error.message : String(error), meta: cached };
  }
}

function report(ctx: ExtensionContext, result: SyncResult, verbose: boolean): void {
  if (result.status === "offline") {
    const fallback = result.meta ? `using cache from ${result.meta.syncedAt}` : "no cached skills yet";
    ctx.ui.notify(`Executor skills: ${result.detail}; ${fallback}`, result.meta ? "warning" : "error");
  } else if (verbose || result.status === "updated") {
    ctx.ui.notify(`Executor skills ${result.status}: ${result.meta?.skills} skills`, "info");
  }
}

export default function executorSkillsExtension(pi: ExtensionAPI): void {
  pi.on("resources_discover", async (_event, ctx) => {
    report(ctx, await syncSkills(), false);
    return { skillPaths: [SKILLS_DIR, OWN_SKILLS_DIR] };
  });

  pi.registerCommand("executor-skills", {
    description: "Sync skills from Executor, then reload if they changed",
    handler: async (_args, ctx) => {
      const result = await syncSkills();
      report(ctx, result, true);
      if (result.status === "updated") await ctx.reload();
    },
  });
}
