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

> **macOS (Apple Silicon):** most Go CLIs and GUI apps install straight from our
> Homebrew tap — Developer ID signed + Apple-notarized prebuilt binaries:
> ```sh
> brew tap nlink-jp/tap
> brew install nlink-jp/tap/<name>          # CLI tools
> brew install --cask nlink-jp/tap/<name>   # GUI apps
> ```
> See [nlink-jp/homebrew-tap](https://github.com/nlink-jp/homebrew-tap) for the full list.

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
| [slack-mcp-extender](https://github.com/nlink-jp/slack-mcp-extender) | Go | Transparent proxy for the official Slack MCP — adds ext_ file upload/download tools (root message / thread reply / save to disk) under the user's own identity, with operator-configured path containment in both directions |
| [slack-router](https://github.com/nlink-jp/slack-router) | Go | Slack Slash Command daemon — routes commands to local shell scripts via Socket Mode |
| [stail](https://github.com/nlink-jp/stail) | Go | Read-only Slack CLI — stream channel messages in real time (`tail -f`) or export history to JSON |
| [swrite](https://github.com/nlink-jp/swrite) | Go | Bot-oriented Slack poster — post text, Block Kit, attachments, and files from shell pipelines; unfurl control; server mode for Docker/Kubernetes |

### cybersecurity-series — Cybersecurity workflow tools

AI-augmented tools for threat intelligence, product risk assessment, and incident response analysis.

| Tool | Lang | Description |
|------|------|-------------|
| [abuse-lookup](https://github.com/nlink-jp/abuse-lookup) | Go | Checks IP address reputation against the AbuseIPDB API (CLI + MCP) — abuse score, report history, usage type, and ISP, cached locally with a TTL; large `get_reports` pages are file-mediated to an agent-provided workspace. The online, reputation-focused sibling of asn-lookup |
| [ai-ir](https://github.com/nlink-jp/ai-ir) | Python | AI-powered incident response — analyzes Slack IR exports to generate summaries, activity reports, and reusable tactics |
| [ai-ir2](https://github.com/nlink-jp/ai-ir2) | Python | Next-gen IR analysis — one-stop Gemini pipeline producing Markdown, self-contained HTML, and knowledge documents |
| [cti-graph](https://github.com/nlink-jp/cti-graph) | Python | Local-first attack graph analysis — STIX 2.1 ingestion, PIR-driven weighting, choke-point detection, FastAPI API |
| [cti-primer](https://github.com/nlink-jp/cti-primer) | Python | Local-first CTI PIR generation — converts business context into Priority Intelligence Requirements using local LLMs or dictionary-only mode |
| [doh-lookup](https://github.com/nlink-jp/doh-lookup) | Go | Collects a domain's DNS records over DoH (CLI + MCP) — queries Cloudflare/Google out-of-band over HTTPS so investigative lookups stay distinguishable from ordinary DNS; forward profile (A/AAAA/MX/TXT/NS/SOA/CAA) + PTR reverse, bulk input, states the resolver/endpoint and DNSSEC AD in every result; no credentials. The DNS-resolution sibling of asn-lookup and whois-lookup |
| [icloud-relay-lookup](https://github.com/nlink-jp/icloud-relay-lookup) | Go | Reports whether an IP is an Apple iCloud Private Relay egress IP (CLI + MCP) — offline longest-prefix match from a cached copy of Apple's egress list, with its geo hints (country/region/city); ETag revalidation, no credentials. The Apple-side sibling of tor-exit-lookup |
| [ioc-collector](https://github.com/nlink-jp/ioc-collector) | Python | Research security incidents from URLs or CVE IDs — extracts IoCs into Markdown and STIX 2.1 bundles |
| [ir-hub](https://github.com/nlink-jp/ir-hub) | Go | IR lifecycle hub — resident Slack ChatOps bot that opens a channel per case, tracks the response with ACL-gated commands, and ingests messages for postmortems and knowledge reuse |
| [ir-timeline](https://github.com/nlink-jp/ir-timeline) | Go | IR timeline recorder — single-binary, browser-based tool for tracking IR events with text, images, tags, and time deltas |
| [ir-tracker](https://github.com/nlink-jp/ir-tracker) | Python | Live IR tracker — continuous ingestion, segmented analysis, and timeline visualization for ongoing incidents via Gemini |
| [mail-triage](https://github.com/nlink-jp/mail-triage) | Python | GCS-based email triage — classifies eml/msg files with Gemini LLM and posts results to Slack via Cloud Run Jobs |
| [news-collector](https://github.com/nlink-jp/news-collector) | Python | News collection agent — collects, tags, summarizes, translates, and delivers curated news digests via Gemini + Slack |
| [product-research](https://github.com/nlink-jp/product-research) | Python | Research products and services — outputs ToS, privacy, and data security analysis as structured reports |
| [tor-exit-lookup](https://github.com/nlink-jp/tor-exit-lookup) | Go | Reports whether an IP is a Tor Exit node (CLI + MCP) — offline membership lookup from a cached copy of the Tor Project's torbulkexitlist, enriched with exit-addresses metadata; no credentials. The offline sibling of asn-lookup and abuse-lookup |
| [urlscan-lookup](https://github.com/nlink-jp/urlscan-lookup) | Go | Investigates a suspicious URL via the urlscan.io API (CLI + MCP) — an active scan submits the URL to urlscan's sandbox browser for its behaviour, verdict, observed IPs/domains, and screenshot (private by default; public must be requested explicitly), plus a passive search of the historical public-scan database; async job flow, TTL cache, free-plan API key. The URL-layer sibling that feeds the IP/domain-layer lookups |
| [whois-lookup](https://github.com/nlink-jp/whois-lookup) | Go | Looks up the registration data of a domain, IP, or AS number (CLI + MCP) — RDAP-first via the IANA bootstrap with a port 43 WHOIS fallback for RDAP-less ccTLDs (.jp), in-house IDN punycode, local TTL cache; no credentials. The registration-focused sibling of asn-lookup and abuse-lookup |

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
| [active-lens](https://github.com/nlink-jp/active-lens) | Go | Content-free Mac activity tracker — records only that input happened (idle/display/lock via CoreGraphics, no permissions) and classifies each moment operating/present/away; derives work **sessions** (never split at midnight, filed under a configurable logical day) into a per-day work log via `timeline`, and the session in progress via `now`. darwin/arm64 |
| [active-lens-gui](https://github.com/nlink-jp/active-lens-gui) | Swift | macOS work-log menu-bar app — a native SwiftUI front-end over active-lens showing the current state + the active time of the session you are in, with a calendar-style work timeline (day columns, hover for a block's start/end/duration) and a per-day work log |
| [ask-gemini-mcp](https://github.com/nlink-jp/ask-gemini-mcp) | Go | MCP server exposing `ask_gemini(prompt)` — forwards to Vertex AI Gemini for second-opinion consultations from AI coding agents, with structured errors and content-filter detection |
| [ask-llm-mcp](https://github.com/nlink-jp/ask-llm-mcp) | Go | MCP server exposing `ask_llm(prompt)` — forwards to an OpenAI API-compatible endpoint (primary target: local LM Studio) for second-opinion consultations from AI coding agents, with optional Bearer auth, retry/backoff, and reasoning stripping |
| [asn-lookup](https://github.com/nlink-jp/asn-lookup) | Go | Local IP↔AS lookups from the IPinfo Lite database (CLI + MCP) — downloads the free Lite DB once and answers IP→ASN/country and ASN→prefixes fully offline; large reverse-lookup results are file-mediated to an agent-provided workspace, with `get_usage`/`update_db` MCP tools |
| [cclaude](https://github.com/nlink-jp/cclaude) | Bash | Containerized Claude Code — run Claude Code in an isolated container with project isolation |
| [claude-usage-lens](https://github.com/nlink-jp/claude-usage-lens) | Go | Token usage & cost analysis for Claude Code / Cowork — parses local session logs, computes API list-price-equivalent cost into a durable SQLite store, and reports by day/session/project/model with near-real-time `watch`, period analysis, and `verify` against Cowork audit ground truth |
| [claude-usage-lens-gui](https://github.com/nlink-jp/claude-usage-lens-gui) | Swift | macOS menu-bar app for Claude usage cost — a native SwiftUI front-end over claude-usage-lens showing today's cost (price/tokens) in the menu bar, expanding into Swift Charts analysis (daily trend, per-model stacking, top projects) |
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
| [image-forge](https://github.com/nlink-jp/image-forge) | Go | Local diffusion image-generation engine + model-management CLI for macOS (Apple Silicon) — SDXL/anime and general models via stable-diffusion.cpp (CGO/Metal, single binary); per-model gotchas (CLIP-skip/VAE/resolution/v-pred) hidden behind profiles; txt2img/img2img/inpaint/ControlNet/LoRA, GGUF quantization, multi-component (FLUX/SD3.5/Z-Image/Anima), resident serve mode; registry manages diffusion / LoRA / ControlNet / upscaler kinds with architecture compatibility + curated LoRA catalog with trigger words |
| [image-forge-gui](https://github.com/nlink-jp/image-forge-gui) | Swift | Native macOS (SwiftUI) front-end for the image-forge CLI — exploratory local image generation: Composer (prompt/negative, model picker with arch + content rating, Advanced sampler/scheduler/clip-skip, LoRA stacking with per-LoRA weights, init-image for img2img) → Generate (single or a batch of up to 50, stopped either at once or after the image in progress) → Gallery (lightbox, multi-select with batch delete/export/move, ESRGAN upscale, switchable libraries, prompt / full-parameter reuse); drives the resident serve engine; bundles the signed CLI |
| [instant-translate](https://github.com/nlink-jp/instant-translate) | Swift | Lightweight macOS menu-bar translator built on the on-device Translation framework (no LLM, no network, no special permissions) — auto-detected language routing with a configurable secondary language + manual target picker, debounced auto-translate, a global hotkey (⌥⌘T, rebindable) with clipboard seeding, OS-supported languages with regional variants distinguished (English (US) vs English (UK), …), and launch-at-login. darwin/arm64 |
| [json-filter](https://github.com/nlink-jp/json-filter) | Go | Extract, validate, prettify, and repair JSON from arbitrary text streams |
| [json-to-sqlite](https://github.com/nlink-jp/json-to-sqlite) | Go | Load JSON data into SQLite with automatic schema inference |
| [json-to-table](https://github.com/nlink-jp/json-to-table) | Go | Format a JSON array into text, Markdown, HTML, CSV, PNG, or Slack Block Kit tables |
| [jstats](https://github.com/nlink-jp/jstats) | Go | SPL-style stats aggregations for JSON streams — count, avg, p95, stdev, values, and more |
| [jviz](https://github.com/nlink-jp/jviz) | Go | Visualize JSON arrays as interactive charts in the browser — bar, line, pie, table with live SSE updates |
| [load-spinner](https://github.com/nlink-jp/load-spinner) | Swift | macOS menu-bar CPU/GPU load indicator — a lit segment travels around a fixed circle/square at a speed proportional to load; modes for max/CPU/GPU/both (per-source shape + color), optional vertical CPU/GPU badges, and a click panel with live gauges + a 3-minute Swift Charts history. GPU via IOKit, degrading to CPU-only when unavailable. darwin/arm64 |
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
| [share-mounter](https://github.com/nlink-jp/share-mounter) | Swift | macOS menu-bar app that auto-mounts SMB shares at login **without opening a Finder window** — mounts via NetFS so shares appear in the Finder sidebar as network volumes; multiple shares with per-share auto-mount at login (SMAppService), Keychain-stored credentials, reachability-gated mount and re-mount on wake/network recovery. darwin/arm64 |
| [shell-agent](https://github.com/nlink-jp/shell-agent) | Go/Swift | ~~macOS LLM chat & agent — MCP support, shell script Tool Calling with MITL, Hot/Warm/Cold memory, multimodal~~ **Archived** — superseded by [shell-agent-v2](https://github.com/nlink-jp/shell-agent-v2) |
| [shell-agent-v2](https://github.com/nlink-jp/shell-agent-v2) | Go/React | Successor to shell-agent — Wails desktop app with interactive data analysis, session-scoped DuckDB, hybrid LLM (Local + Vertex AI), per-session container sandbox (shell + Python), global Findings, unified MITL across analysis/shell/sandbox/MCP |
| [url-shelf](https://github.com/nlink-jp/url-shelf) | Swift | macOS menu-bar shelf of URL notes kept as plain `.webloc` files — the folder tree *is* the classification, so Finder stays the editor and the records outlive the app; per-entry **private-window** opening (measured flags for Firefox/Chrome/Edge/Brave/Vivaldi, Safari normal-only) with entry > folder > global inheritance, disabled rather than downgraded when no private browser is set, Option to invert per click, drag a URL onto the icon to file it. No network access. darwin/arm64 |
| [video-studio-mcp](https://github.com/nlink-jp/video-studio-mcp) | Go | MCP server that assembles a narrated presentation video (MP4) from a page manifest (image + audio per page) — a pure ffmpeg compositor paired with voice-studio-mcp; per-page audio sets each page's duration (exact A/V sync), per-page chapter markers, opt-in captions (burned-in via bundled M PLUS 1p Go-rendered overlay — no libfreetype needed — and/or a toggleable mov_text closed-caption track), per-call canvas override (16:9/9:16/1:1), async rendering with check_job |
| [voice-studio-mcp](https://github.com/nlink-jp/voice-studio-mcp) | Go | MCP server giving AI agents local multi-speaker Japanese speech synthesis for narrated audio (radio drama, audiobook, podcast, briefing) — Japanese only; AivisSpeech Engine backend, script JSONL batch synthesis with content-hash cache, pronunciation dictionaries, ffmpeg mastering (mp3/m4b chapters, loudnorm, credits), voice-model license review workflow, bundled multi-actor-narration Claude Code skill |
| [webhook-relay](https://github.com/nlink-jp/webhook-relay) | Go | Authenticated webhook receiver — writes payloads to GCS via Cloud Run Service with VPC isolation |
