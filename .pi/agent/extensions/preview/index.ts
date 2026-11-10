import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { writeFileSync, unlinkSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { exec } from "node:child_process";
import { marked } from "marked";
import hljs from "highlight.js";
import markedFootnote from "marked-footnote";

marked.use(markedFootnote());

function escapeHtml(value: string) {
  return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

const CALLOUT_ICONS: Record<string, string> = {
  note: "ℹ️",
  tip: "💡",
  important: "❗",
  warning: "⚠️",
  caution: "🛑",
};

const renderer = new marked.Renderer();

renderer.code = ({ text, lang, escaped }) => {
  const language = (lang || "").trim().split(/\s+/)[0];
  const escapedCode = escaped ? text : escapeHtml(text);

  if (language === "mermaid") {
    return `<div class="mermaid">${escapedCode}</div>\n`;
  }

  const grammar = language ? hljs.getLanguage(language) : undefined;
  let codeHtml = `<code>${escapedCode}</code>`;
  if (grammar) {
    try {
      codeHtml = `<code class="hljs language-${escapeHtml(language)}">${hljs.highlight(text, { language }).value}</code>`;
    } catch {}
  }

  const label = grammar?.name ?? (language || "Plain text");
  return `<div class="code-block"><div class="code-toolbar"><span>${escapeHtml(label)}</span><button class="code-copy" type="button">Copy</button></div><pre>${codeHtml}</pre></div>\n`;
};

// GitHub alerts (> [!NOTE]) and emoji-led quotes (> 💡 ...) become Notion callouts
renderer.blockquote = function ({ tokens }) {
  const body = this.parser.parse(tokens);
  const alert = body.match(/^<p>\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*/i);
  const emoji = body.match(/^<p>(\p{Extended_Pictographic}\uFE0F?)\s*/u);

  if (alert) {
    const kind = alert[1].toLowerCase();
    return `<div class="callout callout-${kind}"><div class="callout-icon">${CALLOUT_ICONS[kind]}</div><div class="callout-body"><p>${body.slice(alert[0].length)}</div></div>\n`;
  }
  if (emoji) {
    return `<div class="callout"><div class="callout-icon">${emoji[1]}</div><div class="callout-body"><p>${body.slice(emoji[0].length)}</div></div>\n`;
  }
  return `<blockquote>\n${body}</blockquote>\n`;
};

const HTML_TEMPLATE = (body: string) => `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Preview</title>
<script>
(() => {
  const root = document.documentElement;
  const media = matchMedia('(prefers-color-scheme: dark)');
  const read = (key, fallback) => {
    try { return localStorage.getItem('pi-preview:' + key) || fallback; } catch { return fallback; }
  };
  root.dataset.appearance = read('appearance', 'system');
  root.dataset.font = read('font', 'default');
  root.dataset.smallText = read('smallText', 'false');
  root.dataset.fullWidth = read('fullWidth', 'false');
  const applyTheme = () => {
    root.dataset.theme = root.dataset.appearance === 'system' ? (media.matches ? 'dark' : 'light') : root.dataset.appearance;
    window.dispatchEvent(new Event('pi-theme'));
  };
  media.addEventListener('change', applyTheme);
  applyTheme();
  window.piPreview = { applyTheme };
})();
</script>
<style>
:root {
  color-scheme: light;
  --font-default: ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI Variable Display", "Segoe UI", Helvetica, "Apple Color Emoji", Arial, sans-serif, "Segoe UI Emoji", "Segoe UI Symbol";
  --font-serif: Lyon-Text, Georgia, ui-serif, serif;
  --font-mono: iawriter-mono, Nitti, Menlo, Courier, monospace;
  --font-code: "SFMono-Regular", Menlo, Consolas, "PT Mono", "Liberation Mono", Courier, monospace;
  --font: var(--font-default);
  --gutter: max(24px, min(96px, 8vw));

  /* Values measured from the Notion web app */
  --bg: #ffffff;
  --text: rgb(44, 44, 43);
  --text-muted: rgba(44, 44, 43, 0.5);
  --border: rgba(28, 19, 1, 0.11);
  --hover: rgba(28, 19, 1, 0.06);
  --accent: rgb(39, 131, 222);
  --selection: rgba(35, 131, 226, 0.28);
  --code-bg: rgba(66, 35, 3, 0.03);
  --inline-code-bg: rgba(33, 27, 23, 0.05);
  --inline-code-text: rgb(207, 81, 72);
  --table-border: rgb(230, 229, 227);
  --menu-bg: #ffffff;
  --menu-shadow: rgba(15, 15, 15, 0.05) 0 0 0 1px, rgba(15, 15, 15, 0.1) 0 3px 6px, rgba(15, 15, 15, 0.2) 0 9px 24px;
  --segment-active: #ffffff;
  --switch-off: rgba(135, 131, 120, 0.3);
  --highlight: rgb(251, 243, 219);
  --diagram-label-bg: rgb(249, 248, 247);

  --callout-default: rgb(249, 248, 247);
  --callout-note: rgb(241, 248, 251);
  --callout-tip: rgb(244, 248, 243);
  --callout-important: rgb(249, 246, 251);
  --callout-warning: rgb(252, 249, 240);
  --callout-caution: rgb(253, 245, 244);

  --syn-comment: rgb(112, 128, 144);
  --syn-keyword: rgb(0, 119, 170);
  --syn-string: rgb(102, 153, 0);
  --syn-number: rgb(153, 0, 85);
  --syn-function: rgb(221, 74, 104);
  --syn-type: rgb(221, 74, 104);
  --syn-property: rgb(153, 0, 85);
  --syn-tag: rgb(153, 0, 85);
  --syn-variable: rgb(238, 153, 0);
  --syn-operator: rgb(154, 110, 58);
  --syn-builtin: rgb(102, 153, 0);
  --syn-punctuation: rgb(153, 153, 153);
}

:root[data-theme="dark"] {
  color-scheme: dark;
  --bg: rgb(25, 25, 25);
  --text: rgb(240, 239, 237);
  --text-muted: rgba(240, 239, 237, 0.5);
  --border: rgba(255, 255, 235, 0.1);
  --hover: rgba(255, 255, 235, 0.06);
  --code-bg: rgba(252, 252, 252, 0.03);
  --inline-code-bg: rgba(255, 255, 255, 0.055);
  --table-border: rgb(56, 56, 54);
  --menu-bg: rgb(37, 37, 37);
  --menu-shadow: rgba(15, 15, 15, 0.1) 0 0 0 1px, rgba(15, 15, 15, 0.2) 0 3px 6px, rgba(15, 15, 15, 0.4) 0 9px 24px;
  --segment-active: rgba(255, 255, 255, 0.1);
  --switch-off: rgba(202, 204, 206, 0.3);
  --highlight: rgb(86, 67, 40);
  --diagram-label-bg: rgb(32, 32, 32);

  --callout-default: rgb(56, 56, 54);
  --callout-note: rgb(31, 44, 54);
  --callout-tip: rgb(33, 46, 38);
  --callout-important: rgb(45, 37, 54);
  --callout-warning: rgb(54, 47, 33);
  --callout-caution: rgb(58, 37, 35);

  --syn-comment: rgb(153, 128, 102);
  --syn-keyword: rgb(102, 162, 204);
  --syn-string: rgb(189, 224, 82);
  --syn-number: rgb(209, 148, 158);
  --syn-function: rgb(236, 236, 147);
  --syn-type: rgb(236, 236, 147);
  --syn-property: rgb(209, 148, 158);
  --syn-tag: rgb(209, 148, 158);
  --syn-variable: rgb(245, 184, 61);
  --syn-operator: rgb(245, 184, 61);
  --syn-builtin: rgb(189, 224, 82);
  --syn-punctuation: rgb(240, 239, 237);
}

:root[data-font="serif"] { --font: var(--font-serif); }
:root[data-font="mono"] { --font: var(--font-mono); }

* { box-sizing: border-box; }
::selection { background: var(--selection); }

html { background: var(--bg); }

body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font-family: var(--font);
  font-size: 16px;
  line-height: 1.5;
  -webkit-font-smoothing: antialiased;
}

:root[data-small-text="true"] main { font-size: 14px; }

button { font: inherit; color: inherit; }

/* Top bar */
.topbar {
  position: sticky;
  top: 0;
  z-index: 10;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 45px;
  padding: 0 12px;
  background: var(--bg);
  font-family: var(--font-default);
  font-size: 14px;
}

.breadcrumb {
  display: flex;
  align-items: center;
  gap: 6px;
  min-width: 0;
  padding: 2px 6px;
  border-radius: 4px;
}

.breadcrumb-title { overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
.breadcrumb-separator { color: var(--text-muted); }

.topbar-actions { display: flex; gap: 2px; }

.icon-button {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  padding: 0;
  border: 0;
  border-radius: 6px;
  background: transparent;
  color: var(--text);
  cursor: pointer;
}

.icon-button:hover { background: var(--hover); }
.icon-button svg { width: 18px; height: 18px; fill: currentColor; }
:root[data-theme="dark"] .icon-moon,
:root:not([data-theme="dark"]) .icon-sun { display: none; }

.menu {
  position: absolute;
  top: 42px;
  right: 12px;
  width: 248px;
  padding: 6px;
  border-radius: 10px;
  background: var(--menu-bg);
  box-shadow: var(--menu-shadow);
}

.menu-label {
  padding: 6px 8px 4px;
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 500;
}

.font-options {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 4px;
  padding: 0 2px 4px;
}

.font-options button {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 6px 0 4px;
  border: 0;
  border-radius: 6px;
  background: transparent;
  color: var(--text-muted);
  font-size: 12px;
  cursor: pointer;
}

.font-options button:hover { background: var(--hover); }
.font-options .ag { color: var(--text); font-size: 24px; line-height: 1.3; }
.font-options button[aria-pressed="true"],
.font-options button[aria-pressed="true"] .ag { color: var(--accent); }
.font-options [data-value="serif"] .ag { font-family: var(--font-serif); }
.font-options [data-value="mono"] .ag { font-family: var(--font-mono); }

.menu-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 6px 8px;
  border: 0;
  border-radius: 6px;
  background: transparent;
  text-align: left;
  cursor: pointer;
}

.menu-row:hover { background: var(--hover); }

.switch {
  position: relative;
  width: 26px;
  height: 14px;
  border-radius: 44px;
  background: var(--switch-off);
  transition: background 200ms ease;
}

.switch::after {
  content: "";
  position: absolute;
  top: 2px;
  left: 2px;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #fff;
  transition: transform 200ms ease;
}

.menu-row[aria-checked="true"] .switch { background: var(--accent); }
.menu-row[aria-checked="true"] .switch::after { transform: translateX(12px); }

.menu-divider { height: 1px; margin: 4px 0; background: var(--border); }

.segmented {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  margin: 0 4px 4px;
  padding: 2px;
  border-radius: 6px;
  background: var(--hover);
}

.segmented button {
  padding: 3px 4px;
  border: 0;
  border-radius: 4px;
  background: transparent;
  color: var(--text-muted);
  font-size: 13px;
  cursor: pointer;
}

.segmented button[aria-pressed="true"] {
  background: var(--segment-active);
  color: var(--text);
  box-shadow: rgba(15, 15, 15, 0.1) 0 1px 2px;
}

/* Page: spacing mirrors Notion's block wrappers (6px) plus text padding (2px) */
main {
  width: 100%;
  max-width: calc(708px + 2 * var(--gutter));
  margin: 0 auto;
  padding: 100px var(--gutter) 30vh;
  /* Flex stops margin collapsing, so block gaps add up like Notion's padded wrappers */
  display: flex;
  flex-direction: column;
  word-wrap: break-word;
}

:root[data-full-width="true"] main { max-width: none; }

main > h1:first-child {
  margin: 0 0 16px;
  padding: 0 2px;
  font-size: 2.5em;
  font-weight: 700;
  line-height: 1.2;
}

h1, h2, h3, h4, h5, h6 { margin: 0; padding: 0 2px 8px; font-weight: 600; }
h1 { padding-top: 32px; font-size: 1.875em; line-height: 1.3; }
h2 { padding-top: 28px; font-size: 1.5em; line-height: 1.3; }
h3 { padding-top: 24px; font-size: 1.25em; line-height: 1.3; }
h4, h5, h6 { padding-top: 20px; font-size: 1.125em; line-height: 1.3; }

p { margin: 0; padding: 8px 2px; }
p:empty { display: none; }
strong { font-weight: 600; }

a {
  color: inherit;
  text-decoration: underline;
  text-decoration-color: color-mix(in srgb, currentColor 40%, transparent);
  text-decoration-thickness: 1px;
  text-underline-offset: 3px;
}

a:hover { text-decoration-color: currentColor; }

main > * { min-width: 0; }

ul, ol { margin: 0; padding: 5px 0 5px 26px; }
:is(ul, ol) + :is(ul, ol) { margin-top: -10px; }
li { padding: 3px 0 3px 4px; }
li > p { margin: 0; padding: 0; }
li > * + * { margin-top: 10px; }
li > ul, li > ol { margin-top: 0; padding-top: 3px; padding-bottom: 0; }
li > :is(ul, ol) + * { margin-top: 0; }
li:has(> ul, > ol) { padding-bottom: 0; }
ul ul { list-style-type: circle; }
ul ul ul { list-style-type: square; }
ol ol { list-style-type: lower-alpha; }
ol ol ol { list-style-type: lower-roman; }

li:has(> input[type="checkbox"]),
li:has(> p > input[type="checkbox"]) { list-style: none; margin-left: -24px; padding-left: 2px; }

input[type="checkbox"] {
  appearance: none;
  position: relative;
  top: 2px;
  width: 16px;
  height: 16px;
  margin: 0 6px 0 2px;
  border: 1.5px solid currentColor;
  border-radius: 2px;
}

input[type="checkbox"]:checked {
  border-color: var(--accent);
  background: var(--accent) url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 14 14'%3E%3Cpath d='M5.5 12 14 3.5 12.5 2l-7 7-4-4L0 6.5z' fill='white'/%3E%3C/svg%3E") center / 10px no-repeat;
}

li:has(> input:checked),
li:has(> p > input:checked) { color: var(--text-muted); text-decoration: line-through; text-decoration-color: var(--text-muted); }

blockquote {
  margin: 8px 0;
  padding: 0 14px 0 20px;
  border-left: 3px solid currentColor;
}

blockquote p { padding: 0 2px; }
blockquote p + p { padding-top: 8px; }
blockquote blockquote { margin: 8px 0 0; }

.callout {
  display: flex;
  margin: 8px 0;
  padding: 12px;
  border-radius: 10px;
  background: var(--callout-default);
}

.callout-note { background: var(--callout-note); }
.callout-tip { background: var(--callout-tip); }
.callout-important { background: var(--callout-important); }
.callout-warning { background: var(--callout-warning); }
.callout-caution { background: var(--callout-caution); }

.callout-icon { flex: 0 0 24px; height: 24px; font-size: 1.15em; line-height: 24px; text-align: center; }
.callout-body { flex: 1; min-width: 0; margin-left: 8px; }
.callout-body p { padding: 0 2px; }
.callout-body p + p { padding-top: 8px; }

hr { margin: 6px 2px; border: 0; border-top: 1px solid var(--border); }

code {
  padding: 0.2em 0.4em;
  border-radius: 4px;
  background: var(--inline-code-bg);
  color: var(--inline-code-text);
  font-family: var(--font-code);
  font-size: 85%;
  line-height: normal;
}

.code-block {
  position: relative;
  margin: 8px 0;
  border-radius: 10px;
  background: var(--code-bg);
}

.code-toolbar {
  position: absolute;
  top: 6px;
  left: 12px;
  right: 8px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: var(--text-muted);
  font-family: var(--font-default);
  font-size: 12px;
  opacity: 0;
  transition: opacity 100ms ease-in;
}

.code-block:hover .code-toolbar { opacity: 1; }

.code-copy {
  padding: 2px 6px;
  border: 0;
  border-radius: 4px;
  background: transparent;
  color: var(--text-muted);
  font-size: 12px;
  cursor: pointer;
}

.code-copy:hover { background: var(--hover); }

pre {
  overflow: auto;
  margin: 0;
  padding: 36px 22px;
  tab-size: 2;
}

pre code {
  display: block;
  padding: 0;
  border-radius: 0;
  background: none;
  color: var(--text);
  line-height: 1.5;
  white-space: pre;
}

.hljs-comment, .hljs-quote { color: var(--syn-comment); }
.hljs-keyword, .hljs-selector-tag, .hljs-doctag, .hljs-literal { color: var(--syn-keyword); }
.hljs-string, .hljs-regexp, .hljs-addition { color: var(--syn-string); }
.hljs-number, .hljs-symbol, .hljs-bullet { color: var(--syn-number); }
.hljs-title, .hljs-section { color: var(--syn-function); }
.hljs-title.class_, .hljs-type { color: var(--syn-type); }
.hljs-attr, .hljs-attribute, .hljs-property { color: var(--syn-property); }
.hljs-name, .hljs-tag, .hljs-deletion, .hljs-selector-id, .hljs-selector-class { color: var(--syn-tag); }
.hljs-variable, .hljs-template-variable { color: var(--syn-variable); }
.hljs-operator { color: var(--syn-operator); }
.hljs-built_in { color: var(--syn-builtin); }
.hljs-meta, .hljs-punctuation { color: var(--syn-punctuation); }
.hljs-emphasis { font-style: italic; }
.hljs-strong { font-weight: 600; }

table {
  display: block;
  overflow-x: auto;
  max-width: 100%;
  margin: 8px 0 8px 8px;
  border-collapse: collapse;
  font-size: 14px;
  line-height: 20px;
}

th, td {
  min-width: 120px;
  padding: 7px 9px;
  border: 1px solid var(--table-border);
  text-align: left;
  vertical-align: top;
}

th { background: var(--code-bg); font-weight: 500; }

img { display: block; max-width: 100%; height: auto; margin: 8px 0; border-radius: 2px; }

.mermaid {
  overflow: auto;
  margin: 8px 0;
  padding: 24px;
  border-radius: 10px;
  background: var(--code-bg);
  text-align: center;
}

.mermaid svg { max-width: 100%; height: auto; }

mark { padding: 0 2px; border-radius: 3px; background: var(--highlight); color: inherit; }

kbd {
  padding: 1px 5px;
  border: 1px solid var(--border);
  border-bottom-width: 2px;
  border-radius: 4px;
  background: var(--code-bg);
  font-family: var(--font-default);
  font-size: 0.8em;
}

details { margin: 0; padding: 8px 2px; }
details > :not(summary) { margin-left: 26px; }

summary {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-left: -2px;
  list-style: none;
  cursor: pointer;
}

summary::-webkit-details-marker { display: none; }

summary::before {
  content: "";
  flex: 0 0 22px;
  height: 22px;
  border-radius: 4px;
  background: currentColor;
  mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 22 22'%3E%3Cpath d='M8 6.5v9l7-4.5z'/%3E%3C/svg%3E") center / 22px no-repeat;
  transition: transform 150ms ease;
}

details[open] > summary::before { transform: rotate(90deg); }

sup, sub { line-height: 0; }

.footnotes {
  margin-top: 40px;
  padding-top: 12px;
  border-top: 1px solid var(--border);
  color: var(--text-muted);
  font-size: 0.875em;
}

.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); }
[data-footnote-ref]::before { content: "["; }
[data-footnote-ref]::after { content: "]"; }
[data-footnote-backref] { text-decoration: none; }
</style>
</head>
<body>
<header class="topbar">
  <div class="breadcrumb">
    <span>π</span>
    <span class="breadcrumb-separator">/</span>
    <span class="breadcrumb-title">Preview</span>
  </div>
  <div class="topbar-actions">
    <button class="icon-button" type="button" data-action="toggle-theme" title="Toggle dark mode (⌘⇧L)">
      <svg class="icon-moon" viewBox="0 0 20 20"><path d="M16.9 12.6A7 7 0 0 1 7.4 3.1a7 7 0 1 0 9.5 9.5Z"/></svg>
      <svg class="icon-sun" viewBox="0 0 20 20"><circle cx="10" cy="10" r="3.6"/><path d="M9.2 1.5h1.6v3H9.2zM9.2 15.5h1.6v3H9.2zM1.5 9.2h3v1.6h-3zM15.5 9.2h3v1.6h-3zM3.4 4.5l1.1-1.1 2.1 2.1-1.1 1.1zM13.4 14.5l1.1-1.1 2.1 2.1-1.1 1.1zM3.4 15.5l2.1-2.1 1.1 1.1-2.1 2.1zM13.4 5.5l2.1-2.1 1.1 1.1-2.1 2.1z"/></svg>
    </button>
    <button class="icon-button" type="button" data-action="toggle-menu" title="Style, customize, and more">
      <svg viewBox="0 0 20 20"><circle cx="4" cy="10" r="1.6"/><circle cx="10" cy="10" r="1.6"/><circle cx="16" cy="10" r="1.6"/></svg>
    </button>
  </div>
  <div class="menu" hidden>
    <div class="menu-label">Style</div>
    <div class="font-options">
      <button type="button" data-setting="font" data-value="default"><span class="ag">Ag</span>Default</button>
      <button type="button" data-setting="font" data-value="serif"><span class="ag">Ag</span>Serif</button>
      <button type="button" data-setting="font" data-value="mono"><span class="ag">Ag</span>Mono</button>
    </div>
    <div class="menu-divider"></div>
    <button class="menu-row" type="button" data-toggle="smallText">Small text<span class="switch"></span></button>
    <button class="menu-row" type="button" data-toggle="fullWidth">Full width<span class="switch"></span></button>
    <div class="menu-divider"></div>
    <div class="menu-label">Appearance</div>
    <div class="segmented">
      <button type="button" data-setting="appearance" data-value="system">System</button>
      <button type="button" data-setting="appearance" data-value="light">Light</button>
      <button type="button" data-setting="appearance" data-value="dark">Dark</button>
    </div>
  </div>
</header>
<main>${body}</main>
${body.includes('class="mermaid"') ? '<script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>' : ""}
<script>
(() => {
  const root = document.documentElement;
  const menu = document.querySelector('.menu');

  const title = document.querySelector('main > h1:first-child')?.textContent.trim();
  if (title) {
    document.title = title;
    document.querySelector('.breadcrumb-title').textContent = title;
  }

  const syncControls = () => {
    for (const button of document.querySelectorAll('[data-setting]')) {
      button.setAttribute('aria-pressed', String(root.dataset[button.dataset.setting] === button.dataset.value));
    }
    for (const row of document.querySelectorAll('[data-toggle]')) {
      row.setAttribute('aria-checked', root.dataset[row.dataset.toggle]);
    }
  };

  const updateSetting = (key, value) => {
    root.dataset[key] = value;
    try { localStorage.setItem('pi-preview:' + key, value); } catch {}
    if (key === 'appearance') window.piPreview.applyTheme();
    syncControls();
  };

  const toggleTheme = () => updateSetting('appearance', root.dataset.theme === 'dark' ? 'light' : 'dark');

  document.addEventListener('click', (event) => {
    const target = event.target.closest('button');
    if (!menu.contains(event.target) && target?.dataset.action !== 'toggle-menu') menu.hidden = true;
    if (!target) return;
    if (target.dataset.action === 'toggle-menu') menu.hidden = !menu.hidden;
    if (target.dataset.action === 'toggle-theme') toggleTheme();
    if (target.dataset.setting) updateSetting(target.dataset.setting, target.dataset.value);
    if (target.dataset.toggle) updateSetting(target.dataset.toggle, String(root.dataset[target.dataset.toggle] !== 'true'));
    if (target.classList.contains('code-copy')) {
      const code = target.closest('.code-block').querySelector('pre').innerText;
      navigator.clipboard.writeText(code).then(
        () => { target.textContent = 'Copied!'; },
        () => { target.textContent = 'Failed'; },
      );
      setTimeout(() => { target.textContent = 'Copy'; }, 1500);
    }
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') menu.hidden = true;
    if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key.toLowerCase() === 'l') {
      event.preventDefault();
      toggleTheme();
    }
  });

  syncControls();

  const mermaidBlocks = [...document.querySelectorAll('.mermaid')];
  if (!window.mermaid || mermaidBlocks.length === 0) return;
  for (const block of mermaidBlocks) block.dataset.source = block.textContent;

  const renderMermaid = () => {
    for (const block of mermaidBlocks) {
      block.removeAttribute('data-processed');
      block.textContent = block.dataset.source;
    }
    window.mermaid.initialize({
      startOnLoad: false,
      theme: root.dataset.theme === 'dark' ? 'dark' : 'neutral',
      securityLevel: 'strict',
      fontFamily: getComputedStyle(document.body).fontFamily,
      themeVariables: { edgeLabelBackground: getComputedStyle(root).getPropertyValue('--diagram-label-bg').trim() },
    });
    window.mermaid.run({ nodes: mermaidBlocks });
  };

  window.addEventListener('pi-theme', renderMermaid);
  renderMermaid();
})();
</script>
</body>
</html>`;

export async function renderPreviewHtml(markdown: string) {
  const html = await marked.parse(markdown, { renderer });
  // Force text presentation so the footnote back-arrow is not drawn as an emoji
  return HTML_TEMPLATE(html.replaceAll("↩</a>", "↩\uFE0E</a>"));
}

const CLEANUP_DELAY_MS = 60_000;

export default function (pi: ExtensionAPI) {
  pi.registerCommand("preview", {
    description: "Preview last assistant message as HTML in the browser",
    handler: async (_args, ctx) => {
      const entries = ctx.sessionManager.getBranch();

      let lastAssistantText = "";
      for (let i = entries.length - 1; i >= 0; i--) {
        const entry = entries[i];
        if (entry.type === "message" && entry.message.role === "assistant") {
          const content = entry.message.content;
          if (typeof content === "string") {
            lastAssistantText = content;
          } else if (Array.isArray(content)) {
            lastAssistantText = content
              .filter((block) => block.type === "text")
              .map((block) => block.text)
              .join("\n");
          }
          break;
        }
      }

      if (!lastAssistantText) {
        ctx.ui.notify("No assistant message found", "warning");
        return;
      }

      const html = await renderPreviewHtml(lastAssistantText);
      const filepath = join(tmpdir(), `pi-preview-${Date.now()}.html`);
      writeFileSync(filepath, html, "utf-8");
      exec(`open "${filepath}"`);
      ctx.ui.notify("Opened preview in browser", "info");

      setTimeout(() => {
        try {
          unlinkSync(filepath);
        } catch {}
      }, CLEANUP_DELAY_MS);
    },
  });
}
