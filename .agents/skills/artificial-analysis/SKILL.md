---
name: artificial-analysis
description: Query Artificial Analysis API to compare LLM benchmarks, pricing, and speed. Use when exploring which AI model to use for a task, comparing model performance, or checking pricing/speed tradeoffs.
---

# Artificial Analysis

Query the [Artificial Analysis](https://artificialanalysis.ai/) free API to compare AI models on benchmarks, pricing, and speed. Useful when deciding which LLM (or image/video/speech model) to use for a specific task.

## Setup

Requires an API key set as `ARTIFICIAL_ANALYSIS_API_KEY` environment variable.

1. Create an account at https://artificialanalysis.ai/login
2. Generate an API key from the Insights Platform
3. Set the env var (fish: `set -Ux ARTIFICIAL_ANALYSIS_API_KEY "your-key"`)

## API Reference

Full docs (endpoints, fields, response formats): https://artificialanalysis.ai/api-reference#free-api

Rate limit: 1,000 requests/day. Cache responses when possible.

## Endpoints

### LLMs — benchmarks, pricing, speed

```bash
curl -s "https://artificialanalysis.ai/api/v2/data/llms/models" \
  -H "x-api-key: $ARTIFICIAL_ANALYSIS_API_KEY" | python3 -m json.tool
```

Key response fields: `evaluations` (benchmark scores), `pricing` (per 1M tokens), `median_output_tokens_per_second`, `median_time_to_first_token_seconds`.

### Text-to-Image — ELO ratings

```bash
curl -s "https://artificialanalysis.ai/api/v2/data/media/text-to-image" \
  -H "x-api-key: $ARTIFICIAL_ANALYSIS_API_KEY"
```

Add `?include_categories=true` for per-category ELO breakdown.

### Image Editing — ELO ratings

```bash
curl -s "https://artificialanalysis.ai/api/v2/data/media/image-editing" \
  -H "x-api-key: $ARTIFICIAL_ANALYSIS_API_KEY"
```

### Text-to-Speech — ELO ratings

```bash
curl -s "https://artificialanalysis.ai/api/v2/data/media/text-to-speech" \
  -H "x-api-key: $ARTIFICIAL_ANALYSIS_API_KEY"
```

### Text-to-Video — ELO ratings

```bash
curl -s "https://artificialanalysis.ai/api/v2/data/media/text-to-video" \
  -H "x-api-key: $ARTIFICIAL_ANALYSIS_API_KEY"
```

Add `?include_categories=true` for per-category breakdown.

### Image-to-Video — ELO ratings

```bash
curl -s "https://artificialanalysis.ai/api/v2/data/media/image-to-video" \
  -H "x-api-key: $ARTIFICIAL_ANALYSIS_API_KEY"
```

Add `?include_categories=true` for per-category breakdown.

## Tips

- The free API does not include openness/licensing data. When filtering for open-weight models, use web searches to verify which models are actually open before presenting results.

- Use `jq` to filter/sort results (e.g., `| jq '.data | sort_by(.pricing.price_1m_blended_3_to_1)'`)
- For LLMs, compare `evaluations.artificial_analysis_intelligence_index` against `pricing.price_1m_blended_3_to_1` for value analysis
- Use model `id` fields as stable identifiers — `name` and `slug` may change
- Attribution required: link to https://artificialanalysis.ai/ when sharing data

## When to Use

- Comparing LLMs for a specific use case (coding, math, general intelligence)
- Evaluating price/performance tradeoffs between models
- Checking which model is fastest (tokens/sec, time to first token)
- Comparing image, video, or speech generation models
