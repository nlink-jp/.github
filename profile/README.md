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

### lab-series — Experimental projects

Works in progress. APIs, features, and interfaces may change without notice.

| Tool | Lang | Description |
|------|------|-------------|
| [mail-analyzer](https://github.com/nlink-jp/mail-analyzer) | Go | Mail analysis tool |
| [magi-system](https://github.com/nlink-jp/magi-system) | Python | Multi-agent discussion system with 3 AI personas (MELCHIOR / BALTHASAR / CASPER) |
| [llm-othello](https://github.com/nlink-jp/llm-othello) | Go | Browser-based Othello against a local LLM — server-side move generation via OpenAI-compatible API |
| [sai](https://github.com/nlink-jp/sai) | Python | Context-aware Slack bot with RAG memory and natural language command execution |
| [slack-monitor](https://github.com/nlink-jp/slack-monitor) | Python | Real-time Slack channel summarizer with local/cloud LLM and Textual TUI |

### lite-series — Lightweight LLM and pipeline tools

Small, local-first CLI tools for LLM interaction, retrieval, and classification.

| Tool | Description |
|------|-------------|
| [lite-llm](https://github.com/nlink-jp/lite-llm) | CLI client for OpenAI-compatible LLM APIs — streaming, batch, structured output |
| [lite-rag](https://github.com/nlink-jp/lite-rag) | RAG CLI for Markdown docs using DuckDB — index and query local knowledge bases |
| [lite-switch](https://github.com/nlink-jp/lite-switch) | Natural language classifier for shell pipelines — routes stdin text to a matching tag via LLM |

### util-series — General-purpose data utilities

Pipe-friendly tools for data transformation and processing.

| Tool | Lang | Description |
|------|------|-------------|
| [csv-to-json](https://github.com/nlink-jp/csv-to-json) | Go | Convert CSV data to a JSON array |
| [eml-to-jsonl](https://github.com/nlink-jp/eml-to-jsonl) | Go | Parse .eml files and output structured JSONL — headers, body, attachments |
| [msg-to-jsonl](https://github.com/nlink-jp/msg-to-jsonl) | Go | Parse Outlook .msg files and output structured JSONL — same schema as eml-to-jsonl |
| [json-filter](https://github.com/nlink-jp/json-filter) | Go | Extract, validate, prettify, and repair JSON from arbitrary text streams |
| [json-to-sqlite](https://github.com/nlink-jp/json-to-sqlite) | Go | Load JSON data into SQLite with automatic schema inference |
| [jstats](https://github.com/nlink-jp/jstats) | Go | SPL-style stats aggregations for JSON streams — count, avg, p95, stdev, values, and more |
| [jviz](https://github.com/nlink-jp/jviz) | Go | Visualize JSON arrays as interactive charts in the browser — bar, line, pie, table with live SSE updates |
| [json-to-table](https://github.com/nlink-jp/json-to-table) | Go | Format a JSON array into text, Markdown, HTML, CSV, PNG, or Slack Block Kit tables |
| [lookup](https://github.com/nlink-jp/lookup) | Go | Enrich JSON/JSONL streams by matching fields against CSV/JSON data sources |
| [markdown-viewer](https://github.com/nlink-jp/markdown-viewer) | Go | Single-binary local Markdown viewer — renders GFM, Mermaid, and syntax-highlighted code in the browser |
| [pptx-to-markdown](https://github.com/nlink-jp/pptx-to-markdown) | Python | Convert `.pptx` presentations to structured Markdown for LLM analysis |
| [rex](https://github.com/nlink-jp/rex) | Go | Extract fields from text using named regex capture groups — outputs JSON |
| [sdate](https://github.com/nlink-jp/sdate) | Go | Calculate timestamps using Splunk-like relative time modifiers (e.g., `-1d@d`) |
