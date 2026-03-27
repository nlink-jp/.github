# nlink-jp

A collection of CLI tools and libraries.

## Projects

### cli-series — Service CLI clients

Pipe-friendly, Unix-composable CLI clients for external services.
Authenticate as the human user, not a bot.

| Tool | Service | Description |
|------|---------|-------------|
| [confl-cli](https://github.com/nlink-jp/confl-cli) | Confluence | Confluence Cloud CLI — list, search, read, export |
| [scli](https://github.com/nlink-jp/scli) | Slack | Terminal Slack client — channels, messages, DMs, search |
| [splunk-cli](https://github.com/nlink-jp/splunk-cli) | Splunk | CLI client for the Splunk REST API — run searches, poll jobs, fetch results |

### chatops-series — ChatOps workflow tools

Pipe-friendly Slack tools for ChatOps automation and monitoring.

| Tool | Description |
|------|-------------|
| [md-to-slack](https://github.com/nlink-jp/md-to-slack) | Markdown → Slack Block Kit JSON filter — pipe into `scat` to post formatted messages |
| [scat](https://github.com/nlink-jp/scat) | General-purpose content poster — send text, files, and Block Kit messages to Slack from stdin or files |
| [slack-router](https://github.com/nlink-jp/slack-router) | Slack Slash Command daemon — routes commands to local shell scripts via Socket Mode |
| [stail](https://github.com/nlink-jp/stail) | Read-only Slack CLI — stream channel messages in real time (`tail -f`) or export history to JSON |

### cybersecurity-series — Cybersecurity workflow tools

AI-augmented tools for threat intelligence, product risk assessment, and incident response analysis.

| Tool | Description |
|------|-------------|
| [ai-ir](https://github.com/nlink-jp/ai-ir) | AI-powered incident response — analyzes Slack IR exports to generate summaries, activity reports, and reusable tactics |
| [ioc-collector](https://github.com/nlink-jp/ioc-collector) | Research security incidents from URLs or CVE IDs — extracts IoCs into Markdown and STIX 2.1 bundles |
| [product-research](https://github.com/nlink-jp/product-research) | Research products and services — outputs ToS, privacy, and data security analysis as structured reports |

### util-series — General-purpose data utilities

Pipe-friendly tools for data transformation and processing.

| Tool | Lang | Description |
|------|------|-------------|
| [csv-to-json](https://github.com/nlink-jp/csv-to-json) | Go | Convert CSV data to a JSON array |
| [json-filter](https://github.com/nlink-jp/json-filter) | Go | Extract, validate, prettify, and repair JSON from arbitrary text streams |
| [json-to-sqlite](https://github.com/nlink-jp/json-to-sqlite) | Go | Load JSON data into SQLite with automatic schema inference |
| [json-to-table](https://github.com/nlink-jp/json-to-table) | Go | Format a JSON array into text, Markdown, HTML, CSV, PNG, or Slack Block Kit tables |
| [lookup](https://github.com/nlink-jp/lookup) | Go | Enrich JSON/JSONL streams by matching fields against CSV/JSON data sources |
| [markdown-viewer](https://github.com/nlink-jp/markdown-viewer) | Go | Single-binary local Markdown viewer — renders GFM, Mermaid, and syntax-highlighted code in the browser |
| [pptx-to-markdown](https://github.com/nlink-jp/pptx-to-markdown) | Python | Convert `.pptx` presentations to structured Markdown for LLM analysis |
| [rex](https://github.com/nlink-jp/rex) | Go | Extract fields from text using named regex capture groups — outputs JSON |
| [sdate](https://github.com/nlink-jp/sdate) | Go | Calculate timestamps using Splunk-like relative time modifiers (e.g., `-1d@d`) |

### lite-series — Lightweight LLM and pipeline tools

Small, local-first CLI tools for LLM interaction, retrieval, classification, and email parsing.

| Tool | Description |
|------|-------------|
| [lite-eml](https://github.com/nlink-jp/lite-eml) | EML parser — extracts headers and body from .eml files as structured JSONL |
| [lite-llm](https://github.com/nlink-jp/lite-llm) | CLI client for OpenAI-compatible LLM APIs — streaming, batch, structured output |
| [lite-msg](https://github.com/nlink-jp/lite-msg) | Outlook MSG parser — extracts headers and body from .msg files as structured JSONL |
| [lite-rag](https://github.com/nlink-jp/lite-rag) | RAG CLI for Markdown docs using DuckDB — index and query local knowledge bases |
| [lite-switch](https://github.com/nlink-jp/lite-switch) | Natural language classifier for shell pipelines — routes stdin text to a matching tag via LLM |
