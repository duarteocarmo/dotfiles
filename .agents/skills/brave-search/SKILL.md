---
name: brave-search
description: Web search and source discovery through the Brave Search API. Use for current information or finding relevant pages. For a known public URL, try curl first. Use agent-browser only when interaction or a real browser is required, and use markitdown when conversion to Markdown is the goal.
---

# Brave Search

Web search and source discovery using the official Brave Search API. No browser required.

## Setup

Requires a Brave Search API account with a free subscription. A credit card is required to create the free subscription (you won't be charged).

1. Create an account at https://api-dashboard.search.brave.com/register
2. Create a "Free AI" subscription
3. Create an API key for the subscription
4. Add to your shell profile (`~/.profile` or `~/.zprofile` for zsh):
   ```bash
   export BRAVE_API_KEY="your-api-key-here"
   ```
5. Install dependencies (run once):
   ```bash
   cd {baseDir}
   npm install
   ```

## Search

```bash
{baseDir}/search.js "query"                         # Basic search (5 results)
{baseDir}/search.js "query" -n 10                   # More results (max 20)
{baseDir}/search.js "query" --content               # Include page content as markdown
{baseDir}/search.js "query" --freshness pw          # Results from last week
{baseDir}/search.js "query" --freshness 2024-01-01to2024-06-30  # Date range
{baseDir}/search.js "query" --country DE            # Results from Germany
{baseDir}/search.js "query" -n 3 --content          # Combined options
```

### Options

- `-n <num>` - Number of results (default: 5, max: 20)
- `--content` - Fetch and include page content as markdown
- `--country <code>` - Two-letter country code (default: US)
- `--freshness <period>` - Filter by time:
  - `pd` - Past day (24 hours)
  - `pw` - Past week
  - `pm` - Past month
  - `py` - Past year
  - `YYYY-MM-DDtoYYYY-MM-DD` - Custom date range

## Known URLs

For a known public URL, try `curl -L` first. Use the content helper only when curl returns noisy HTML and readable Markdown would help:

```bash
{baseDir}/content.js https://example.com/article
```

## Output Format

```
--- Result 1 ---
Title: Page Title
Link: https://example.com/page
Age: 2 days ago
Snippet: Description from search results
Content: (if --content flag used)
  Markdown content extracted from the page...

--- Result 2 ---
...
```

## When to Use

- Searching for documentation or API references
- Looking up facts or current information
- Finding and comparing relevant sources
- Any task requiring web search without interactive browsing
