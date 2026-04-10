---
name: image-generation
description: Generate and edit images with the Gemini API. Use when the user asks for text-to-image, image editing, aspect-ratio/resolution controls, or image prompt refinement.
---

# Gemini Image Generation

## When to use this skill

Use this skill when the user wants to:
- Generate new images from text prompts
- Edit an existing image with natural language instructions
- Choose the right Gemini image model for quality/speed tradeoffs
- Control aspect ratio or output resolution
- Improve output quality through better prompting

## Requirements

- `GEMINI_API_KEY` available in your environment
- `uv` installed

## Quickstart (minimal examples)

### Text-to-image

```bash
uv run --with google-genai --with pillow python - <<'PY'
from google import genai
from PIL import Image

client = genai.Client()

prompt = "Create a picture of a nano banana dish in a fancy restaurant with a Gemini theme"
response = client.models.generate_content(
    model="gemini-3.1-flash-image-preview",
    contents=[prompt],
)

for part in response.parts:
    if part.text is not None:
        print(part.text)
    elif part.inline_data is not None:
        image = part.as_image()
        image.save("generated_image.png")
PY
```

### Image editing (prompt + input image)

```bash
uv run --with google-genai --with pillow python - <<'PY'
from google import genai
from google.genai import types
from PIL import Image

client = genai.Client()

prompt = (
    "Create a picture of my cat eating a nano-banana in a "
    "fancy restaurant under the Gemini constellation"
)

image = Image.open("/path/to/cat_image.png")

response = client.models.generate_content(
    model="gemini-3.1-flash-image-preview",
    contents=[prompt, image],
)

for part in response.parts:
    if part.text is not None:
        print(part.text)
    elif part.inline_data is not None:
        output_image = part.as_image()
        output_image.save("generated_image.png")
PY
```

## Model selection guideline

- **Gemini 3.1 Flash Image Preview (Nano Banana 2 Preview)**
  - Default choice for most tasks
  - Best overall quality/intelligence/cost/latency balance

- **Gemini 3 Pro Image Preview (Nano Banana Pro Preview)**
  - Professional asset production and complex instructions
  - Google Search grounding + default thinking behavior
  - Up to 4K output

- **Gemini 2.5 Flash Image (Nano Banana)**
  - Speed-first and high-volume workloads
  - Low latency, typically 1024px-class output

## Aspect ratio and resolution

Default behavior:
- With an input image: output usually follows input dimensions
- Without input image: output defaults to `1:1`

Use `image_config.aspect_ratio` for framing and `image_config.image_size` (3.1/3 Pro) for resolution tier.

```python
from google.genai import types

# gemini-2.5-flash-image
response = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents=[prompt],
    config=types.GenerateContentConfig(
        image_config=types.ImageConfig(
            aspect_ratio="16:9",
        )
    ),
)

# gemini-3.1-flash-image-preview and gemini-3-pro-image-preview
response = client.models.generate_content(
    model="gemini-3.1-flash-image-preview",
    contents=[prompt],
    config=types.GenerateContentConfig(
        image_config=types.ImageConfig(
            aspect_ratio="16:9",
            image_size="2K",
        )
    ),
)
```

### Resolution guidance

- **1K**: drafts and fast iteration
- **2K**: standard production default
- **4K**: high-detail deliverables
- Higher resolution increases latency, token usage, and memory usage

### Common aspect ratios

- `1:1` — social posts, thumbnails, avatars
- `16:9` — slides, YouTube, landscape banners
- `9:16` — stories, reels, shorts
- `4:5` — social feed posts
- `3:2` or `4:3` — photography-style framing

## Prompting strategies (good → great)

- **Be hyper-specific**: add concrete details, not vague labels.
- **Provide context and intent**: include the image purpose (brand ad, concept art, product mockup, etc.).
- **Iterate and refine**: do follow-up edits instead of restarting from scratch.
- **Use step-by-step instructions**: especially for complex multi-object scenes.
- **Use semantic negative prompts**: describe desired absence positively (for example, "an empty street with no traffic").
- **Control the camera**: use terms like "wide-angle shot", "macro shot", and "low-angle perspective".

## Output handling

- Responses may include both text and image parts
- Save image parts from `part.inline_data` with `part.as_image()`
- If no image is returned, refine prompt and retry
