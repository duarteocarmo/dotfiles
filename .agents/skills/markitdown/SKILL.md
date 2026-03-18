---
name: markitdown
description: "Convert files and URLs to Markdown using Microsoft's markitdown. Use for web pages, web PDFs, or local files — supports: PDF, PowerPoint, Word, Excel, Images (EXIF + OCR), Audio (transcription), HTML, CSV/JSON/XML, ZIP files, YouTube URLs, EPubs, and more. Do NOT use for GitHub URLs — convert to raw.githubusercontent.com and fetch directly instead. Runs via uvx with no install needed."
---

# MarkItDown

Convert files and web pages to Markdown using [Microsoft MarkItDown](https://github.com/microsoft/markitdown). Runs instantly via `uvx` — no installation or venv required.

## Read a Web Page

```bash
uvx markitdown https://example.com
```

Fetches the URL and extracts readable content as Markdown. Works well on JS-heavy sites where simpler extractors fail.

## Convert Local Files

```bash
uvx markitdown document.pdf
uvx markitdown presentation.pptx
uvx markitdown spreadsheet.xlsx
uvx markitdown file.docx
```

### Supported Formats

- **PDF** — `uvx --with 'markitdown[pdf]' markitdown file.pdf`
- **Word (.docx)** — `uvx --with 'markitdown[docx]' markitdown file.docx`
- **PowerPoint (.pptx)** — `uvx --with 'markitdown[pptx]' markitdown file.pptx`
- **Excel (.xlsx)** — `uvx --with 'markitdown[xlsx]' markitdown file.xlsx`
- **Excel (.xls)** — `uvx --with 'markitdown[xls]' markitdown file.xls`
- **HTML** — supported by default
- **Images** — EXIF metadata extraction (add OCR via plugin)
- **Audio** — `uvx --with 'markitdown[audio-transcription]' markitdown file.mp3`
- **YouTube URLs** — see YouTube section below
- **CSV, JSON, XML** — supported by default
- **ZIP files** — iterates over contents
- **EPub** — supported by default

Use `markitdown[all]` to enable all format support:

```bash
uvx --with 'markitdown[all]' markitdown file.pdf
```

## Save Output to File

```bash
uvx markitdown input.pdf > output.md
uvx markitdown input.pdf -o output.md
```

## Pipe Content

```bash
cat file.pdf | uvx markitdown
```

## YouTube Transcripts

`markitdown` YouTube support can be unreliable. Use the `youtube-transcript-api` directly instead:

```bash
uvx --with 'youtube-transcript-api' python -c "
from youtube_transcript_api import YouTubeTranscriptApi
ytt_api = YouTubeTranscriptApi()
transcript = ytt_api.fetch('VIDEO_ID')
for entry in transcript:
    print(entry.text)
"
```

Replace `VIDEO_ID` with the ID from the URL (e.g., `2JjKn7uhKqY` from `https://www.youtube.com/watch?v=2JjKn7uhKqY`).

## When to Use

- Reading web pages (especially JS-heavy sites that simpler extractors fail on)
- Converting PDFs, Office documents, or other files to Markdown for analysis
- Extracting text from images, audio, or YouTube videos
- Any task where you need file content as clean Markdown

## When NOT to Use

- **GitHub URLs** — never use markitdown on `github.com` blob URLs. Convert to a raw URL and fetch directly instead:
  - Change `https://github.com/user/repo/blob/branch/file.ts`
  - To `https://raw.githubusercontent.com/user/repo/branch/file.ts`
  - Then use `curl` or the `Read` tool on the raw URL
- **Plain text/source files reachable via a raw URL** — fetch directly, no conversion needed
