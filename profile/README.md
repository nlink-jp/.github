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
| [abuse-lookup](https://github.com/nlink-jp/abuse-lookup) | Go | Checks IP address reputation against the AbuseIPDB API (CLI + MCP) — abuse score, report history, usage type, and ISP, cached locally with a TTL; large `get_reports` pages are file-mediated to an agent-provided workspace. The online, reputation-focused sibling of asn-lookup |
| [ai-ir](https://github.com/nlink-jp/ai-ir) | Python | ~~AI-powered incident response — analyzes Slack IR exports to generate summaries, activity reports, and reusable tactics~~ **Archived** — superseded by [incident-review](https://github.com/nlink-jp/incident-review) |
| [ai-ir2](https://github.com/nlink-jp/ai-ir2) | Python | ~~Next-gen IR analysis — one-stop Gemini pipeline producing Markdown, self-contained HTML, and knowledge documents~~ **Archived** — superseded by [incident-review](https://github.com/nlink-jp/incident-review) |
| [asn-lookup](https://github.com/nlink-jp/asn-lookup) | Go | Local IP↔AS lookups from the IPinfo Lite database (CLI + MCP) — downloads the free Lite DB once and answers IP→ASN/country and ASN→prefixes fully offline; large reverse-lookup results are file-mediated to an agent-provided workspace, with `get_usage`/`update_db` MCP tools |
| [cti-graph](https://github.com/nlink-jp/cti-graph) | Python | ~~Local-first attack graph analysis — STIX 2.1 ingestion, PIR-driven weighting, choke-point detection, FastAPI API~~ **Archived** — no longer used or maintained |
| [cti-primer](https://github.com/nlink-jp/cti-primer) | Python | ~~Local-first CTI PIR generation — converts business context into Priority Intelligence Requirements using local LLMs or dictionary-only mode~~ **Archived** — no longer used or maintained |
| [doh-lookup](https://github.com/nlink-jp/doh-lookup) | Go | Collects a domain's DNS records over DoH (CLI + MCP) — queries Cloudflare/Google out-of-band over HTTPS so investigative lookups stay distinguishable from ordinary DNS; forward profile (A/AAAA/MX/TXT/NS/SOA/CAA) + PTR reverse, bulk input, states the resolver/endpoint and DNSSEC AD in every result; no credentials. The DNS-resolution sibling of asn-lookup and whois-lookup |
| [icloud-relay-lookup](https://github.com/nlink-jp/icloud-relay-lookup) | Go | Reports whether an IP is an Apple iCloud Private Relay egress IP (CLI + MCP) — offline longest-prefix match from a cached copy of Apple's egress list, with its geo hints (country/region/city); ETag revalidation, no credentials. The Apple-side sibling of tor-exit-lookup |
| [ioc-collector](https://github.com/nlink-jp/ioc-collector) | Python | ~~Research security incidents from URLs or CVE IDs — extracts IoCs into Markdown and STIX 2.1 bundles~~ **Archived** — superseded by [incident-research](https://github.com/nlink-jp/incident-research) (v0.2+) |
| [ir-hub](https://github.com/nlink-jp/ir-hub) | Go | IR lifecycle hub — resident Slack ChatOps bot that opens a channel per case, tracks the response with ACL-gated commands, and ingests messages for postmortems and knowledge reuse |
| [ir-timeline](https://github.com/nlink-jp/ir-timeline) | Go | IR timeline recorder — single-binary, browser-based tool for tracking IR events with text, images, tags, and time deltas |
| [ir-tracker](https://github.com/nlink-jp/ir-tracker) | Python | ~~Live IR tracker — continuous ingestion, segmented analysis, and timeline visualization for ongoing incidents via Gemini~~ **Archived** — no longer used or maintained |
| [mac-lookup](https://github.com/nlink-jp/mac-lookup) | Go | Resolves a MAC address or BSSID to its manufacturer (CLI + MCP) — offline longest-prefix match (36/28/24-bit) against a cached copy of the IEEE registries, and classifies the address first: a randomized or otherwise locally administered address is reported as having no vendor to find, not as an unidentified device; no credentials. The L2 sibling of asn-lookup |
| [mail-triage](https://github.com/nlink-jp/mail-triage) | Python | ~~GCS-based email triage — classifies eml/msg files with Gemini LLM and posts results to Slack via Cloud Run Jobs~~ **Archived** — no longer used or maintained |
| [malware-lookup](https://github.com/nlink-jp/malware-lookup) | Go | Answers whether a file hash (MD5/SHA1/SHA256) is a publicly known legitimate file or known malware (CLI + MCP) — layers CIRCL hashlookup (known-good), Team Cymru MHR (malicious, queried over DoH so hashes never cross the local resolver in cleartext) and MalwareBazaar (family/tags) into one lookup with a four-way verdict: known_good / known_malware / unknown / conflicting, the last flagging abused legitimate software or false positives for scrutiny. Exists because VirusTotal's free API forbids workflow integration — the VT API is never called; results carry a human-facing GUI link instead. Only the optional abuse.ch Auth-Key as a credential. The file-hash sibling of abuse-lookup and urlscan-lookup |
| [news-collector](https://github.com/nlink-jp/news-collector) | Python | News collection agent — collects, tags, summarizes, translates, and delivers curated news digests via Gemini + Slack |
| [otx-lookup](https://github.com/nlink-jp/otx-lookup) | Go | Attaches campaign context to an indicator of compromise from the community reports ("pulses") of the LevelBlue Open Threat Exchange (CLI + MCP) — adversary, malware family, ATT&CK techniques, targeted industries and countries, each counted by how many independent reports named it, then the pivot from a pulse to the other indicators it carries. The one question the rest of the lookup family cannot answer: every sibling returns one attribute of one indicator, while this returns whether the indicator belongs to a known campaign; the sections a sibling already owns (reputation, passive_dns, malware, url_list) are off by default so the two never compete. Reads only a third-party index, so no packet reaches the target. The API key is optional — indicator lookups and the campaign pivot both work without one; a key adds pulse search and an exact indicator total. An empty answer is reported as clean only when every lookup succeeded, never when one failed |
| [pcap-analyzer-mcp](https://github.com/nlink-jp/pcap-analyzer-mcp) | Go | Analyses pcap/pcapng captures for an LLM agent (MCP) — a digest-pinned tshark runs in a rootless, network-less container with the capture mounted read-only and never copied, so results are reproducible and the evidence stays byte-identical; small results come back inline and large ones as JSONL/CSV in the workspace, always reporting how many packets the filter actually hit. Content read off the wire is framed as untrusted and recovered files are stored under their own SHA-256, never executable — the capture-layer sibling that feeds the IP/domain/URL lookups |
| [product-research](https://github.com/nlink-jp/product-research) | Python | ~~Research products and services — outputs ToS, privacy, and data security analysis as structured reports~~ **Archived** — superseded by [service-research](https://github.com/nlink-jp/service-research) |
| [rdns-lookup](https://github.com/nlink-jp/rdns-lookup) | Go | Looks up the relationships around an IP or domain in the free 6-billion-record ip.thc.org index (CLI + MCP) — the domains associated with an address or octet-boundary block, a domain's subdomains, and the domains that CNAME to it. Reads only a third-party index, so no packet reaches the target; note this is not PTR but an aggregate of PTR names, A-record matches, and CT-log names, so `1.1.1.1` yields 83,216 records where a PTR yields one. Every result states how many records upstream holds against how many were retrieved, so a capped answer is never mistaken for a complete one; local TTL cache, rate-limit pacing, no credentials. The relationship-breadth sibling of doh-lookup and whois-lookup |
| [tor-exit-lookup](https://github.com/nlink-jp/tor-exit-lookup) | Go | Reports whether an IP is a Tor Exit node (CLI + MCP) — offline membership lookup from a cached copy of the Tor Project's torbulkexitlist, enriched with exit-addresses metadata; no credentials. The offline sibling of asn-lookup and abuse-lookup |
| [urlscan-lookup](https://github.com/nlink-jp/urlscan-lookup) | Go | Investigates a suspicious URL via the urlscan.io API (CLI + MCP) — an active scan submits the URL to urlscan's sandbox browser for its behaviour, verdict, observed IPs/domains, and screenshot (private by default; public must be requested explicitly), plus a passive search of the historical public-scan database; async job flow, TTL cache, free-plan API key. The URL-layer sibling that feeds the IP/domain-layer lookups |
| [whois-lookup](https://github.com/nlink-jp/whois-lookup) | Go | Looks up the registration data of a domain, IP, or AS number (CLI + MCP) — RDAP-first via the IANA bootstrap with a port 43 WHOIS fallback for RDAP-less ccTLDs (.jp), in-house IDN punycode, local TTL cache; no credentials. The registration-focused sibling of asn-lookup and abuse-lookup |

### lab-series — Experimental projects

Works in progress. APIs, features, and interfaces may change without notice.

| Tool | Lang | Description |
|------|------|-------------|
| [agent-skeleton](https://github.com/nlink-jp/agent-skeleton) | Python | Autonomous agent skeleton — plan-approve-execute loop, per-tool approval, 2-tier memory compression, MCP support |
| [agentic-web-search](https://github.com/nlink-jp/agentic-web-search) | Go | ~~Agentic web search — autonomous research via local LLM + Brave Search API~~ **FROZEN** (search API ToS concerns) |
| [gem-agent](https://github.com/nlink-jp/gem-agent) | Go | Interactive CLI agent on Vertex AI Gemini — continuity tool for when Claude Code is unavailable; sandboxed file/shell tools, MCP, two-tier auto-approve, session resume, context compaction (macOS) |
| [llm-othello](https://github.com/nlink-jp/llm-othello) | Go | Browser-based Othello against a local LLM — server-side move generation via OpenAI-compatible API |
| [log-analyzer](https://github.com/nlink-jp/log-analyzer) | Python | ~~Large JSONL log analyzer — LLM-driven analysis with timestamp-based chunking for files exceeding context limits~~ **Archived** — no longer used or maintained |
| [m5-clock](https://github.com/nlink-jp/m5-clock) | C++ | NTP-synchronized digital clock for M5Stack Core2 — night mode, RTC backup, SD card config |
| [m5-data-receiver](https://github.com/nlink-jp/m5-data-receiver) | Bash/CFn | Serverless AWS backend for m5-vehicle-logger — API Gateway + Lambda + S3 with deploy/destroy scripts |
| [m5-vehicle-logger](https://github.com/nlink-jp/m5-vehicle-logger) | C++ | Vehicle data logger for M5Stack — GNSS + 9-axis IMU + barometer, 3-page display, gravity compensation |
| [magi-system](https://github.com/nlink-jp/magi-system) | Python | ~~Multi-agent discussion system with 3 AI personas (MELCHIOR / BALTHASAR / CASPER)~~ **Archived** — no longer used or maintained |
| [magi-system2](https://github.com/nlink-jp/magi-system2) | Python | ~~Multi-persona AI discussion — dynamic persona generation, dual memory, adaptive facilitation via Gemini~~ **Archived** — no longer used or maintained |
| [mail-watcher](https://github.com/nlink-jp/mail-watcher) | Bash | ~~Mail monitoring workflow — watches for incoming eml/msg files, analyzes with LLM, and posts Slack notifications~~ **Archived** — no longer used or maintained |
| [mcp-skeleton](https://github.com/nlink-jp/mcp-skeleton) | Python | MCP server skeleton — raw JSON-RPC 2.0 over stdio/SSE with API key auth, for learning MCP internals |
| [meeting-note](https://github.com/nlink-jp/meeting-note) | Python | ~~Meeting minutes structuring tool — audio/transcript to structured JSON via Gemini, then compile to Markdown/HTML~~ **Archived** — superseded by [meeting-notes](https://github.com/nlink-jp/meeting-notes) |
| [sai](https://github.com/nlink-jp/sai) | Python | ~~Context-aware Slack bot with RAG memory and natural language command execution~~ **Archived** — no longer used or maintained |
| [slack-monitor](https://github.com/nlink-jp/slack-monitor) | Python | Real-time Slack channel summarizer with local/cloud LLM and Textual TUI |
| [slack-personal-agent](https://github.com/nlink-jp/slack-personal-agent) | Go/React | ~~Personal Slack knowledge agent — multi-workspace monitoring, channel-scoped RAG over DuckDB with strict 3-tier isolation, Hot/Warm/Cold memory, MITL draft responses~~ **Archived** — no longer used or maintained |
| [virtual-reviewer](https://github.com/nlink-jp/virtual-reviewer) | Python | ~~AI-powered security review system — LLM expert models with full regulation context, no RAG, UNIX pipes~~ **Archived** — superseded by [compliance-review](https://github.com/nlink-jp/compliance-review) |
| [workflow-builder](https://github.com/nlink-jp/workflow-builder) | — | ~~LLM-powered workflow builder — generates shell scripts from natural language using CLI tool registry~~ **Archived** — design phase only; never implemented |

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
| [mcp-tactics](https://github.com/nlink-jp/mcp-tactics) | `/mcp-tactics` | Cross-cutting tactics book for the organization's MCP servers and proxies — decision tables from input artifact to route, cross-server chains, and a four-tier escalation doctrine ranked by who can observe the query: no external observer, third party, target contact via urlscan, target contact from our own IP |
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
| [ask-gemini-mcp](https://github.com/nlink-jp/ask-gemini-mcp) | Go | MCP server exposing `ask_gemini(prompt)` — forwards to Vertex AI Gemini for second-opinion consultations from AI coding agents, with structured errors and content-filter detection |
| [ask-llm-mcp](https://github.com/nlink-jp/ask-llm-mcp) | Go | MCP server exposing `ask_llm(prompt)` — forwards to an OpenAI API-compatible endpoint (primary target: local LM Studio) for second-opinion consultations from AI coding agents, with optional Bearer auth, retry/backoff, and reasoning stripping |
| [cclaude](https://github.com/nlink-jp/cclaude) | Bash | Containerized Claude Code — run Claude Code in an isolated container with project isolation |
| [claude-usage-lens](https://github.com/nlink-jp/claude-usage-lens) | Go | Token usage & cost analysis for Claude Code / Cowork — parses local session logs, computes API list-price-equivalent cost into a durable SQLite store, and reports by day/session/project/model with near-real-time `watch`, period analysis, `verify` against Cowork audit ground truth, configurable per-model pricing, `reprice` to apply rate changes to already-stored history, and real-quota `calibrate`/`limits` deriving the effective weekly cap from official `/usage` readings (no private API) |
| [claude-usage-lens-gui](https://github.com/nlink-jp/claude-usage-lens-gui) | Swift | macOS menu-bar app for Claude usage cost — a native SwiftUI front-end over claude-usage-lens showing today's cost (price/tokens) in the menu bar, expanding into Swift Charts analysis (daily trend, per-model stacking, top projects), with a weekly budget monitor calibratable to the real limit from official `/usage` readings, showing use/remaining in both amount and percent and projecting from the week's pace whether the budget will be overrun |
| [chrome-pilot-mcp](https://github.com/nlink-jp/chrome-pilot-mcp) | Go | Browser automation for an LLM agent (MCP) with no supply chain to trust — a single static binary with zero external modules (`go.mod` has no `require`, including a hand-written RFC 6455 client) that speaks the Chrome DevTools Protocol directly, drives the Chrome you already have, and downloads nothing at run time. 27 tools cover pages, input, accessibility snapshots, screenshots, script evaluation, console, network, emulation, and screencast recorded as an animated GIF built with the Go standard library. Snapshots also recover the clickable elements the accessibility tree omits — icon-only buttons and empty click targets an agent otherwise cannot address — and an action that opens a JavaScript dialog reports it at once instead of stalling on the blocked renderer. Where the agent may send the browser is bounded by startup-only host allow/block lists that no tool can widen, enforced at the tool arguments and again at the CDP layer so in-page fetch, redirects and subresources are covered; profiles are throwaway by default, and the user's real Chrome profile is refused |
| [csv-editor](https://github.com/nlink-jp/csv-editor) | Go/React | ~~CSV/TSV editor GUI for macOS/Windows — UTF-8 (BOM optional)/Shift_JIS/CP932 with auto-detect, virtual scroll for 100k+ rows, IME-safe edit, sort, find/replace, TSV clipboard with shape-mismatch confirmation~~ **Archived** — superseded by [grid-edit](https://github.com/nlink-jp/grid-edit) |
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
| [mail-analyzer-gui](https://github.com/nlink-jp/mail-analyzer-gui) | Rust/Svelte | macOS desktop GUI for mail-analyzer — drag & drop email analysis via Tauri |
| [mail-analyzer-local](https://github.com/nlink-jp/mail-analyzer-local) | Go | Local LLM version of mail-analyzer — email analysis via OpenAI-compatible API (LM Studio, Ollama) |
| [markdown-viewer](https://github.com/nlink-jp/markdown-viewer) | Go | Single-binary local Markdown viewer — renders GFM, Mermaid, and syntax-highlighted code in the browser |
| [mcp-bridge](https://github.com/nlink-jp/mcp-bridge) | Go | Bridges stdio MCP clients to Streamable HTTP MCP servers that require a pre-registered OAuth client — Slack, GitHub Apps, Entra ID and other providers without dynamic client registration, which a client's built-in OAuth cannot reach. Zero dependencies |
| [mcp-guardian](https://github.com/nlink-jp/mcp-guardian) | Go | ~~MCP governance proxy — transparent auditing, OAuth2 auto-discovery, and tool masking for MCP servers~~ **Archived** — bridging half superseded by [mcp-bridge](https://github.com/nlink-jp/mcp-bridge); the governance layer was never adopted in practice |
| [msg-to-jsonl](https://github.com/nlink-jp/msg-to-jsonl) | Go | Parse Outlook .msg files and output structured JSONL — same schema as eml-to-jsonl |
| [nvme-lens](https://github.com/nlink-jp/nvme-lens) | Swift | macOS menu-bar monitor for NVMe SSD temperature and endurance — reads SMART through IOKit directly (no smartmontools, no root, no daemon) and judges on the hottest Temperature Sensor rather than the composite value, which understates the hotspot by 17–21 °C; six-hour sparklines in the panel, up to ninety days across seven metrics in History with outages drawn as gaps, and alerts on sustained heat, endurance, media errors and abnormal power-cycle rates. Internal and Thunderbolt/USB4 NVMe only — macOS has no SMART path to USB-attached drives, which are listed with the reason |
| [pptx-to-markdown](https://github.com/nlink-jp/pptx-to-markdown) | Python | Convert `.pptx` presentations to structured Markdown for LLM analysis |
| [quick-translate](https://github.com/nlink-jp/quick-translate) | Swift | macOS menu-bar-resident translation tool — local LLM via OpenAI-compatible API |
| [rex](https://github.com/nlink-jp/rex) | Go | Extract fields from text using named regex capture groups — outputs JSON |
| [sdate](https://github.com/nlink-jp/sdate) | Go | Calculate timestamps using Splunk-like relative time modifiers (e.g., `-1d@d`) |
| [sensor-lens](https://github.com/nlink-jp/sensor-lens) | Go | Collect SwitchBot temperature, humidity and CO2 into a local SQLite history — quota-aware polling, CSV backfill for what the API cannot serve |
| [sensor-lens-gui](https://github.com/nlink-jp/sensor-lens-gui) | Swift | macOS menu-bar readout of your SwitchBot sensors — six-hour sparklines, CO2 alerts, and it collects while it runs |
| [share-mounter](https://github.com/nlink-jp/share-mounter) | Swift | macOS menu-bar app that auto-mounts SMB shares at login **without opening a Finder window** — mounts via NetFS so shares appear in the Finder sidebar as network volumes; multiple shares with per-share auto-mount at login (SMAppService), Keychain-stored credentials, reachability-gated mount and re-mount on wake/network recovery. darwin/arm64 |
| [shell-agent](https://github.com/nlink-jp/shell-agent) | Go/Swift | ~~macOS LLM chat & agent — MCP support, shell script Tool Calling with MITL, Hot/Warm/Cold memory, multimodal~~ **Archived** — superseded by [shell-agent-v2](https://github.com/nlink-jp/shell-agent-v2) |
| [shell-agent-v2](https://github.com/nlink-jp/shell-agent-v2) | Go/React | Successor to shell-agent — Wails desktop app with interactive data analysis, session-scoped DuckDB, hybrid LLM (Local + Vertex AI), per-session container sandbox (shell + Python), global Findings, unified MITL across analysis/shell/sandbox/MCP |
| [splunk-mcp](https://github.com/nlink-jp/splunk-mcp) | Go | MCP server for Splunk search over the REST API (10 tools: `run_query` / `start_query` / `check_job` / `get_results` / `cancel_job` / `list_indexes` / `list_sourcetypes` / `list_saved_searches` / `run_saved_search` / `get_usage`) — asynchronous job pattern guarantees exact result counts (never oneshot/preview), large result sets delivered as JSONL files without truncation, destructive-SPL guard, one instance per Splunk host |
| [status-lens](https://github.com/nlink-jp/status-lens) | Swift | macOS menu-bar watcher for Statuspage-hosted status pages (Claude by default; GitHub or any Statuspage URL as profiles) — per-profile "label + shape symbol" display dual-encoded in color and shape, worst-of aggregation mode, detail popover (components / active incidents / scheduled maintenance), notifications on degradation/recovery crossings only, unreachable pages surfaced as a distinct gray `?`. darwin/arm64 |
| [url-shelf](https://github.com/nlink-jp/url-shelf) | Swift | macOS menu-bar shelf of URL notes kept as plain `.webloc` files — the folder tree *is* the classification, so Finder stays the editor and the records outlive the app; per-entry **private-window** opening (measured flags for Firefox/Chrome/Edge/Brave/Vivaldi, Safari normal-only) with entry > folder > global inheritance, disabled rather than downgraded when no private browser is set, Option to invert per click, drag a URL onto the icon to file it. No network access. darwin/arm64 |
| [video-studio-mcp](https://github.com/nlink-jp/video-studio-mcp) | Go | MCP server that assembles a narrated presentation video (MP4) from a page manifest (image + audio per page) — a pure ffmpeg compositor paired with voice-studio-mcp; per-page audio sets each page's duration (exact A/V sync), per-page chapter markers, opt-in captions (burned-in via bundled M PLUS 1p Go-rendered overlay — no libfreetype needed — and/or a toggleable mov_text closed-caption track), per-call canvas override (16:9/9:16/1:1), async rendering with check_job. `transition: "fade"` dips to the canvas background *inside* each page's own duration rather than cross-fading, so the exact-duration guarantee, the chapter/caption timelines, and the stream-copy concat all survive |
| [voice-scribe](https://github.com/nlink-jp/voice-scribe) | Go | Local speech-to-text for macOS (CLI + MCP) — transcribes any container AVFoundation can read with whisper.cpp on Metal, statically linked so there is no ffmpeg and no runtime dependency beyond the system frameworks; a curated model catalog defaults to large-v3-turbo — measured on-machine to beat the Japanese-specialised kotoba-whisper even on Japanese, which stays in the catalog — voice-activity gating (`--vad`, also over MCP) suppresses hallucinated text over silence, speaker diarization via sherpa-onnx labels who is speaking, and diagnostics warn when diarization looks over-split or the decoder fell into a repetition loop rather than handing back a well-formed wrong answer in silence. Output uses gem-transcribe's envelope, so downstream tools parse cloud and local transcripts with one parser. No API key, and no audio leaves the machine. The local counterpart of gem-transcribe and the reverse direction of voice-studio-mcp |
| [voice-studio-mcp](https://github.com/nlink-jp/voice-studio-mcp) | Go | MCP server giving AI agents local multi-speaker Japanese speech synthesis for narrated audio (radio drama, audiobook, podcast, briefing) — Japanese only; AivisSpeech Engine backend, script JSONL batch synthesis with content-hash cache, pronunciation dictionaries, ffmpeg mastering (mp3/m4b chapters, loudnorm, credits), voice-model license review workflow, bundled multi-actor-narration Claude Code skill |
| [webhook-relay](https://github.com/nlink-jp/webhook-relay) | Go | Authenticated webhook receiver — writes payloads to GCS via Cloud Run Service with VPC isolation |
| [zip-porter](https://github.com/nlink-jp/zip-porter) | Swift | Windows-safe ZIP creation/extraction for macOS (AppKit GUI + embedded CLI) — junk files excluded, NFC UTF-8 names (no split dakuten) with CP932 legacy mode, AES-256/ZipCrypto passwords, CP932 auto-detection and AES decryption on extract, configurable extraction destination and folder policy. Several archives selected in Finder extract as one job with one progress bar, one prompt and one result ([ADR-0004](https://github.com/nlink-jp/zip-porter/blob/main/docs/en/adr/0004-batch-completion.md)). Hardened extraction ([ADR-0001](https://github.com/nlink-jp/zip-porter/blob/main/docs/en/adr/0001-extraction-hardening.md)): zip-slip guard, fail-fast decompression-bomb limits, pre-flight space budget, overlapping-entry rejection, archive permissions masked by the process umask, `com.apple.quarantine` propagation to every extracted item — folders included, so Gatekeeper still evaluates an app that arrives inside a ZIP — duplicate-name uniquification, and malformed headers rejected rather than trusted. Cross-verified against Info-ZIP/ditto/7-Zip and real-machine verified on Windows Explorer. darwin/arm64 |
