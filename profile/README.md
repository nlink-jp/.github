# nlink-jp

A collection of CLI tools and libraries.

## Getting Started

New to nlink-jp tools? Start here:

- **[Getting Started Guide (JA)](https://github.com/nlink-jp/.github/blob/main/docs/ja/getting-started.ja.md)** — どのツールに何が必要か、判定フロー付きガイド
- [Getting Started Guide (EN)](https://github.com/nlink-jp/.github/blob/main/docs/en/getting-started.md)

| Setup Guide | What it covers |
|-------------|---------------|
| [Vertex AI Setup](https://github.com/nlink-jp/.github/blob/main/docs/ja/setup-vertex-ai.ja.md) | gcloud CLI, ADC authentication, config.toml |
| [Local LLM Setup](https://github.com/nlink-jp/.github/blob/main/docs/ja/setup-local-llm.ja.md) | LM Studio, model download, API server |
| [Python + uv Setup](https://github.com/nlink-jp/.github/blob/main/docs/ja/setup-python-uv.ja.md) | Python, uv package manager |
| [Go Build Setup](https://github.com/nlink-jp/.github/blob/main/docs/ja/setup-go-build.ja.md) | Go, make, or pre-built binaries |

## Projects

### cli-series — Service CLI clients

Pipe-friendly, Unix-composable CLI clients for external services.
Authenticate as the human user, not a bot.

| Tool | Lang | Description |
|------|------|-------------|
| [confl-cli](https://github.com/nlink-jp/confl-cli) | Python | Confluence Cloud CLI — list, search, read, export |
| [gem-cli](https://github.com/nlink-jp/gem-cli) | Go | Gemini CLI client — multimodal prompts, streaming, grounding, structured output via Vertex AI |
| [llm-cli](https://github.com/nlink-jp/llm-cli) | Go | CLI client for local LLMs (LM Studio, Ollama) — streaming, batch, multi-image VLM, structured output |
| [scli](https://github.com/nlink-jp/scli) | Go | Terminal Slack client — channels, messages, DMs, search |
| [splunk-cli](https://github.com/nlink-jp/splunk-cli) | Go | CLI client for the Splunk REST API — run searches, poll jobs, fetch results |

### chatops-series — ChatOps workflow tools

Pipe-friendly Slack tools for ChatOps automation and monitoring.

| Tool | Lang | Description |
|------|------|-------------|
| [md-to-slack](https://github.com/nlink-jp/md-to-slack) | Go | Markdown → Slack Block Kit JSON filter — pipe into `scat` to post formatted messages |
| [scat](https://github.com/nlink-jp/scat) | Go | General-purpose content poster — send text, files, and Block Kit messages to Slack from stdin or files |
| [slack-router](https://github.com/nlink-jp/slack-router) | Go | Slack Slash Command daemon — routes commands to local shell scripts via Socket Mode |
| [stail](https://github.com/nlink-jp/stail) | Go | Read-only Slack CLI — stream channel messages in real time (`tail -f`) or export history to JSON |
| [swrite](https://github.com/nlink-jp/swrite) | Go | Bot-oriented Slack poster — post text, Block Kit, attachments, and files from shell pipelines; unfurl control; server mode for Docker/Kubernetes |

### cybersecurity-series — Cybersecurity workflow tools

AI-augmented tools for threat intelligence, product risk assessment, and incident response analysis.

| Tool | Lang | Description |
|------|------|-------------|
| [ai-ir](https://github.com/nlink-jp/ai-ir) | Python | AI-powered incident response — analyzes Slack IR exports to generate summaries, activity reports, and reusable tactics |
| [ai-ir2](https://github.com/nlink-jp/ai-ir2) | Python | Next-gen IR analysis — one-stop Gemini pipeline producing Markdown, self-contained HTML, and knowledge documents |
| [cti-graph](https://github.com/nlink-jp/cti-graph) | Python | Local-first attack graph analysis — STIX 2.1 ingestion, PIR-driven weighting, choke-point detection, FastAPI API |
| [cti-primer](https://github.com/nlink-jp/cti-primer) | Python | Local-first CTI PIR generation — converts business context into Priority Intelligence Requirements using local LLMs or dictionary-only mode |
| [ioc-collector](https://github.com/nlink-jp/ioc-collector) | Python | Research security incidents from URLs or CVE IDs — extracts IoCs into Markdown and STIX 2.1 bundles |
| [ir-hub](https://github.com/nlink-jp/ir-hub) | Go | IR lifecycle hub — resident Slack ChatOps bot that opens a channel per case, tracks the response with ACL-gated commands, and ingests messages for postmortems and knowledge reuse |
| [ir-timeline](https://github.com/nlink-jp/ir-timeline) | Go | IR timeline recorder — single-binary, browser-based tool for tracking IR events with text, images, tags, and time deltas |
| [ir-tracker](https://github.com/nlink-jp/ir-tracker) | Python | Live IR tracker — continuous ingestion, segmented analysis, and timeline visualization for ongoing incidents via Gemini |
| [mail-triage](https://github.com/nlink-jp/mail-triage) | Python | GCS-based email triage — classifies eml/msg files with Gemini LLM and posts results to Slack via Cloud Run Jobs |
| [news-collector](https://github.com/nlink-jp/news-collector) | Python | News collection agent — collects, tags, summarizes, translates, and delivers curated news digests via Gemini + Slack |
| [product-research](https://github.com/nlink-jp/product-research) | Python | Research products and services — outputs ToS, privacy, and data security analysis as structured reports |

### lab-series — Experimental projects

Works in progress. APIs, features, and interfaces may change without notice.

| Tool | Lang | Description |
|------|------|-------------|
| [agent-skeleton](https://github.com/nlink-jp/agent-skeleton) | Python | Autonomous agent skeleton — plan-approve-execute loop, per-tool approval, 2-tier memory compression, MCP support |
| [agentic-web-search](https://github.com/nlink-jp/agentic-web-search) | Go | ~~Agentic web search — autonomous research via local LLM + Brave Search API~~ **FROZEN** (search API ToS concerns) |
| [llm-othello](https://github.com/nlink-jp/llm-othello) | Go | Browser-based Othello against a local LLM — server-side move generation via OpenAI-compatible API |
| [log-analyzer](https://github.com/nlink-jp/log-analyzer) | Python | Large JSONL log analyzer — LLM-driven analysis with timestamp-based chunking for files exceeding context limits |
| [m5-clock](https://github.com/nlink-jp/m5-clock) | C++ | NTP-synchronized digital clock for M5Stack Core2 — night mode, RTC backup, SD card config |
| [m5-data-receiver](https://github.com/nlink-jp/m5-data-receiver) | Bash/CFn | Serverless AWS backend for m5-vehicle-logger — API Gateway + Lambda + S3 with deploy/destroy scripts |
| [m5-vehicle-logger](https://github.com/nlink-jp/m5-vehicle-logger) | C++ | Vehicle data logger for M5Stack — GNSS + 9-axis IMU + barometer, 3-page display, gravity compensation |
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

| Tool | Lang | Description |
|------|------|-------------|
| [nlk](https://github.com/nlink-jp/nlk) | Go | Lightweight LLM utility toolkit — guard, jsonfix, strip, backoff, validate. Zero external dependencies |
| [nlk-py](https://github.com/nlink-jp/nlk-py) | Python | Python edition of nlk — same 5 modules, same API design. Zero external dependencies |

### lite-series — Lightweight LLM and pipeline tools

Small, local-first CLI tools for LLM interaction, retrieval, and classification.

| Tool | Lang | Description |
|------|------|-------------|
| [lite-llm](https://github.com/nlink-jp/lite-llm) | Go | ~~CLI client for OpenAI-compatible LLM APIs~~ **Archived** — superseded by [llm-cli](https://github.com/nlink-jp/llm-cli) |
| [lite-rag](https://github.com/nlink-jp/lite-rag) | Go | RAG CLI for Markdown docs using DuckDB — index and query local knowledge bases |
| [lite-switch](https://github.com/nlink-jp/lite-switch) | Go | Natural language classifier for shell pipelines — routes stdin text to a matching tag via LLM |

### skills-series — Claude Code Skills

Claude Code Skills for development process automation.

| Skill | Command | Description |
|-------|---------|-------------|
| [rfp](https://github.com/nlink-jp/skills-series) | `/rfp [tool-name]` | Interactive RFP facilitation — collects requirements through Q&A against CONVENTIONS.md Phase 1 and generates structured RFP documents |

### util-series — General-purpose data utilities

Pipe-friendly tools for data transformation and processing.

| Tool | Lang | Description |
|------|------|-------------|
| [ask-gemini-mcp](https://github.com/nlink-jp/ask-gemini-mcp) | Go | MCP server exposing `ask_gemini(prompt)` — forwards to Vertex AI Gemini for second-opinion consultations from AI coding agents, with structured errors and content-filter detection |
| [ask-llm-mcp](https://github.com/nlink-jp/ask-llm-mcp) | Go | MCP server exposing `ask_llm(prompt)` — forwards to an OpenAI API-compatible endpoint (primary target: local LM Studio) for second-opinion consultations from AI coding agents, with optional Bearer auth, retry/backoff, and reasoning stripping |
| [cclaude](https://github.com/nlink-jp/cclaude) | Bash | Containerized Claude Code — run Claude Code in an isolated container with project isolation |
| [csv-editor](https://github.com/nlink-jp/csv-editor) | Go/React | CSV/TSV editor GUI for macOS/Windows — UTF-8 (BOM optional)/Shift_JIS/CP932 with auto-detect, virtual scroll for 100k+ rows, IME-safe edit, sort, find/replace, TSV clipboard with shape-mismatch confirmation |
| [csv-to-json](https://github.com/nlink-jp/csv-to-json) | Go | Convert CSV data to a JSON array |
| [data-agent](https://github.com/nlink-jp/data-agent) | Go/React | ~~Data analysis desktop GUI — interactive chat, plan-driven SQL + sliding window analysis, per-case DuckDB, dual LLM backend~~ **Archived** — superseded by [shell-agent-v2](https://github.com/nlink-jp/shell-agent-v2) |
| [data-analyzer](https://github.com/nlink-jp/data-analyzer) | Go | Large-scale JSON/JSONL data analysis using local LLMs — sliding window + progressive summarization |
| [data-toolbox-mcp](https://github.com/nlink-jp/data-toolbox-mcp) | Go | MCP server exposing DuckDB analysis and containerized Python execution (9 tools: `load_data` / `query_data` / `execute_code` / `list_workspaces` / `describe_workspace` / `delete_workspace` / `describe_runtime` / `attach_files` / `load_from_work`) — workspace-scoped DuckDB + Podman sandbox, structured tool errors, bring your own LLM client |
| [eml-to-jsonl](https://github.com/nlink-jp/eml-to-jsonl) | Go | Parse .eml files and output structured JSONL — headers, body, attachments |
| [gem-image](https://github.com/nlink-jp/gem-image) | Go | Image generation and editing CLI — text-to-image and image editing via Vertex AI Gemini 2.5 Flash |
| [gem-query](https://github.com/nlink-jp/gem-query) | Go | Natural language data analysis CLI — interactive SQL generation for DuckDB/SQLite via Vertex AI Gemini |
| [gem-rag](https://github.com/nlink-jp/gem-rag) | Python | Gemini-powered RAG CLI for Markdown documents — index, search, and answer questions using Vertex AI embeddings and DuckDB |
| [gem-search](https://github.com/nlink-jp/gem-search) | Go | Agentic web search — autonomous research via Vertex AI Gemini with Google Search Grounding, Markdown/JSON reports |
| [gem-summary](https://github.com/nlink-jp/gem-summary) | Go | Single-call text summarisation CLI via Vertex AI Gemini — automatic chunked + parallel + merge fallback for over-context-window inputs, prompt-injection defended |
| [gem-transcribe](https://github.com/nlink-jp/gem-transcribe) | Python | Audio transcription CLI built on Vertex AI Gemini — speaker name inference, multi-language output, structured JSON |
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
| [shell-agent](https://github.com/nlink-jp/shell-agent) | Go/Swift | ~~macOS LLM chat & agent — MCP support, shell script Tool Calling with MITL, Hot/Warm/Cold memory, multimodal~~ **Archived** — superseded by [shell-agent-v2](https://github.com/nlink-jp/shell-agent-v2) |
| [shell-agent-v2](https://github.com/nlink-jp/shell-agent-v2) | Go/React | Successor to shell-agent — Wails desktop app with interactive data analysis, session-scoped DuckDB, hybrid LLM (Local + Vertex AI), per-session container sandbox (shell + Python), global Findings, unified MITL across analysis/shell/sandbox/MCP |
| [webhook-relay](https://github.com/nlink-jp/webhook-relay) | Go | Authenticated webhook receiver — writes payloads to GCS via Cloud Run Service with VPC isolation |
