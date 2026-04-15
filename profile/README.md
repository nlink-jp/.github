# nlink-jp

A collection of CLI tools and libraries.

## Projects

### cli-series — Service CLI clients

Pipe-friendly, Unix-composable CLI clients for external services.
Authenticate as the human user, not a bot.

| Tool | Service | Description |
|------|---------|-------------|
| [confl-cli](https://github.com/nlink-jp/confl-cli) | Confluence | Confluence Cloud CLI — list, search, read, export |
| [gem-cli](https://github.com/nlink-jp/gem-cli) | Gemini | Gemini CLI client — multimodal prompts, streaming, grounding, structured output via Vertex AI |
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
| [swrite](https://github.com/nlink-jp/swrite) | Bot-oriented Slack poster — post text, Block Kit, attachments, and files from shell pipelines; unfurl control; server mode for Docker/Kubernetes |

### cybersecurity-series — Cybersecurity workflow tools

AI-augmented tools for threat intelligence, product risk assessment, and incident response analysis.

| Tool | Description |
|------|-------------|
| [ai-ir](https://github.com/nlink-jp/ai-ir) | AI-powered incident response — analyzes Slack IR exports to generate summaries, activity reports, and reusable tactics |
| [ai-ir2](https://github.com/nlink-jp/ai-ir2) | Next-gen IR analysis — one-stop Gemini pipeline producing Markdown, self-contained HTML, and knowledge documents |
| [ioc-collector](https://github.com/nlink-jp/ioc-collector) | Research security incidents from URLs or CVE IDs — extracts IoCs into Markdown and STIX 2.1 bundles |
| [ir-timeline](https://github.com/nlink-jp/ir-timeline) | IR timeline recorder — single-binary, browser-based tool for tracking IR events with text, images, tags, and time deltas |
| [ir-tracker](https://github.com/nlink-jp/ir-tracker) | Live IR tracker — continuous ingestion, segmented analysis, and timeline visualization for ongoing incidents via Gemini |
| [mail-triage](https://github.com/nlink-jp/mail-triage) | GCS-based email triage — classifies eml/msg files with Gemini LLM and posts results to Slack via Cloud Run Jobs |
| [news-collector](https://github.com/nlink-jp/news-collector) | News collection agent — collects, tags, summarizes, translates, and delivers curated news digests via Gemini + Slack |
| [product-research](https://github.com/nlink-jp/product-research) | Research products and services — outputs ToS, privacy, and data security analysis as structured reports |

### lab-series — Experimental projects

Works in progress. APIs, features, and interfaces may change without notice.

| Tool | Lang | Description |
|------|------|-------------|
| [agent-skeleton](https://github.com/nlink-jp/agent-skeleton) | Python | Autonomous agent skeleton — plan-approve-execute loop, per-tool approval, 2-tier memory compression, MCP support |
| [agentic-web-search](https://github.com/nlink-jp/agentic-web-search) | Go | ~~Agentic web search — autonomous research via local LLM + Brave Search API~~ **FROZEN** (search API ToS concerns) |
| [llm-othello](https://github.com/nlink-jp/llm-othello) | Go | Browser-based Othello against a local LLM — server-side move generation via OpenAI-compatible API |
| [m5-clock](https://github.com/nlink-jp/m5-clock) | C++ | NTP-synchronized digital clock for M5Stack Core2 — night mode, RTC backup, SD card config |
| [m5-vehicle-logger](https://github.com/nlink-jp/m5-vehicle-logger) | C++ | Vehicle driving data logger for M5Stack Basic v2.7 — GPS + IMU sensing with Wi-Fi transmission |
| [magi-system](https://github.com/nlink-jp/magi-system) | Python | Multi-agent discussion system with 3 AI personas (MELCHIOR / BALTHASAR / CASPER) |
| [magi-system2](https://github.com/nlink-jp/magi-system2) | Python | Multi-persona AI discussion — dynamic persona generation, dual memory, adaptive facilitation via Gemini |
| [mail-watcher](https://github.com/nlink-jp/mail-watcher) | Bash | Mail monitoring workflow — watches for incoming eml/msg files, analyzes with LLM, and posts Slack notifications |
| [mcp-skeleton](https://github.com/nlink-jp/mcp-skeleton) | Python | MCP server skeleton — raw JSON-RPC 2.0 over stdio/SSE with API key auth, for learning MCP internals |
| [meeting-note](https://github.com/nlink-jp/meeting-note) | Python | Meeting minutes structuring tool — audio/transcript to structured JSON via Gemini, then compile to Markdown/HTML |
| [sai](https://github.com/nlink-jp/sai) | Python | Context-aware Slack bot with RAG memory and natural language command execution |
| [slack-monitor](https://github.com/nlink-jp/slack-monitor) | Python | Real-time Slack channel summarizer with local/cloud LLM and Textual TUI |
| [virtual-reviewer](https://github.com/nlink-jp/virtual-reviewer) | Python | AI-powered security review system — LLM expert models with full regulation context, no RAG, UNIX pipes |
| [workflow-builder](https://github.com/nlink-jp/workflow-builder) | — | LLM-powered workflow builder — generates shell scripts from natural language using CLI tool registry (design phase) |

### lib-series — Shared libraries

Shared libraries for nlink-jp projects. Zero external dependencies where possible.

| Library | Lang | Description |
|---------|------|-------------|
| [nlk](https://github.com/nlink-jp/nlk) | Go | Lightweight LLM utility toolkit — guard, jsonfix, strip, backoff, validate. Zero external dependencies |
| [nlk-py](https://github.com/nlink-jp/nlk-py) | Python | Python edition of nlk — same 5 modules, same API design. Zero external dependencies |

### lite-series — Lightweight LLM and pipeline tools

Small, local-first CLI tools for LLM interaction, retrieval, and classification.

| Tool | Description |
|------|-------------|
| [lite-llm](https://github.com/nlink-jp/lite-llm) | CLI client for OpenAI-compatible LLM APIs — streaming, batch, structured output |
| [lite-rag](https://github.com/nlink-jp/lite-rag) | RAG CLI for Markdown docs using DuckDB — index and query local knowledge bases |
| [lite-switch](https://github.com/nlink-jp/lite-switch) | Natural language classifier for shell pipelines — routes stdin text to a matching tag via LLM |

### skills-series — Claude Code Skills

Claude Code Skills for development process automation.

| Skill | Command | Description |
|-------|---------|-------------|
| [rfp](https://github.com/nlink-jp/skills-series) | `/rfp [tool-name]` | Interactive RFP facilitation — collects requirements through Q&A against CONVENTIONS.md Phase 1 and generates structured RFP documents |

### util-series — General-purpose data utilities

Pipe-friendly tools for data transformation and processing.

| Tool | Lang | Description |
|------|------|-------------|
| [cclaude](https://github.com/nlink-jp/cclaude) | Bash | Containerized Claude Code — run Claude Code in an isolated container with project isolation |
| [csv-to-json](https://github.com/nlink-jp/csv-to-json) | Go | Convert CSV data to a JSON array |
| [data-analyzer](https://github.com/nlink-jp/data-analyzer) | Go | Large-scale JSON/JSONL data analysis using local LLMs — sliding window + progressive summarization |
| [eml-to-jsonl](https://github.com/nlink-jp/eml-to-jsonl) | Go | Parse .eml files and output structured JSONL — headers, body, attachments |
| [gem-image](https://github.com/nlink-jp/gem-image) | Go | Image generation and editing CLI — text-to-image and image editing via Vertex AI Gemini 2.5 Flash |
| [gem-query](https://github.com/nlink-jp/gem-query) | Go | Natural language data analysis CLI — interactive SQL generation for DuckDB/SQLite via Vertex AI Gemini |
| [gem-rag](https://github.com/nlink-jp/gem-rag) | Python | Gemini-powered RAG CLI for Markdown documents — index, search, and answer questions using Vertex AI embeddings and DuckDB |
| [gem-search](https://github.com/nlink-jp/gem-search) | Go | Agentic web search — autonomous research via Vertex AI Gemini with Google Search Grounding, Markdown/JSON reports |
| [json-filter](https://github.com/nlink-jp/json-filter) | Go | Extract, validate, prettify, and repair JSON from arbitrary text streams |
| [json-to-sqlite](https://github.com/nlink-jp/json-to-sqlite) | Go | Load JSON data into SQLite with automatic schema inference |
| [json-to-table](https://github.com/nlink-jp/json-to-table) | Go | Format a JSON array into text, Markdown, HTML, CSV, PNG, or Slack Block Kit tables |
| [jstats](https://github.com/nlink-jp/jstats) | Go | SPL-style stats aggregations for JSON streams — count, avg, p95, stdev, values, and more |
| [jviz](https://github.com/nlink-jp/jviz) | Go | Visualize JSON arrays as interactive charts in the browser — bar, line, pie, table with live SSE updates |
| [lookup](https://github.com/nlink-jp/lookup) | Go | Enrich JSON/JSONL streams by matching fields against CSV/JSON data sources |
| [mail-analyzer](https://github.com/nlink-jp/mail-analyzer) | Go | Suspicious email analyzer — rule-based indicators + Gemini LLM content analysis for .eml/.msg files |
| [mail-analyzer-gui](https://github.com/nlink-jp/mail-analyzer-gui) | Rust/Svelte | macOS desktop GUI for mail-analyzer — drag & drop email analysis via Tauri |
| [mail-analyzer-local](https://github.com/nlink-jp/mail-analyzer-local) | Go | Local LLM version of mail-analyzer — email analysis via OpenAI-compatible API (LM Studio, Ollama) |
| [markdown-viewer](https://github.com/nlink-jp/markdown-viewer) | Go | Single-binary local Markdown viewer — renders GFM, Mermaid, and syntax-highlighted code in the browser |
| [mcp-guardian](https://github.com/nlink-jp/mcp-guardian) | Go | MCP governance proxy — transparent auditing, OAuth2 auto-discovery, and tool masking for MCP servers |
| [msg-to-jsonl](https://github.com/nlink-jp/msg-to-jsonl) | Go | Parse Outlook .msg files and output structured JSONL — same schema as eml-to-jsonl |
| [pptx-to-markdown](https://github.com/nlink-jp/pptx-to-markdown) | Python | Convert `.pptx` presentations to structured Markdown for LLM analysis |
| [quick-translate](https://github.com/nlink-jp/quick-translate) | Swift | macOS menu-bar-resident translation tool — local LLM via OpenAI-compatible API |
| [rex](https://github.com/nlink-jp/rex) | Go | Extract fields from text using named regex capture groups — outputs JSON |
| [sdate](https://github.com/nlink-jp/sdate) | Go | Calculate timestamps using Splunk-like relative time modifiers (e.g., `-1d@d`) |
| [webhook-relay](https://github.com/nlink-jp/webhook-relay) | Go | Authenticated webhook receiver — writes payloads to GCS via Cloud Run Service with VPC isolation |
