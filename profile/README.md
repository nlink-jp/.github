# nlink-jp

A collection of CLI tools and libraries.

## Projects

### cli-series — Service CLI clients

Pipe-friendly, Unix-composable CLI clients for external services.
Authenticate as the human user, not a bot.

| Tool | Service | Description |
|------|---------|-------------|
| [scli](https://github.com/nlink-jp/scli) | Slack | Terminal Slack client — channels, messages, DMs, search |
| [md-to-slack](https://github.com/nlink-jp/md-to-slack) | Slack | Markdown → Slack Block Kit JSON filter |
| [splunk-cli](https://github.com/nlink-jp/splunk-cli) | Splunk | CLI client for the Splunk REST API — run searches, poll jobs, fetch results |
| [confl-cli](https://github.com/nlink-jp/confl-cli) | Confluence | Confluence Cloud CLI — list, search, read, export |

### chatops-series — ChatOps workflow tools

Pipe-friendly Slack tools for ChatOps automation and monitoring.

| Tool | Description |
|------|-------------|
| [scat](https://github.com/nlink-jp/scat) | General-purpose content poster — send text, files, and Block Kit messages to Slack from stdin or files |
| [stail](https://github.com/nlink-jp/stail) | Read-only Slack CLI — stream channel messages in real time (`tail -f`) or export history to JSON |
| [slack-router](https://github.com/nlink-jp/slack-router) | Slack Slash Command daemon — routes commands to local shell scripts via Socket Mode |

### cybersecurity-series — Cybersecurity workflow tools

AI-augmented tools for threat intelligence, product risk assessment, and incident response analysis.

| Tool | Description |
|------|-------------|
| [ioc-collector](https://github.com/nlink-jp/ioc-collector) | Research security incidents from URLs or CVE IDs — extracts IoCs into Markdown and STIX 2.1 bundles |
| [product-research](https://github.com/nlink-jp/product-research) | Research products and services — outputs ToS, privacy, and data security analysis as structured reports |
| [ai-ir](https://github.com/nlink-jp/ai-ir) | AI-powered incident response — analyzes Slack IR exports to generate summaries, activity reports, and reusable tactics |

### util-series — General-purpose data utilities

Pipe-friendly tools for data transformation and processing.

| Tool | Lang | Description |
|------|------|-------------|
| [json-to-table](https://github.com/nlink-jp/json-to-table) | Go | Format a JSON array into text, Markdown, HTML, CSV, PNG, or Slack Block Kit tables |
| [rex](https://github.com/nlink-jp/rex) | Go | Extract fields from text using named regex capture groups — outputs JSON |
| [sdate](https://github.com/nlink-jp/sdate) | Go | Calculate timestamps using Splunk-like relative time modifiers (e.g., `-1d@d`) |
| [csv-to-json](https://github.com/nlink-jp/csv-to-json) | Go | Convert CSV data to a JSON array |
| [json-to-sqlite](https://github.com/nlink-jp/json-to-sqlite) | Go | Load JSON data into SQLite with automatic schema inference |
| [lookup](https://github.com/nlink-jp/lookup) | Go | Enrich JSON/JSONL streams by matching fields against CSV/JSON data sources |
| [pptx-to-markdown](https://github.com/nlink-jp/pptx-to-markdown) | Python | Convert `.pptx` presentations to structured Markdown for LLM analysis |

### lite-series — Lightweight local tools

Small, dependency-light tools for local file and data processing.

| Tool | Description |
|------|-------------|
| [lite-eml](https://github.com/nlink-jp/lite-eml) | Parse and extract content from .eml files |
| [lite-msg](https://github.com/nlink-jp/lite-msg) | Parse and extract content from .msg files |
| [lite-switch](https://github.com/nlink-jp/lite-switch) | Natural language classifier for shell pipelines via LLM |
| [lite-rag](https://github.com/nlink-jp/lite-rag) | CLI-based RAG tool for Markdown documents using a local LLM |
| [lite-llm](https://github.com/nlink-jp/lite-llm) | Lightweight CLI for OpenAI-compatible LLM APIs — batch mode, structured output |

## Conventions

All projects follow the [organization conventions](https://github.com/nlink-jp/.github/blob/main/CONVENTIONS.md).
