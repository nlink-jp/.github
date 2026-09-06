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

## Knowledge Base

[**nlink-jp/knowledge**](https://github.com/nlink-jp/knowledge) — engineering
lessons learned across all projects, compiled into themed bilingual (ja/en)
documents: release engineering (signing/notarization), macOS GUI, MCP server
design, LLM integration, security, and more. Every entry follows
**symptom → why → how to apply**, distilled from real incidents.

## Projects

### cli-series — Service CLI clients

Pipe-friendly, Unix-composable CLI clients for external services.
Authenticate as the human user, not a bot.

| Tool | Lang | Description |
|------|------|-------------|
| [confl-cli](https://github.com/nlink-jp/confl-cli) | Python | Confluence Cloud CLI — list, search, read, export |
| [gem-agent](https://github.com/nlink-jp/gem-agent) | Go | Interactive CLI agent runtime on Vertex AI Gemini — sandboxed file/shell tools, MCP, skills, two-tier auto-approve (interactive and headless `-p`), session resume, context compaction (macOS) |
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

Tools for security investigation, threat intelligence, and incident response — offline-first lookup CLIs + MCP servers alongside AI-assisted analysis tools.

| Tool | Lang | Description |
|------|------|-------------|
| [abuse-lookup](https://github.com/nlink-jp/abuse-lookup) | Go | Checks IP address reputation against the AbuseIPDB API (CLI + MCP) — abuse score, report history, usage type, and ISP, cached locally with a TTL; `get_reports` returns each page inline and `page`/`per_page` size it. The online, reputation-focused sibling of asn-lookup |
| [asn-lookup](https://github.com/nlink-jp/asn-lookup) | Go | Local IP↔AS lookups from the IPinfo Lite database (CLI + MCP) — downloads the free Lite DB once and answers IP→ASN/country and ASN→prefixes fully offline; a large AS's prefixes come back inline a page at a time (`limit`/`offset`), with `get_usage`/`update_db` MCP tools |
| [doh-lookup](https://github.com/nlink-jp/doh-lookup) | Go | Collects a domain's DNS records over DoH (CLI + MCP) — queries Cloudflare/Google out-of-band over HTTPS so investigative lookups stay distinguishable from ordinary DNS; forward profile (A/AAAA/MX/TXT/NS/SOA/CAA) + PTR reverse, bulk input, states the resolver/endpoint and DNSSEC AD in every result; no credentials. The DNS-resolution sibling of asn-lookup and whois-lookup |
| [gti-lookup](https://github.com/nlink-jp/gti-lookup) | Go | Threat context from Google Threat Intelligence (CLI + MCP) — the community collections an indicator is associated with, sandbox behaviour of a sample served as an index of paged sections, corpus-wide IOC search in GTI query syntax, the vulnerability catalogue with relationship pivots and ATT&CK trees, and read-only LiveHunt ruleset inspection that answers live ("did my rule take?"). Ships exactly the GTI Standard feature set — an untestable Enterprise-gated feature does not ship — and is the one member of the lookup family that requires a commercial licence key: every query is recorded against it, and there is no anonymous mode. Reads only Google's index, so no packet reaches the target; read-only by design — no collection writes, no sample uploads |
| [icloud-relay-lookup](https://github.com/nlink-jp/icloud-relay-lookup) | Go | Reports whether an IP is an Apple iCloud Private Relay egress IP (CLI + MCP) — offline longest-prefix match from a cached copy of Apple's egress list, with its geo hints (country/region/city); ETag revalidation, no credentials. The Apple-side sibling of tor-exit-lookup |
| [ir-timeline](https://github.com/nlink-jp/ir-timeline) | Go | IR timeline recorder — single-binary, browser-based tool for tracking IR events with text, images, tags, and time deltas |
| [mac-lookup](https://github.com/nlink-jp/mac-lookup) | Go | Resolves a MAC address or BSSID to its manufacturer (CLI + MCP) — offline longest-prefix match (36/28/24-bit) against a cached copy of the IEEE registries, and classifies the address first: a randomized or otherwise locally administered address is reported as having no vendor to find, not as an unidentified device; no credentials. The L2 sibling of asn-lookup |
| [malware-lookup](https://github.com/nlink-jp/malware-lookup) | Go | Answers whether a file hash (MD5/SHA1/SHA256) is a publicly known legitimate file or known malware (CLI + MCP) — layers CIRCL hashlookup (known-good), Team Cymru MHR (malicious, queried over DoH so hashes never cross the local resolver in cleartext) and MalwareBazaar (family/tags) into one lookup with a four-way verdict: known_good / known_malware / unknown / conflicting, the last flagging abused legitimate software or false positives for scrutiny. Exists because VirusTotal's free API forbids workflow integration — the VT API is never called; results carry a human-facing GUI link instead. Only the optional abuse.ch Auth-Key as a credential. The file-hash sibling of abuse-lookup and urlscan-lookup |
| [news-collector](https://github.com/nlink-jp/news-collector) | Python | News collection agent — collects, tags, summarizes, translates, and delivers curated news digests via Gemini + Slack |
| [otx-lookup](https://github.com/nlink-jp/otx-lookup) | Go | Attaches campaign context to an indicator of compromise from the community reports ("pulses") of the LevelBlue Open Threat Exchange (CLI + MCP) — adversary, malware family, ATT&CK techniques, targeted industries and countries, each counted by how many independent reports named it, then the pivot from a pulse to the other indicators it carries. The one question the rest of the lookup family cannot answer: every sibling returns one attribute of one indicator, while this returns whether the indicator belongs to a known campaign; the sections a sibling already owns (reputation, passive_dns, malware, url_list) are off by default so the two never compete. Reads only a third-party index, so no packet reaches the target. The API key is optional — indicator lookups and the campaign pivot both work without one; a key adds pulse search and an exact indicator total. An empty answer is reported as clean only when every lookup succeeded, never when one failed |
| [pcap-analyzer-mcp](https://github.com/nlink-jp/pcap-analyzer-mcp) | Go | Analyses pcap/pcapng captures for an LLM agent (MCP) — a digest-pinned tshark runs in a rootless, network-less container with the capture mounted read-only and never copied, so results are reproducible and the evidence stays byte-identical; small results come back inline and large ones as JSONL/CSV in the workspace, always reporting how many packets the filter actually hit. Content read off the wire is framed as untrusted and recovered files are stored under their own SHA-256, never executable — the capture-layer sibling that feeds the IP/domain/URL lookups |
| [rdns-lookup](https://github.com/nlink-jp/rdns-lookup) | Go | Looks up the relationships around an IP or domain in the free 6-billion-record ip.thc.org index (CLI + MCP) — the domains associated with an address or octet-boundary block, a domain's subdomains, and the domains that CNAME to it. Reads only a third-party index, so no packet reaches the target; note this is not PTR but an aggregate of PTR names, A-record matches, and CT-log names, so `1.1.1.1` yields 83,216 records where a PTR yields one. Every result states how many records upstream holds against how many were retrieved, so a capped answer is never mistaken for a complete one; local TTL cache, rate-limit pacing, no credentials. The relationship-breadth sibling of doh-lookup and whois-lookup |
| [tor-exit-lookup](https://github.com/nlink-jp/tor-exit-lookup) | Go | Reports whether an IP is a Tor Exit node (CLI + MCP) — offline membership lookup from a cached copy of the Tor Project's torbulkexitlist, enriched with exit-addresses metadata; no credentials. The offline sibling of asn-lookup and abuse-lookup |
| [urlscan-lookup](https://github.com/nlink-jp/urlscan-lookup) | Go | Investigates a suspicious URL via the urlscan.io API (CLI + MCP) — an active scan submits the URL to urlscan's sandbox browser for its behaviour, verdict, observed IPs/domains, and screenshot (private by default; public must be requested explicitly), plus a passive search of the historical public-scan database; async job flow, TTL cache, free-plan API key. The URL-layer sibling that feeds the IP/domain-layer lookups |
| [whois-lookup](https://github.com/nlink-jp/whois-lookup) | Go | Looks up the registration data of a domain, IP, or AS number (CLI + MCP) — RDAP-first via the IANA bootstrap with a port 43 WHOIS fallback for RDAP-less ccTLDs (.jp), in-house IDN punycode, local TTL cache; no credentials. The registration-focused sibling of asn-lookup and abuse-lookup |

### lab-series — Experimental projects

Works in progress. APIs, features, and interfaces may change without notice.

| Tool | Lang | Description |
|------|------|-------------|
| [llm-othello](https://github.com/nlink-jp/llm-othello) | Go | Browser-based Othello against a local LLM — server-side move generation via OpenAI-compatible API |
| [m5-clock](https://github.com/nlink-jp/m5-clock) | C++ | NTP-synchronized digital clock for M5Stack Core2 — night mode, RTC backup, SD card config |
| [m5-data-receiver](https://github.com/nlink-jp/m5-data-receiver) | Bash/CFn | Serverless AWS backend for m5-vehicle-logger — API Gateway + Lambda + S3 with deploy/destroy scripts |
| [m5-vehicle-logger](https://github.com/nlink-jp/m5-vehicle-logger) | C++ | Vehicle data logger for M5Stack — GNSS + 9-axis IMU + barometer, 3-page display, gravity compensation |
| [slack-monitor](https://github.com/nlink-jp/slack-monitor) | Python | Real-time Slack channel summarizer with local/cloud LLM and Textual TUI |

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
| [lite-rag](https://github.com/nlink-jp/lite-rag) | Go | RAG CLI for Markdown docs using DuckDB — index and query local knowledge bases |
| [lite-switch](https://github.com/nlink-jp/lite-switch) | Go | Natural language classifier for shell pipelines — routes stdin text to a matching tag via LLM |

### skills-series — Claude Code Skills

Claude Code Skills packaging the organization's workflows — development
process, research, meeting minutes, security analysis, and news
collection. One repository per skill; each releases a skill zip
installable into `~/.claude/skills/`
or uploadable to claude.ai (Settings → Skills).

| Skill | Command | Description |
|-------|---------|-------------|
| [compliance-review](https://github.com/nlink-jp/compliance-review) | `/compliance-review compile \| review` | Two-phase regulation-compliance review — `compile` decomposes your regulation documents into a versioned domain-expert set (full clause text per expert, no RAG, deterministic coverage check), `review` evaluates an application behind a sha256 drift gate and a nonce-isolation preprocessing gate with parallel independent experts, deterministic severity rules, and a two-pass Q&A; successor to the virtual-reviewer PoC |
| [incident-research](https://github.com/nlink-jp/incident-research) | `/incident-research <incident>` | Security incident deep-dive research — collects and reads news and primary sources on one publicly reported incident into a schema-validated JSON report (timeline-centric, three source tiers, confidence-qualified attribution) plus compiled Markdown and a STIX 2.1 bundle of extracted IoCs; incident-side companion to service-research and successor to the ioc-collector CLI |
| [incident-review](https://github.com/nlink-jp/incident-review) | `/incident-review <record>` | Own-incident retrospective analysis — turns your IR communication record (Slack exports, plain-text logs, connector-read channels) into a schema-validated report (summary / activity / roles / process review) plus reusable tactic knowledge, behind a defang and nonce-isolation preprocessing gate; successor to the ai-ir / ai-ir2 CLIs |
| [mcp-tactics](https://github.com/nlink-jp/mcp-tactics) | `/mcp-tactics` | Cross-cutting tactics book for the organization's MCP servers and proxies — decision tables from input artifact to route, cross-server chains, and a four-tier escalation doctrine ranked by who can observe the query: no external observer, third party, target contact via urlscan, target contact from our own IP — plus the caveat that the ladder ranks who sees that you asked, not who sees the material you send |
| [meeting-notes](https://github.com/nlink-jp/meeting-notes) | `/meeting-notes <transcript>` | Meeting transcript to structured minutes — validated 3-layer JSON (verbatim quotes / decisions with rationale / summaries) compiled to Markdown or HTML; successor to the meeting-note CLI |
| [news-digest](https://github.com/nlink-jp/news-digest) | `/news-digest --repo <corpus>` | Feed collection and digesting — the agent scores novelty, significance and relevance behind a nonce-isolation gate and never writes a priority, which a swappable profile's decision table derives; continuing stories are tracked so a rehash with no new facts is named as such. The engine is public and holds no data: the feed list, relevance profile and article corpus live in a private corpus repository joined by a versioned contract; first-time setup through scheduled operation is an agent-runnable runbook |
| [rfp](https://github.com/nlink-jp/rfp) | `/rfp [tool-name]` | Interactive RFP facilitation — collects requirements through Q&A against CONVENTIONS.md Phase 1 and generates structured RFP documents |
| [service-research](https://github.com/nlink-jp/service-research) | `/service-research <name>` | Product/service risk research — reads ToS, privacy-policy, and security primary sources on the web into a schema-validated JSON report with a three-tier risk rating plus compiled Markdown; successor to the product-research CLI |

### util-series — General-purpose data utilities

Pipe-friendly tools for data transformation and processing.

| Tool | Lang | Description |
|------|------|-------------|
| [active-lens](https://github.com/nlink-jp/active-lens) | Go | Content-free Mac activity tracker — records only that input happened (idle/display/lock via CoreGraphics, no permissions) and classifies each moment operating/present/away; derives work **sessions** (never split at midnight, filed under a configurable logical day) into a per-day work log via `timeline`, and the session in progress via `now`. darwin/arm64 |
| [active-lens-gui](https://github.com/nlink-jp/active-lens-gui) | Swift | macOS work-log menu-bar app — a native SwiftUI front-end over active-lens showing the current state + the active time of the session you are in, with a calendar-style work timeline (day columns, hover for a block's start/end/duration) and a per-day work log |
| [agent-board](https://github.com/nlink-jp/agent-board) | Go | Machine-local shared knowledge board for concurrent AI agent sessions — append-only records posted as claims, delivered as per-turn deltas through Claude Code / gem-agent hooks, path claims that refuse another session's edits, and a write-side evaluation ladder (schema, duplicate, rate, credential and PII floors, entropy quarantine) instead of a human gate; one binary with CLI, hook and MCP faces |
| [ask-gemini-mcp](https://github.com/nlink-jp/ask-gemini-mcp) | Go | MCP server exposing `ask_gemini(prompt)` — forwards to Vertex AI Gemini for second-opinion consultations from AI coding agents, with structured errors and content-filter detection |
| [ask-llm-mcp](https://github.com/nlink-jp/ask-llm-mcp) | Go | MCP server exposing `ask_llm(prompt)` — forwards to an OpenAI API-compatible endpoint (primary target: local LM Studio) for second-opinion consultations from AI coding agents, with optional Bearer auth, retry/backoff, and reasoning stripping |
| [bigquery-mcp](https://github.com/nlink-jp/bigquery-mcp) | Go | Protection-first BigQuery MCP server (6 tools: `list_datasets` / `list_tables` / `describe_table` / `dry_run` / `query` / `get_usage`) — every query is dry-run first and refused unless BigQuery classifies it as a single SELECT inside the dataset allowlist and the byte budget; runs as a named job with `maximumBytesBilled`, returns column-keyed rows under explicit caps with truncation accounting, and reports every failure as `{code, message, retryable, details}`; Application Default Credentials, no SDK, one instance per billing project |
| [cclaude](https://github.com/nlink-jp/cclaude) | Bash | Containerized Claude Code — run Claude Code in an isolated container with project isolation |
| [claude-usage-lens](https://github.com/nlink-jp/claude-usage-lens) | Go | Token usage & cost analysis for Claude Code / Cowork — parses local session logs, computes API list-price-equivalent cost into a durable SQLite store, and reports by day/session/project/model with near-real-time `watch`, period analysis, `verify` against Cowork audit ground truth, configurable per-model pricing, `reprice` to apply rate changes to already-stored history, and real-quota `calibrate`/`limits` deriving the effective weekly cap from official `/usage` readings (no private API) |
| [claude-usage-lens-gui](https://github.com/nlink-jp/claude-usage-lens-gui) | Swift | macOS menu-bar app for Claude usage cost — a native SwiftUI front-end over claude-usage-lens showing today's cost (price/tokens) in the menu bar, expanding into Swift Charts analysis (daily trend, per-model stacking, top projects), with a weekly budget monitor calibratable to the real limit from official `/usage` readings, showing use/remaining in both amount and percent and projecting from the week's pace whether the budget will be overrun |
| [chrome-pilot-mcp](https://github.com/nlink-jp/chrome-pilot-mcp) | Go | Browser automation for an LLM agent (MCP) with no supply chain to trust — a single static binary with zero external modules (`go.mod` has no `require`, including a hand-written RFC 6455 client) that speaks the Chrome DevTools Protocol directly, drives the Chrome you already have, and downloads nothing at run time. 27 tools cover pages, input, accessibility snapshots, screenshots, script evaluation, console, network, emulation, and screencast recorded as an animated GIF built with the Go standard library. Snapshots also recover the clickable elements the accessibility tree omits — icon-only buttons and empty click targets an agent otherwise cannot address — and an action that opens a JavaScript dialog reports it at once instead of stalling on the blocked renderer. Where the agent may send the browser is bounded by startup-only host allow/block lists that no tool can widen, enforced at the tool arguments and again at the CDP layer so in-page fetch, redirects and subresources are covered; profiles are throwaway by default, and the user's real Chrome profile is refused |
| [csv-to-json](https://github.com/nlink-jp/csv-to-json) | Go | Convert CSV data to a JSON array |
| [data-analyzer](https://github.com/nlink-jp/data-analyzer) | Go | Large-scale JSON/JSONL data analysis using local LLMs — sliding window + progressive summarization |
| [data-toolbox-mcp](https://github.com/nlink-jp/data-toolbox-mcp) | Go | MCP server exposing DuckDB analysis and containerized Python execution (9 tools: `load_data` / `query_data` / `execute_code` / `list_workspaces` / `describe_workspace` / `delete_workspace` / `describe_runtime` / `attach_files` / `load_from_work`) — workspace-scoped DuckDB + Podman sandbox, structured tool errors, bring your own LLM client |
| [eml-to-jsonl](https://github.com/nlink-jp/eml-to-jsonl) | Go | Parse .eml files and output structured JSONL — headers, body, attachments |
| [gem-image](https://github.com/nlink-jp/gem-image) | Go | Image generation and editing CLI — text-to-image and image editing via Vertex AI Gemini (Nano Banana 2) |
| [gem-query](https://github.com/nlink-jp/gem-query) | Go | Natural language data analysis CLI — interactive SQL generation for DuckDB/SQLite via Vertex AI Gemini |
| [gem-rag](https://github.com/nlink-jp/gem-rag) | Python | Gemini-powered RAG CLI for Markdown documents — index, search, and answer questions using Vertex AI embeddings and DuckDB |
| [gem-scribe](https://github.com/nlink-jp/gem-scribe) | Go | Speech-to-text CLI and MCP server on Vertex AI's dedicated transcription model — the model returns speaker turns and word timings as structured data, so no language model authors the transcript's JSON. Cloud counterpart of voice-scribe |
| [gem-search](https://github.com/nlink-jp/gem-search) | Go | Agentic web search — autonomous research via Vertex AI Gemini with Google Search Grounding, Markdown/JSON reports |
| [gem-summary](https://github.com/nlink-jp/gem-summary) | Go | Single-call text summarisation CLI via Vertex AI Gemini — automatic chunked + parallel + merge fallback for over-context-window inputs, prompt-injection defended |
| [gem-usage-lens](https://github.com/nlink-jp/gem-usage-lens) | Go | Token usage & cost analysis for gem-agent (Vertex AI Gemini) — parses the session transcripts' accounting records into a durable SQLite store, prices them at the Vertex AI list price (thinking as output, cached prompt as a share, grounding per request, regional multiplier) and reports by day/session/project/model/call source with `watch`, `reprice`, `verify` of the accounting checksum, and a calendar-month `budget` with a pace forecast |
| [gem-usage-lens-gui](https://github.com/nlink-jp/gem-usage-lens-gui) | Swift | macOS menu-bar app for gem-agent usage cost — a native SwiftUI front-end over gem-usage-lens showing today's cost (price/tokens) in the menu bar, expanding into Swift Charts analysis (daily trend, per-model stacking, by call source, top projects), with a calendar-month budget monitor showing use/remaining in both amount and percent and projecting from the month's pace whether the budget will be overrun |
| [grid-edit](https://github.com/nlink-jp/grid-edit) | Swift | Native macOS CSV/TSV editor (AppKit, NSDocument + NSTableView) — csv-editor's successor: encoding auto-detect (UTF-8/BOM/Shift_JIS/CP932), delimiter auto-detect (comma/tab/semicolon), IME-safe editing, rectangular selection, TSV clipboard with paste confirmation, find & replace, sort, row/column ops, variable row heights for multiline cells |
| [image-forge](https://github.com/nlink-jp/image-forge) | Go | Local diffusion image-generation engine + model-management CLI for macOS (Apple Silicon) — SDXL/anime and general models via stable-diffusion.cpp (CGO/Metal, single binary); per-model gotchas (CLIP-skip/VAE/resolution/v-pred) hidden behind profiles; txt2img/img2img/inpaint/ControlNet/LoRA, GGUF quantization, multi-component (FLUX/SD3.5/Z-Image/Anima), resident serve mode; registry manages diffusion / LoRA / ControlNet / upscaler kinds with architecture compatibility + curated LoRA catalog with trigger words; models can be relocated to another disk (`models relocate`), and a model whose weight files are missing is reported rather than failing at render time |
| [image-forge-gui](https://github.com/nlink-jp/image-forge-gui) | Swift | Native macOS (SwiftUI) front-end for the image-forge CLI — exploratory local image generation: Composer (prompt/negative, model picker with arch + content rating, Advanced sampler/scheduler/clip-skip, LoRA stacking with per-LoRA weights, init-image for img2img) → Generate (single or a batch of up to 50, stopped either at once or after the image in progress) → Gallery (lightbox, multi-select with batch delete/export/move, ESRGAN upscale, switchable libraries, prompt / full-parameter reuse); drives the resident serve engine; bundles the signed CLI |
| [instant-translate](https://github.com/nlink-jp/instant-translate) | Swift | Lightweight macOS menu-bar translator built on the on-device Translation framework (no LLM, no network, no special permissions) — auto-detected language routing with a configurable secondary language (ambiguous input resolves toward your own languages, no OS language-picker interruptions), source-pin + manual target pickers, debounced auto-translate, a global hotkey (⌥⌘T, rebindable) with clipboard seeding, OS-supported languages with regional variants distinguished (English (US) vs English (UK), …), and launch-at-login; an always-present status line names every state the panel is in — including the ones where it withholds a translation on purpose (IME composing, language not identifiable yet) — and framework failures are classified into a cause, a fix naming the control that applies it, and a selectable technical tag for bug reports. darwin/arm64 |
| [json-filter](https://github.com/nlink-jp/json-filter) | Go | Extract, validate, prettify, and repair JSON from arbitrary text streams |
| [json-to-sqlite](https://github.com/nlink-jp/json-to-sqlite) | Go | Load JSON data into SQLite with automatic schema inference |
| [json-to-table](https://github.com/nlink-jp/json-to-table) | Go | Format a JSON array into text, Markdown, HTML, CSV, PNG, or Slack Block Kit tables |
| [jstats](https://github.com/nlink-jp/jstats) | Go | SPL-style stats aggregations for JSON streams — count, avg, p95, stdev, values, and more |
| [jviz](https://github.com/nlink-jp/jviz) | Go | Visualize JSON arrays as interactive charts in the browser — bar, line, pie, table with live SSE updates |
| [load-spinner](https://github.com/nlink-jp/load-spinner) | Swift | macOS menu-bar CPU/GPU load indicator — a lit segment travels around a fixed circle/square at a speed proportional to load, alongside an optional memory gauge that fills with usage; modes for max/CPU/GPU/both (per-source shape + color), optional vertical CPU/GPU/MEM badges, and a click panel that flips between a live readout (gauges + a 3-minute Swift Charts history + a button through to Activity Monitor) and its settings. GPU via IOKit, degrading to CPU-only when unavailable. darwin/arm64 |
| [lookup](https://github.com/nlink-jp/lookup) | Go | Enrich JSON/JSONL streams by matching fields against CSV/JSON data sources |
| [mail-analyzer](https://github.com/nlink-jp/mail-analyzer) | Go | Suspicious email analyzer — rule-based indicators + Gemini LLM content analysis for .eml/.msg files |
| [mail-analyzer-gui](https://github.com/nlink-jp/mail-analyzer-gui) | Swift | macOS desktop GUI for mail-analyzer — drag & drop email analysis (Apple Mail multi-message supported) |
| [mail-analyzer-local](https://github.com/nlink-jp/mail-analyzer-local) | Go | Local LLM version of mail-analyzer — email analysis via OpenAI-compatible API (LM Studio, Ollama) |
| [markdown-viewer](https://github.com/nlink-jp/markdown-viewer) | Go | Single-binary local Markdown viewer — renders GFM, Mermaid, and syntax-highlighted code in the browser |
| [mcp-bridge](https://github.com/nlink-jp/mcp-bridge) | Go | Bridges stdio MCP clients to Streamable HTTP MCP servers that require a pre-registered OAuth client — Slack, GitHub Apps, Entra ID and other providers without dynamic client registration, which a client's built-in OAuth cannot reach. Zero dependencies |
| [msg-to-jsonl](https://github.com/nlink-jp/msg-to-jsonl) | Go | Parse Outlook .msg files and output structured JSONL — same schema as eml-to-jsonl |
| [nvme-lens](https://github.com/nlink-jp/nvme-lens) | Swift | macOS menu-bar monitor for NVMe SSD temperature and endurance — reads SMART through IOKit directly (no smartmontools, no root, no daemon) and judges on the hottest Temperature Sensor rather than the composite value, which understates the hotspot by 17–21 °C; six-hour sparklines in the panel, up to ninety days across seven metrics in History with outages drawn as gaps, and alerts on sustained heat, endurance, media errors and abnormal power-cycle rates. Internal and Thunderbolt/USB4 NVMe only — macOS has no SMART path to USB-attached drives, which are listed with the reason |
| [pptx-to-markdown](https://github.com/nlink-jp/pptx-to-markdown) | Python | Convert `.pptx` presentations to structured Markdown for LLM analysis |
| [rex](https://github.com/nlink-jp/rex) | Go | Extract fields from text using named regex capture groups — outputs JSON |
| [sdate](https://github.com/nlink-jp/sdate) | Go | Calculate timestamps using Splunk-like relative time modifiers (e.g., `-1d@d`) |
| [sensor-lens](https://github.com/nlink-jp/sensor-lens) | Go | Collect SwitchBot temperature, humidity and CO2 into a local SQLite history — quota-aware polling, CSV backfill for what the API cannot serve |
| [sensor-lens-gui](https://github.com/nlink-jp/sensor-lens-gui) | Swift | macOS menu-bar readout of your SwitchBot sensors — six-hour sparklines, CO2 alerts, and it collects while it runs |
| [share-mounter](https://github.com/nlink-jp/share-mounter) | Swift | macOS menu-bar app that auto-mounts SMB shares at login **without opening a Finder window** — mounts via NetFS so shares appear in the Finder sidebar as network volumes; multiple shares with per-share auto-mount at login (SMAppService), Keychain-stored credentials, reachability-gated mount and re-mount on wake/network recovery. darwin/arm64 |
| [shell-agent-v2](https://github.com/nlink-jp/shell-agent-v2) | Go/React | Successor to shell-agent — Wails desktop app with interactive data analysis, session-scoped DuckDB, hybrid LLM (Local + Vertex AI), per-session container sandbox (shell + Python), global Findings, unified MITL across analysis/shell/sandbox/MCP |
| [splunk-mcp](https://github.com/nlink-jp/splunk-mcp) | Go | MCP server for Splunk search over the REST API (10 tools: `run_query` / `start_query` / `check_job` / `get_results` / `cancel_job` / `list_indexes` / `list_sourcetypes` / `list_saved_searches` / `run_saved_search` / `get_usage`) — asynchronous job pattern guarantees exact result counts (never oneshot/preview), large result sets delivered as JSONL files without truncation, destructive-SPL guard, one instance per Splunk host |
| [status-lens](https://github.com/nlink-jp/status-lens) | Swift | macOS menu-bar watcher for Statuspage-hosted status pages (Claude by default; GitHub or any Statuspage URL as profiles) — per-profile "label + shape symbol" display dual-encoded in color and shape, worst-of aggregation mode, detail popover (components / active incidents / scheduled maintenance), notifications on degradation/recovery crossings only, unreachable pages surfaced as a distinct gray `?`. darwin/arm64 |
| [task-clock](https://github.com/nlink-jp/task-clock) | Go | Resident macOS scheduler that does not trust launchd's timing engine — launchd's timer coalescing can silently delay or drop periodic jobs, and its timer state cannot even be queried, so task-clock evaluates cron itself (launchd kept for KeepAlive residency only) and records every fire as scheduled-vs-actual (`on_time` / `queued` / `missed` with reasons); overlap policies (queue-one / skip / kill-and-restart), catch-up, a watermark trigger (fire N after the last *success* — self-healing for variable-duration batch jobs), deterministic jitter, per-run stdout+stderr capture, notification hooks with an overrun-streak early warning, and a localhost token-authenticated HTTP trigger API. darwin/arm64 |
| [task-clock-gui](https://github.com/nlink-jp/task-clock-gui) | Swift | Menu-bar front end for task-clock — a quiet-by-default clock that speaks only when it matters (overrun badge with the overrun duration, a distinct question-mark state when the daemon is unreachable); pilot-lamp daemon control (lamp = actual state, power switch = launch-agent registration, Restart for a broken one), per-task rows with per-second countdowns, run-now, persistent on/off switches and reveal-log, a per-task scheduled-vs-actual run-history view (one line per fire with start delay, duration and result), notifications for overrun entry / run failure / daemon-down (deliberate stops stay silent), launch-at-login; bundles the signed task-clock CLI as its only data path. macOS 14+, darwin/arm64 |
| [url-shelf](https://github.com/nlink-jp/url-shelf) | Swift | macOS menu-bar shelf of URL notes kept as plain `.webloc` files — the folder tree *is* the classification, so Finder stays the editor and the records outlive the app; per-entry **private-window** opening (measured flags for Firefox/Chrome/Edge/Brave/Vivaldi, Safari normal-only) with entry > folder > global inheritance, disabled rather than downgraded when no private browser is set, Option to invert per click, drag a URL onto the icon to file it. No network access. darwin/arm64 |
| [video-studio-mcp](https://github.com/nlink-jp/video-studio-mcp) | Go | MCP server that assembles a narrated presentation video (MP4) from a page manifest (image + audio per page) — a pure ffmpeg compositor paired with voice-studio-mcp; per-page audio sets each page's duration (exact A/V sync), per-page chapter markers, opt-in captions (burned-in via bundled M PLUS 1p Go-rendered overlay — no libfreetype needed — and/or a toggleable mov_text closed-caption track), per-call canvas override (16:9/9:16/1:1), async rendering with check_job. `transition: "fade"` dips to the canvas background *inside* each page's own duration rather than cross-fading, so the exact-duration guarantee, the chapter/caption timelines, and the stream-copy concat all survive |
| [voice-scribe](https://github.com/nlink-jp/voice-scribe) | Go | Local speech-to-text for macOS (CLI + MCP) — transcribes any container AVFoundation can read with whisper.cpp on Metal, statically linked so there is no ffmpeg and no runtime dependency beyond the system frameworks; a curated model catalog defaults to large-v3-turbo — measured on-machine to beat the Japanese-specialised kotoba-whisper even on Japanese, which stays in the catalog — voice-activity gating (`--vad`, also over MCP) suppresses hallucinated text over silence, speaker diarization via sherpa-onnx labels who is speaking, and diagnostics warn when diarization looks over-split or the decoder fell into a repetition loop rather than handing back a well-formed wrong answer in silence. Output uses the shared transcript envelope, so downstream tools parse cloud and local transcripts with one parser. No API key, and no audio leaves the machine. The local counterpart of gem-scribe and the reverse direction of voice-studio-mcp |
| [voice-studio-mcp](https://github.com/nlink-jp/voice-studio-mcp) | Go | MCP server giving AI agents local multi-speaker Japanese speech synthesis for narrated audio (radio drama, audiobook, podcast, briefing) — Japanese only; AivisSpeech Engine backend, script JSONL batch synthesis with content-hash cache, pronunciation dictionaries, ffmpeg mastering (mp3/m4b chapters, loudnorm, credits), voice-model license review workflow, bundled multi-actor-narration Claude Code skill |
| [webhook-relay](https://github.com/nlink-jp/webhook-relay) | Go | Authenticated webhook receiver — writes payloads to GCS via Cloud Run Service with VPC isolation |
| [zip-porter](https://github.com/nlink-jp/zip-porter) | Swift | Windows-safe ZIP creation/extraction for macOS (AppKit GUI + embedded CLI) — junk files excluded, NFC UTF-8 names (no split dakuten) with CP932 legacy mode, AES-256/ZipCrypto passwords, CP932 auto-detection and AES decryption on extract, configurable extraction destination and folder policy. Several archives selected in Finder extract as one job with one progress bar, one prompt and one result ([ADR-0004](https://github.com/nlink-jp/zip-porter/blob/main/docs/en/adr/0004-batch-completion.md)). Hardened extraction ([ADR-0001](https://github.com/nlink-jp/zip-porter/blob/main/docs/en/adr/0001-extraction-hardening.md)): zip-slip guard, fail-fast decompression-bomb limits, pre-flight space budget, overlapping-entry rejection, archive permissions masked by the process umask, `com.apple.quarantine` propagation to every extracted item — folders included, so Gatekeeper still evaluates an app that arrives inside a ZIP — duplicate-name uniquification, and malformed headers rejected rather than trusted. Cross-verified against Info-ZIP/ditto/7-Zip and real-machine verified on Windows Explorer. darwin/arm64 |

### archive-series — Archived projects

Projects that have been retired or superseded live in
[**archive-series**](https://github.com/nlink-jp/archive-series), grouped by the
series each came from. Those repositories are read-only on GitHub: their
released assets stay downloadable, but they take no further changes.

Where a project has a successor, the archive catalog names it.
