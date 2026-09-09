import type { ExtensionAPI, ProviderModelConfig } from "@earendil-works/pi-coding-agent";
import type { Model } from "@earendil-works/pi-ai";

const PROVIDER_ID = "zai-api";
const BASE_URL = "https://api.z.ai/api/paas/v4";

const COMPAT = {
	supportsStore: false,
	supportsDeveloperRole: false,
	maxTokensField: "max_tokens",
	thinkingFormat: "zai",
	zaiToolStream: true,
} as const;

const GLM_53_THINKING_LEVELS = {
	off: null,
	minimal: null,
	low: "low",
	medium: null,
	high: "high",
	xhigh: null,
	max: "max",
} as const;

const GLM_52_THINKING_LEVELS = {
	off: "none",
	minimal: null,
	low: null,
	medium: null,
	high: "high",
	xhigh: null,
	max: "max",
} as const;

const STATIC_MODELS: ProviderModelConfig[] = [
	{
		id: "glm-5.3-flash",
		name: "GLM-5.3-Flash",
		reasoning: true,
		thinkingLevelMap: GLM_53_THINKING_LEVELS,
		input: ["text", "image"],
		cost: { input: 0.075, output: 0.25, cacheRead: 0.015, cacheWrite: 0 },
		contextWindow: 1_000_000,
		maxTokens: 131_072,
		compat: { ...COMPAT, supportsReasoningEffort: true },
	},
	{
		id: "glm-5.3",
		name: "GLM-5.3",
		reasoning: true,
		thinkingLevelMap: GLM_53_THINKING_LEVELS,
		input: ["text"],
		cost: { input: 1.4, output: 4.4, cacheRead: 0.26, cacheWrite: 0 },
		contextWindow: 1_000_000,
		maxTokens: 131_072,
		compat: { ...COMPAT, supportsReasoningEffort: true },
	},
	{
		id: "glm-5.2",
		name: "GLM-5.2",
		reasoning: true,
		thinkingLevelMap: GLM_52_THINKING_LEVELS,
		input: ["text"],
		cost: { input: 1.4, output: 4.4, cacheRead: 0.26, cacheWrite: 0 },
		contextWindow: 1_000_000,
		maxTokens: 131_072,
		compat: { ...COMPAT, supportsReasoningEffort: true },
	},
];

type ZaiModel = {
	id: string;
	name?: string;
	input_modalities?: string[];
	context_length: number;
	max_output_length: number;
	pricing: Array<{
		prompt: string;
		completion: string;
		input_cache_read?: string;
	}>;
	discount_to_user?: number;
	supported_features?: string[];
};

function storedModelToConfig(model: Model): ProviderModelConfig {
	return {
		id: model.id,
		name: model.name,
		reasoning: model.reasoning,
		thinkingLevelMap: model.thinkingLevelMap,
		input: [...model.input],
		cost: model.cost,
		contextWindow: model.contextWindow,
		maxTokens: model.maxTokens,
		compat: model.compat,
	};
}

function costFor(model: ZaiModel): ProviderModelConfig["cost"] {
	const pricing = model.pricing[0];
	if (!pricing) {
		if (model.id.endsWith(":free")) return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 };
		throw new Error(`Missing pricing for ${model.id}`);
	}

	const discount = model.discount_to_user ?? 1;
	if (!Number.isFinite(discount) || discount < 0) throw new Error(`Invalid discount for ${model.id}`);
	const perMillion = (value: string | undefined) => {
		const price = Number(value ?? 0);
		if (!Number.isFinite(price) || price < 0) throw new Error(`Invalid pricing for ${model.id}`);
		return price * 1_000_000 * discount;
	};

	return {
		input: perMillion(pricing.prompt),
		output: perMillion(pricing.completion),
		cacheRead: perMillion(pricing.input_cache_read),
		cacheWrite: 0,
	};
}

function modelConfigFor(model: ZaiModel): ProviderModelConfig {
	if (!Number.isInteger(model.context_length) || model.context_length <= 0) throw new Error(`Invalid context length for ${model.id}`);
	if (!Number.isInteger(model.max_output_length) || model.max_output_length <= 0) throw new Error(`Invalid output limit for ${model.id}`);

	const thinkingLevelMap = model.id === "glm-5.2"
		? GLM_52_THINKING_LEVELS
		: model.id === "glm-5.3" || model.id === "glm-5.3-flash"
			? GLM_53_THINKING_LEVELS
			: undefined;

	return {
		id: model.id,
		name: model.name ?? model.id,
		reasoning: model.supported_features?.includes("reasoning") ?? false,
		thinkingLevelMap,
		input: model.input_modalities?.includes("image") ? ["text", "image"] : ["text"],
		cost: costFor(model),
		contextWindow: model.context_length,
		maxTokens: model.max_output_length,
		compat: { ...COMPAT, supportsReasoningEffort: thinkingLevelMap !== undefined },
	};
}

export default function (pi: ExtensionAPI) {
	pi.registerProvider(PROVIDER_ID, {
		name: "Z.AI API",
		baseUrl: BASE_URL,
		apiKey: "$ZAI_API_KEY",
		api: "openai-completions",
		models: STATIC_MODELS,
		async refreshModels(context) {
			if (!context.allowNetwork) {
				return context.stored?.models.map(storedModelToConfig) ?? STATIC_MODELS;
			}

			const apiKey = context.credential?.type === "api_key" ? context.credential.key : undefined;
			if (!apiKey) throw new Error("ZAI_API_KEY is not configured");

			const response = await fetch(`${BASE_URL}/v1/models`, {
				headers: { Authorization: `Bearer ${apiKey}` },
				signal: context.signal,
			});
			if (!response.ok) throw new Error(`Z.AI model refresh failed with HTTP ${response.status}`);

			const payload = await response.json() as { data?: ZaiModel[] };
			if (!Array.isArray(payload.data) || payload.data.length === 0) {
				throw new Error("Z.AI model refresh returned an invalid response");
			}
			const models = payload.data.map(modelConfigFor);

			await context.publish({
				persist: {
					models: models.map((model) => ({
						...model,
						api: "openai-completions" as const,
						provider: PROVIDER_ID,
						baseUrl: BASE_URL,
					})),
					checkedAt: Date.now(),
				},
			});
			return models;
		},
	});
}
