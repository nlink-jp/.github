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
| [confl-cli](https://github.com/nlink-jp/confl-cli) | Python | CLI for Atlassian Confluence Cloud built on the UNIX split — stdout is data, stderr is logs, so it composes with jq and grep. Lists and exports whole space page trees, full-text search over CQL, reads a page or page tree as text/HTML/JSON/storage format, and downloads attachments safely |
| [gem-agent](https://github.com/nlink-jp/gem-agent) | Go | Interactive CLI agent runtime on Vertex AI Gemini — a deliberately minimal, auditable loop of read, edit, shell, MCP and approval, defended by sandbox-exec containment plus human-in-the-loop approval, with no analysis or GUI subsystems. Drop-in with existing projects: it reads their AGENTS.md, CLAUDE.md and .mcp.json as they are |
| [gem-cli](https://github.com/nlink-jp/gem-cli) | Go | Gemini client CLI on Vertex AI — multimodal prompts (image, PDF, audio, video), streaming, interactive chat with session persistence, context caching, Google Search Grounding with citations, native structured output, and a prompt-injection guard. The Gemini-native counterpart to llm-cli’s OpenAI-compatible route |
| [lagent](https://github.com/nlink-jp/lagent) | Go | CLI agent runtime on a local LLM (LM Studio, Ollama) for work that should stay off a cloud API — the same minimal, auditable loop as gem-agent, defended by sandbox-exec containment plus operator approval. Drop-in with existing projects: it reads their AGENTS.md, CLAUDE.md and .mcp.json as they are |
| [llm-cli](https://github.com/nlink-jp/llm-cli) | Go | CLI client for local LLMs over OpenAI-compatible endpoints (LM Studio, Ollama) — streaming prompts, line-by-line JSONL batch runs, multi-image input for VLMs, and JSON-schema structured output that falls back to prompt-injected formatting when the server rejects response_format. Built on nlk; successor to lite-llm |
| [scli](https://github.com/nlink-jp/scli) | Go | Terminal Slack client that acts as you, not a bot — read channels and DMs with threads expanded, post text or Block Kit JSON, upload files, list unread conversations and search the workspace, across multiple workspaces. OAuth 2.0 PKCE login, tokens in the OS keychain |
| [splunk-cli](https://github.com/nlink-jp/splunk-cli) | Go | Pipe-friendly CLI client for the Splunk REST API — run an SPL search synchronously, or start it and poll status and results for long jobs. JSON output composes with jq and json-to-table, and Ctrl+C on a running search offers to cancel it or send it to the background |

### chatops-series — ChatOps workflow tools

Pipe-friendly Slack tools for ChatOps automation and monitoring.

| Tool | Lang | Description |
|------|------|-------------|
| [md-to-slack](https://github.com/nlink-jp/md-to-slack) | Go | Converts Markdown on stdin to a Slack Block Kit JSON payload on stdout — GFM tables become aligned code blocks, H1/H2 become header blocks, H3-H6 bold sections, standalone images become image blocks, and raw HTML is dropped because Slack cannot render it. Pairs with scli for posting |
| [scat](https://github.com/nlink-jp/scat) | Go | Service-facing Slack CLI using bot credentials — posts messages and files, streams stdin, manages channels and invitations, and exports threads as scli-compatible JSON with attachment downloads. Multiple workspace profiles and environment-only server mode support automation; user-authenticated workflows belong to scli |
| [slack-mcp-extender](https://github.com/nlink-jp/slack-mcp-extender) | Go | Per-workspace MCP proxy that transparently forwards Claude’s official Slack MCP while injecting the one capability it lacks: moving real files between Slack and local disk. Every official tool passes through unmodified, and the three added tools live in an explicit ext_ namespace that cannot collide |
| [slack-router](https://github.com/nlink-jp/slack-router) | Go | Daemon that receives Slack slash commands over Socket Mode and dispatches them asynchronously to local shell scripts by a YAML routing table — a ChatOps hub for admin, deploy and LLM workflows. Command metadata arrives on stdin, not argv, so credentials never surface in ps |
| [stail](https://github.com/nlink-jp/stail) | Go | Read-only Slack tail — streams new channel messages in real time over Socket Mode like tail -f, shows the last N, or starts from an absolute timestamp, and exports full channel history to JSON in the export schema shared with scat and scli (a subset of their fields) |
| [swrite](https://github.com/nlink-jp/swrite) | Go | Posts messages and files to Slack from the command line, for bot workflows and shell pipelines — text or Block Kit, file upload with a comment, and a `--stream` mode that batches stdin every 3 seconds. Profile-based config or pure environment variables for containers; auto-joins on not_in_channel |

### cybersecurity-series — Cybersecurity workflow tools

Tools for security investigation, threat intelligence, and incident response — offline-first lookup CLIs + MCP servers alongside AI-assisted analysis tools.

| Tool | Lang | Description |
|------|------|-------------|
| [abuse-lookup](https://github.com/nlink-jp/abuse-lookup) | Go | Checks IP address reputation against the AbuseIPDB API (CLI + MCP) — abuse score, report history, usage type, and ISP, cached locally with a TTL; report pages come back inline, sized by the caller. The online sibling of asn-lookup |
| [asn-lookup](https://github.com/nlink-jp/asn-lookup) | Go | Local IP↔AS lookups from the IPinfo Lite database (CLI + MCP) — downloads the free Lite DB once and answers IP→ASN/country and ASN→prefixes fully offline; a large AS's prefixes come back inline a page at a time |
| [cve-lookup](https://github.com/nlink-jp/cve-lookup) | Go | Context for a CVE from EchelonGraph’s CVE Pulse API (CLI + MCP) — CVSS, CISA KEV, EPSS, SSVC, exploit and patch signals, product matching, vendor advisories and the internet-exposure footprint. No key or account: a single dependency-free binary in place of the vendor’s npx-launched MCP server |
| [doh-lookup](https://github.com/nlink-jp/doh-lookup) | Go | Collects a domain’s DNS records over DoH (CLI + MCP) — queries Cloudflare or Google out-of-band over HTTPS so investigative lookups stay distinguishable from ordinary DNS; forward profile plus PTR reverse, and every result states the resolver, endpoint and DNSSEC AD flag |
| [gti-lookup](https://github.com/nlink-jp/gti-lookup) | Go | Threat context from Google Threat Intelligence (CLI + MCP) — the collections an indicator belongs to, a sample’s sandbox behaviour, corpus-wide IOC search in GTI query syntax, the vulnerability catalogue, and read-only LiveHunt inspection. Standard-tier only, and the one lookup here that needs a commercial licence key |
| [icloud-relay-lookup](https://github.com/nlink-jp/icloud-relay-lookup) | Go | Reports whether an IP is an Apple iCloud Private Relay egress IP (CLI + MCP) — offline longest-prefix match from a cached copy of Apple’s egress list, with its geo hints (country/region/city); ETag revalidation, no credentials. The Apple-side sibling of tor-exit-lookup |
| [ir-timeline](https://github.com/nlink-jp/ir-timeline) | Go | Incident response timeline recorder (single binary) — replaces the Excel IR timeline with a local browser UI: events carry text, images, tags and the delta since the previous one, drawn as a vertical timeline or a per-tag swimlane. One SQLite file per incident, images included |
| [mac-lookup](https://github.com/nlink-jp/mac-lookup) | Go | Resolves a MAC address or BSSID to its manufacturer (CLI + MCP) — offline longest-prefix match (36/28/24-bit) against a cached copy of the IEEE registries, classifying the address first: a randomized or locally administered MAC is reported as having no vendor to find, not as an unknown device |
| [malware-lookup](https://github.com/nlink-jp/malware-lookup) | Go | Checks a file hash against three public indexes at once (CLI + MCP) — CIRCL hashlookup, Team Cymru MHR (over DoH) and MalwareBazaar, layered into one four-way verdict: known_good, known_malware, unknown, or conflicting (known-good and flagged at the same time). VirusTotal’s API is never called |
| [news-collector](https://github.com/nlink-jp/news-collector) | Python | News collection agent for daily batch runs (Gemini + Google Search Grounding) — collects articles per topic from a TOML keyword config, deduplicates into SQLite, then tags, summarizes and translates each one, and delivers the digest to Slack or a local web dashboard |
| [otx-lookup](https://github.com/nlink-jp/otx-lookup) | Go | Attaches campaign context to an indicator from LevelBlue OTX’s community reports, or “pulses” (CLI + MCP) — adversary, malware family, ATT&CK techniques and targeted industries, each counted by how many independent reports named it. Reads only a third-party index, so no packet reaches the target |
| [pcap-analyzer-mcp](https://github.com/nlink-jp/pcap-analyzer-mcp) | Go | pcap/pcapng analysis as an MCP server — a digest-pinned tshark runs in a network-less Podman container with the capture mounted read-only, so an agent narrows a GB-scale capture step by step under explicit bounds instead of drowning in tshark -V. Wire content is framed as untrusted |
| [rdns-lookup](https://github.com/nlink-jp/rdns-lookup) | Go | Maps the relationships around an IP or domain in the ip.thc.org index (CLI + MCP) — the domains on an address or octet-boundary block, a domain’s subdomains, and the domains that CNAME to it. An aggregate index, not PTR — 1.1.1.1 yields 83,216 records against a PTR’s one |
| [tor-exit-lookup](https://github.com/nlink-jp/tor-exit-lookup) | Go | Reports whether an IP is a Tor Exit node (CLI + MCP) — offline membership lookup from a cached copy of the Tor Project’s torbulkexitlist, enriched with exit-addresses metadata; no credentials. The offline sibling of asn-lookup and abuse-lookup |
| [urlscan-lookup](https://github.com/nlink-jp/urlscan-lookup) | Go | Investigates a suspicious URL via the urlscan.io API (CLI + MCP) — an active scan submits it to urlscan’s sandbox browser for behaviour, verdict, observed IPs/domains and a screenshot (private by default), alongside a passive search of the historical public-scan database that never touches the target |
| [whois-lookup](https://github.com/nlink-jp/whois-lookup) | Go | Looks up the registration data of a domain, IP, or AS number (CLI + MCP) — RDAP-first via the IANA bootstrap with a port 43 WHOIS fallback for RDAP-less ccTLDs (.jp), in-house IDN punycode, local TTL cache; no credentials. The registration-focused sibling of asn-lookup |

### lab-series — Experimental projects

Works in progress. APIs, features, and interfaces may change without notice.

| Tool | Lang | Description |
|------|------|-------------|
| [llm-othello](https://github.com/nlink-jp/llm-othello) | Go | Browser-based Othello against a local LLM — you play Black, the model plays White, and every move decision happens server-side: the server builds a prompt from the board and the legal moves, parses the JSON reply and validates that the move is legal. Works with any OpenAI-compatible API |
| [m5-clock](https://github.com/nlink-jp/m5-clock) | C++ | NTP-synchronized digital clock for M5Stack Core2 — date, weekday and time to the second, synced over Wi-Fi at startup and hourly, falling back to the onboard RTC when Wi-Fi is unavailable. Night mode dims automatically within configurable hours; settings come from a JSON file on the SD card |
| [m5-data-receiver](https://github.com/nlink-jp/m5-data-receiver) | Bash/CFn | Serverless AWS backend for m5-vehicle-logger — receives sensor data over HTTPS POST, validates the API key, and stores JSON in S3 under date-partitioned keys. Every resource lives in one CloudFormation template, so deploy, teardown and download need only the AWS CLI; no CDK, SAM or Terraform |
| [m5-vehicle-logger](https://github.com/nlink-jp/m5-vehicle-logger) | C++ | Vehicle driving-data logger on M5Stack Basic v2.7 — GNSS position at 1 Hz, IMU accelerometer/gyroscope/magnetometer at 10 Hz and barometric environment data at 1 Hz, buffered in memory and sent over Wi-Fi when a network is reachable. Built for vehicle-mounted use with no battery backup |
| [slack-monitor](https://github.com/nlink-jp/slack-monitor) | Python | Real-time Slack channel activity summarizer on a local or cloud LLM — tails a channel through stail and produces periodic summaries of topics, sentiment, cumulative findings and the situation so far, in a live three-panel TUI or as Rich panels reading stail JSONL from stdin |
| [spice-client](https://github.com/nlink-jp/spice-client) | Swift | Native SPICE client for QEMU and Ravada virtual desktops — opens .vv files and an HTTPS Ravada portal, confirming host, port, TLS and clipboard (off by default) natively before connecting. Text-only clipboard for the focused window, files sent to the guest by drop or menu; for Apple Silicon |

### lib-series — Shared libraries

Shared libraries for nlink-jp projects. Zero external dependencies where possible.

| Tool | Lang | Description |
|------|------|-------------|
| [nlk](https://github.com/nlink-jp/nlk) | Go | Go toolkit for the code that surrounds an LLM call, not the call itself — guard wraps user text in a nonce-tagged XML envelope against prompt injection, jsonfix repairs what a model actually emits, strip removes thinking tags, backoff and validate cover the rest. Zero external dependencies |
| [nlk-py](https://github.com/nlink-jp/nlk-py) | Python | Python edition of nlk — the same five modules (guard, jsonfix, strip, backoff, validate) with the same API design, for the code around an LLM call rather than the call itself. Zero external dependencies, so it drops into any project without pulling a tree behind it |
| [pathguard](https://github.com/nlink-jp/pathguard) | Go | Go library that judges whether a path may be touched — system locations, credential stores, agent configuration and a server’s own directories are compared by file identity as well as by folded name, so no case variant, link or firmlink walks past them, even before they exist |

### lite-series — Lightweight LLM and pipeline tools

Small, local-first CLI tools for LLM interaction, retrieval, and classification.

| Tool | Lang | Description |
|------|------|-------------|
| [lite-rag](https://github.com/nlink-jp/lite-rag) | Go | Retrieval-augmented question answering over a Markdown directory, entirely local — chunks and embeds into DuckDB, then answers with a local LLM over an OpenAI-compatible API, from the CLI or an embedded web UI. Japanese/English mixed documents chunk on Japanese sentence boundaries; re-indexing only touches files whose hash changed |
| [lite-switch](https://github.com/nlink-jp/lite-switch) | Go | Natural-language classifier for shell pipelines — reads free-form text on stdin and writes the single best-matching tag to stdout, so an LLM decision slots into a pipe like any other filter. Options live in a version-controlled YAML file, and stdin is isolated in a nonce-tagged wrapper |

### skills-series — Claude Code Skills

Claude Code Skills packaging the organization's workflows — development
process, research, meeting minutes, security analysis, and news
collection. One repository per skill; each releases a skill zip
installable into `~/.claude/skills/`
or uploadable to claude.ai (Settings → Skills).

| Skill | Command | Description |
|-------|---------|-------------|
| [compliance-review](https://github.com/nlink-jp/compliance-review) | `/compliance-review compile \| review` | Two-phase regulation-compliance review — compiles your regulation documents into a versioned domain-expert set (full clause text, no RAG, deterministic coverage check), then reviews applications with parallel independent experts behind drift and nonce-isolation gates; successor to the virtual-reviewer PoC |
| [incident-research](https://github.com/nlink-jp/incident-research) | `/incident-research <incident>` | Security incident deep-dive research — collects and reads news and primary sources on one public incident into a timeline-centric, source-tiered JSON report plus a STIX 2.1 bundle of extracted IoCs; companion to service-research, successor to the ioc-collector CLI |
| [incident-review](https://github.com/nlink-jp/incident-review) | `/incident-review <record>` | Claude Code Skill that reviews your own organization’s IR communication record — a Slack export, a plain-text log or a live channel — into a schema-validated JSON report with per-participant activity, role inference and a process-quality review. Every IoC is defanged before the agent reads a line |
| [mcp-tactics](https://github.com/nlink-jp/mcp-tactics) | `/mcp-tactics` | Claude Code Skill: the cross-cutting tactics book for nlink-jp’s MCP servers and proxies — SKILL.md is a router of decision tables with a four-tier escalation doctrine ranked by who can see that you asked, from no external observer up to contact from your own IP |
| [meeting-notes](https://github.com/nlink-jp/meeting-notes) | `/meeting-notes <transcript>` | Claude Code Skill that structures a meeting transcript (TXT/VTT/SRT) into a validated three-layer JSON record — raw utterances, decisions with their rationale, summaries — then compiles Markdown or self-contained HTML minutes. Extracts small pieces, validates each and retries only what broke, verifying every quote against the transcript |
| [news-digest](https://github.com/nlink-jp/news-digest) | `/news-digest --repo <corpus>` | Claude Code Skill that collects your own feeds, decides what is worth reading, and compiles a digest of only that — significance and your own relationship to it are scored separately, continuing stories are tracked, and a topic that resurfaced with no new facts is named as stale |
| [rfp](https://github.com/nlink-jp/rfp) | `/rfp [tool-name]` | Claude Code Skill that facilitates the RFP planning stage for a new nlink-jp project — collects requirements through interactive Q&A, validates completeness against the organization’s CONVENTIONS.md Phase 1, and emits a structured RFP document covering problem statement, features, constraints and non-goals |
| [service-research](https://github.com/nlink-jp/service-research) | `/service-research <name>` | Claude Code Skill that researches a product or service — overview, pricing, terms of service, privacy policy, data security and AI-agent behavior — into a schema-validated JSON report with a three-tier risk rating and a Markdown summary. The agent opens and reads the actual policy pages itself |

### util-series — General-purpose data utilities

Pipe-friendly tools for data transformation and processing.

| Tool | Lang | Description |
|------|------|-------------|
| [active-lens](https://github.com/nlink-jp/active-lens) | Go | Content-free Mac activity tracker — records only WHEN you work, never WHAT you do; classifies each moment operating / present / away with no permissions, and derives work sessions that are never cut at midnight (timeline for the work log, now for the session in progress) |
| [active-lens-gui](https://github.com/nlink-jp/active-lens-gui) | Swift | macOS work-log menu-bar app — a native SwiftUI front-end over active-lens showing the session you are in, with a calendar-style work timeline (day columns, hover for start / end / duration) and a per-day work log |
| [ask-gemini-mcp](https://github.com/nlink-jp/ask-gemini-mcp) | Go | MCP server exposing a single tool, `ask_gemini(prompt)`, which forwards the prompt to Vertex AI Gemini and returns the reply — a second-opinion channel for coding agents, and the only route to Gemini in MCP clients with no shell to run the gem-* CLIs |
| [ask-llm-mcp](https://github.com/nlink-jp/ask-llm-mcp) | Go | MCP server exposing a single tool, `ask_llm(prompt)`, which forwards the prompt to any OpenAI-compatible chat-completions endpoint — aimed at a local LM Studio server, so a second opinion costs nothing and no data leaves the machine. One config file per model to offer several backends |
| [bigquery-mcp](https://github.com/nlink-jp/bigquery-mcp) | Go | Protection-first BigQuery MCP server — every query is dry-run and refused unless BigQuery itself classifies it as a single SELECT inside the dataset allowlist and the byte budget, then runs as a named job under maximumBytesBilled. Rows come back column-keyed with explicit caps; failures carry a retry hint |
| [brave-search](https://github.com/nlink-jp/brave-search) | Go | The Brave Search API as a CLI and local MCP server — ranked web results, page text pre-extracted to a token budget for grounding a model, and cited answers from one search or a multi-step research run. Every result prints its cost; nothing is cached (Brave ToS) |
| [cclaude](https://github.com/nlink-jp/cclaude) | Bash | Runs Claude Code inside an isolated container — only the current project directory is mounted, so it cannot reach anything outside the project, while ~/.claude persists on the host across sessions. Podman or Docker auto-detected, Go/Node/Python preinstalled, subscription or API-key auth |
| [claude-usage-lens](https://github.com/nlink-jp/claude-usage-lens) | Go | Token usage and cost analysis for Claude Code / Cowork — parses local session logs into SQLite and reports by day, session, project or model, with near-real-time watch. Reprice applies rate changes to stored history, and the effective weekly cap comes from official /usage readings |
| [claude-usage-lens-gui](https://github.com/nlink-jp/claude-usage-lens-gui) | Swift | macOS menu-bar app for Claude usage cost — a native SwiftUI front-end over claude-usage-lens: today’s cost in the menu bar, expanding into Swift Charts analysis (daily trend, per-model stacking, top projects). The weekly budget monitor calibrates to the real limit and projects overrun from the week’s pace |
| [chrome-pilot-mcp](https://github.com/nlink-jp/chrome-pilot-mcp) | Go | Browser automation as an MCP server with no supply chain to trust — a single binary with no third-party modules speaking CDP directly, driving your installed Chrome, with startup-only host allow/block lists no tool can widen |
| [csv-to-json](https://github.com/nlink-jp/csv-to-json) | Go | Converts CSV to a JSON array — reads a file or stdin and writes the array to stdout, one object per row keyed by the header. A single dependency-free binary for macOS, Linux and Windows, and the usual entry point to the json-filter / jstats / jviz pipeline |
| [data-analyzer](https://github.com/nlink-jp/data-analyzer) | Go | Large-scale JSON/JSONL analysis with a local LLM — a sliding window with overlap summarises progressively across 100k+ records instead of map-reducing them, so boundary context survives. Every finding cites the source records and is verified against the originals; checkpointed resume, Markdown or HTML report |
| [data-toolbox-mcp](https://github.com/nlink-jp/data-toolbox-mcp) | Go | DuckDB analysis and containerized Python as a single-binary MCP server — loads tabular files into a per-workspace DuckDB and runs SQL or throwaway Python against them inside a Podman sandbox, with results capped and the omission counted. Workspaces persist across sessions; the client brings its own LLM |
| [eml-to-jsonl](https://github.com/nlink-jp/eml-to-jsonl) | Go | EML parser for shell pipelines — reads .eml from stdin, files or a directory and writes one JSON object per message: headers (from/to/cc/subject/date/message-id/received), bodies with text/plain first, and attachment metadata without the binary. Everything decoded to UTF-8, ISO-2022-JP and Shift_JIS included |
| [gem-image](https://github.com/nlink-jp/gem-image) | Go | Image generation and editing CLI on Vertex AI Gemini’s native image models — generates from a text prompt or edits an existing image from the command line, built for batch work driven by shell scripts and pipes. The cloud counterpart to the fully local image-forge |
| [gem-query](https://github.com/nlink-jp/gem-query) | Go | Natural-language data analysis CLI for DuckDB and SQLite on Vertex AI Gemini — asks in plain language, generates SQL, validates it with a dry run before executing, and shows the result. Works as an interactive DB shell or a pipe-friendly one-shot command |
| [gem-rag](https://github.com/nlink-jp/gem-rag) | Python | Gemini-powered RAG CLI for Markdown documents — heading-aware chunking with JP/EN sentence boundary detection, Vertex AI text embeddings stored in DuckDB, and answers built from vector search plus adjacent-chunk expansion. The Vertex AI counterpart to the fully local lite-rag; Python, runs anywhere uv does |
| [gem-scribe](https://github.com/nlink-jp/gem-scribe) | Go | Cloud speech-to-text on Vertex AI’s dedicated transcription model (CLI + MCP) — speaker turns and word-level timings come back as structured response parts, so no language model authors the transcript’s JSON. Separates up to 8 speakers where the local voice-scribe stops at 4, and shares its output envelope |
| [gem-search](https://github.com/nlink-jp/gem-search) | Go | Agentic web search CLI on Vertex AI Gemini — given a question in natural language, it searches via Google Search Grounding, reads the results and writes a Markdown or JSON report with citations. Pipe-friendly; brave-search is the raw search call, this is the report |
| [gem-summary](https://github.com/nlink-jp/gem-summary) | Go | Single-purpose text summarisation CLI on Vertex AI Gemini — one LLM call for a .md/.txt file or stdin, relying on Gemini’s ~1M-token window instead of a sliding-window summariser. Inputs past that window fall back to chunk, summarise in parallel, then merge, so nothing is silently refused |
| [gem-usage-lens](https://github.com/nlink-jp/gem-usage-lens) | Go | Token usage and cost analysis for gem-agent (Vertex AI Gemini) — parses the session transcripts’ accounting records into SQLite and prices them at Vertex AI list price: thinking as output, cached prompt as a share, grounding per request, regional multiplier. Calendar-month budget with a pace forecast |
| [gem-usage-lens-gui](https://github.com/nlink-jp/gem-usage-lens-gui) | Swift | macOS menu-bar app for gem-agent usage cost — a native SwiftUI front-end over gem-usage-lens: today’s cost in the menu bar, expanding into Swift Charts analysis (daily trend, per-model stacking, call source, top projects). The calendar-month budget monitor shows use and remaining, and projects overrun from the month’s pace |
| [grid-edit](https://github.com/nlink-jp/grid-edit) | Swift | Native macOS CSV/TSV editor (AppKit, NSDocument + NSTableView) — csv-editor’s successor, and a real AppKit grid, so scrolling, IME input and focus behave like macOS rather than a web page. Encoding and delimiter auto-detect (UTF-8/BOM/Shift_JIS/CP932), rectangular selection, TSV clipboard with paste confirmation, find and replace, sort |
| [image-forge](https://github.com/nlink-jp/image-forge) | Go | Local diffusion image-generation engine and model CLI for macOS (Apple Silicon) — runs SDXL, anime and general models through stable-diffusion.cpp with each model’s gotchas (CLIP-skip, VAE, resolution, v-pred) hidden behind profiles. txt2img/img2img/inpaint/ControlNet/LoRA, GGUF quantization, resident serve, and an mcp server mode |
| [image-forge-gui](https://github.com/nlink-jp/image-forge-gui) | Swift | macOS app for exploratory local image generation — a native SwiftUI front-end driving image-forge’s resident serve engine: a model picker with a Safe-only filter, stacked LoRAs with weight sliders, img2img with an inpaint mask painted on the init image, and a gallery with live progress |
| [instant-translate](https://github.com/nlink-jp/instant-translate) | Swift | macOS menu-bar translator on the OS Translation framework — on-device, no LLM and no network. Auto language routing with a configurable secondary language, a source pin and manual target, a rebindable global hotkey seeded from the clipboard, and a status line that always says what it is doing |
| [json-filter](https://github.com/nlink-jp/json-filter) | Go | Command-line filter that extracts, validates, prettifies and repairs JSON inside arbitrary text — pulls the object out of LLM prose, an API response or a log line, then fixes 20+ real-world defects (code fences, single quotes, trailing commas, unquoted keys, comments). `--bypass` keeps a pipeline alive |
| [json-to-sqlite](https://github.com/nlink-jp/json-to-sqlite) | Go | Ingests JSON and turns it into an SQLite database — infers the table schema from the objects themselves, maps JSON types to TEXT/REAL/INTEGER (falling back to TEXT when types conflict), and evolves an existing table by adding columns when new fields appear. Reads from files or stdin |
| [json-to-table](https://github.com/nlink-jp/json-to-table) | Go | Formats a JSON array of objects into a readable table — reads stdin, writes plain text with borders, GitHub-flavoured Markdown, CSV, self-contained HTML, or a PNG image with Japanese font support for pasting into a report or chat. Column selection and ordering; the companion to splunk-cli |
| [jstats](https://github.com/nlink-jp/jstats) | Go | SPL-style stats for JSON — reads a JSON array or JSONL on stdin and computes aggregations grouped by one or more fields, with count, sum, min/max, avg, median, stdev, variance, range, percentiles, distinct count, first/last, mode, and values/list collectors. The aggregation stage between json-filter and jviz |
| [jviz](https://github.com/nlink-jp/jviz) | Go | Visualizes JSON in the browser — pipe a JSON array and it opens a local page with interactive bar, line, pie or table views and X/Y column pickers. The chart updates live when the data changes, so it sits naturally at the end of a jstats pipeline |
| [load-spinner](https://github.com/nlink-jp/load-spinner) | Swift | macOS menu-bar CPU/GPU load indicator — a lit segment travels around a fixed circle or square at a speed proportional to load. Memory is a level rather than a rate, so it renders as a gauge that fills. A click opens live gauges with a 3-minute history |
| [lookup](https://github.com/nlink-jp/lookup) | Go | Enriches a JSON stream by joining fields from an external table — reads a JSON array or JSON Lines on stdin, matches against a CSV or JSON lookup file, and writes the enriched objects out. Matching is exact (case-sensitive or not), glob wildcard, regex, or CIDR |
| [mail-analyzer](https://github.com/nlink-jp/mail-analyzer) | Go | Suspicious email analyzer combining rule-based indicators and a Gemini LLM — parses .eml and .msg into structured JSON with SHA-256 hashes, SPF/DKIM/DMARC results, sender integrity checks (From vs Return-Path, display-name spoofing, Reply-To divergence), URL and attachment risk. Offline mode skips the LLM entirely |
| [mail-analyzer-gui](https://github.com/nlink-jp/mail-analyzer-gui) | Swift | Native macOS desktop app for analyzing suspicious emails — drop .eml or .msg from Finder or straight out of Apple Mail (multiple at once) and get the judgment, its confidence and its reasons up front, with indicators expandable per row. Works against either mail-analyzer or mail-analyzer-local |
| [mail-analyzer-local](https://github.com/nlink-jp/mail-analyzer-local) | Go | Local-LLM edition of mail-analyzer — the same rule-based indicators and LLM judgment, but against an OpenAI-compatible endpoint (LM Studio, Ollama) so nothing leaves the machine and no GCP or Vertex AI is needed. Same JSON schema; disable the model’s thinking mode, which measurably improves accuracy |
| [markdown-viewer](https://github.com/nlink-jp/markdown-viewer) | Go | Single-binary local Markdown viewer and file browser — a two-pane UI with a persistent file tree beside the rendered page, GitHub-like styling, Mermaid diagrams and syntax highlighting, with every asset embedded so there is nothing to install. Directory-traversal protection and HTML sanitization are on by default |
| [menubar-spacer](https://github.com/nlink-jp/menubar-spacer) | Swift | Changes the spacing between macOS menu bar icons and puts it back exactly as it was — four presets drawn in the window at widths measured on macOS 27, so they can be compared before anything is written. Requests no permissions; macOS’s own icons keep their spacing |
| [mcp-bridge](https://github.com/nlink-jp/mcp-bridge) | Go | Bridges stdio MCP clients to Streamable HTTP MCP servers that require a pre-registered OAuth client — Slack, GitHub Apps, Entra ID and other providers without dynamic client registration, which a client’s own OAuth cannot reach. PKCE, an https loopback callback, zero dependencies |
| [msg-to-jsonl](https://github.com/nlink-jp/msg-to-jsonl) | Go | Outlook MSG parser for shell pipelines — reads .msg and writes the same JSONL schema as eml-to-jsonl, so both compose in one pipeline. Handles Unicode and codepage MAPI properties, prefers SMTP addresses and discards X.400/Exchange internals, splits To/CC/BCC from recipient records. Pure local parser, no network |
| [net-meter](https://github.com/nlink-jp/net-meter) | Swift | macOS menu-bar meter for one network interface — upstream and downstream rate as numbers and a graph scrolling one bar a second, with a panel for history, addresses, peaks and totals. Follows the physical link even while a VPN is up. No permissions, nothing else. macOS 26+, darwin/arm64 |
| [nvme-lens](https://github.com/nlink-jp/nvme-lens) | Swift | macOS menu-bar monitor for NVMe SSD temperature and endurance — reads SMART through IOKit directly (no smartmontools, no root, no daemon) and judges on the hottest Temperature Sensor, not the composite value that understates the hotspot by 17–21 °C. Internal and Thunderbolt/USB4 NVMe only |
| [pptx-to-markdown](https://github.com/nlink-jp/pptx-to-markdown) | Python | Converts .pptx presentations to structured Markdown as a preprocessing step for LLM analysis — slide text and bullet hierarchy become Markdown, tables become Markdown tables, chart data is extracted as a table, images are embedded as base64 data URIs, and speaker notes get their own section per slide |
| [rex](https://github.com/nlink-jp/rex) | Go | Extracts fields from unstructured text with regular expressions and emits JSON — like Splunk’s rex, it applies several patterns to each line and merges the named captures into one object. With `--field` it works on JSON input instead, applying the regex to one field and merging it back |
| [sdate](https://github.com/nlink-jp/sdate) | Go | Generates a timestamp from a Splunk-style relative time and snap expression — -1d@d means yesterday snapped to midnight, and units run from seconds to years with weeks starting Monday. Prints in a Go time layout or as epoch, in a timezone you choose |
| [sensor-lens](https://github.com/nlink-jp/sensor-lens) | Go | Collects temperature, humidity and CO2 from SwitchBot sensors into a local SQLite history — authenticates against the SwitchBot Open API v1.1, polls on a schedule within the daily quota, and backfills from CSV. Strictly read-only: it never sends a command, so it cannot switch, open or lock anything |
| [sensor-lens-gui](https://github.com/nlink-jp/sensor-lens-gui) | Swift | macOS menu-bar readout of your SwitchBot sensors — a front end over the bundled sensor-lens CLI, which holds the credentials and owns the database; while the app runs it also does the collecting. Up to three device-by-metric readings in the menu bar, six-hour sparklines and CO2 alerts |
| [share-mounter](https://github.com/nlink-jp/share-mounter) | Swift | macOS menu-bar app that auto-mounts SMB shares at login — mounts via NetFS with no Finder window, appearing in the sidebar as network volumes; multiple shares, per-share auto-mount, Keychain credentials, re-mount on wake/network recovery |
| [shell-agent-v2](https://github.com/nlink-jp/shell-agent-v2) | Go/React | macOS chat and agent desktop app built around interactive data analysis — each session owns its own DuckDB, and every analysis tool stays visible to the model each round so it can plan a multi-step workflow up front. Hybrid local/Vertex backend, per-session container sandbox, MCP, unified approval |
| [splunk-mcp](https://github.com/nlink-jp/splunk-mcp) | Go | Splunk search as a local MCP server — asynchronous job pattern over the REST API guarantees exact result counts (never oneshot/preview), large result sets delivered as JSONL files without truncation, destructive-SPL guard, one instance per Splunk host |
| [status-lens](https://github.com/nlink-jp/status-lens) | Swift | macOS menu-bar watcher for Statuspage-hosted status pages (Claude by default; GitHub or any Statuspage URL as profiles) — per-profile label plus shape symbol dual-encoded in color and shape, worst-of aggregation, a detail popover with components and active incidents, and notifications on degradation or recovery only |
| [task-clock](https://github.com/nlink-jp/task-clock) | Go | Resident macOS scheduler that does not trust launchd’s timing engine — evaluates cron itself (launchd only keeps it resident) and records every fire as scheduled-vs-actual with overrun accounting. Watermark triggers, overlap policies, persistent per-task pause, a localhost HTTP trigger API, and a stop that never kills running tasks |
| [task-clock-gui](https://github.com/nlink-jp/task-clock-gui) | Swift | Menu-bar front end for task-clock — quiet by default, speaking only on overrun or an unreachable daemon. Pilot lamp plus a power switch for the run state (stopping never kills running tasks), per-task on/off switches with per-second countdowns, a scheduled-vs-actual run history, and a resizable panel |
| [url-shelf](https://github.com/nlink-jp/url-shelf) | Swift | macOS menu-bar shelf of URL notes kept as plain .webloc files — the folder tree is the classification, so Finder stays the editor and the records outlive the app. Per-entry private-window opening with folder-inherited defaults, disabled rather than downgraded when no private browser is set |
| [video-studio-mcp](https://github.com/nlink-jp/video-studio-mcp) | Go | Presentation-video compositor as an MCP server — page images plus per-page audio become one narrated MP4, each page shown for exactly the length of its audio. A pure ffmpeg compositor paired with voice-studio-mcp: per-page chapters, opt-in burned-in or closed-caption subtitles, 16:9/9:16/1:1, async rendering |
| [voice-scribe](https://github.com/nlink-jp/voice-scribe) | Go | Local speech-to-text for macOS (CLI + MCP) — whisper.cpp statically linked against Metal, so no API key, no ffmpeg, and no audio leaving the machine. Defaults to large-v3-turbo, measured on-machine to beat the Japanese-specialised alternative even on Japanese; VAD gating suppresses hallucinations over silence |
| [voice-studio-mcp](https://github.com/nlink-jp/voice-studio-mcp) | Go | Local multi-speaker Japanese speech synthesis for AI agents as an MCP server — narrated audio for radio drama, audiobook, podcast or briefing, Japanese only. AivisSpeech Engine backend, script JSONL batch synthesis with a content-hash cache, pronunciation dictionaries, ffmpeg mastering, bundled multi-actor-narration skill |
| [web-fetch](https://github.com/nlink-jp/web-fetch) | Go | One URL’s readable text as a CLI and local MCP server — main content as markdown, plain text or the raw body. Built for agent runtimes that can search but cannot read a user-given URL: no cookies, nothing stored on disk, and an SSRF guard in the dialer |
| [webhook-relay](https://github.com/nlink-jp/webhook-relay) | Go | Authenticated webhook receiver that writes payloads to GCS — an internet-facing ingestion gateway on Cloud Run with VPC isolation and egress only to Google APIs, scale-to-zero billing, constant-time API-key comparison, per-IP token-bucket rate limiting, a request size cap and a file-extension whitelist against path traversal |
| [zip-porter](https://github.com/nlink-jp/zip-porter) | Swift | Windows-safe ZIP creation and extraction for macOS — a drag-and-drop GUI with an embedded CLI: junk files excluded, NFC UTF-8 names with a CP932 legacy mode, AES-256 or ZipCrypto passwords, CP932 auto-detection on extract. Hardened extraction too: zip-slip guard, decompression-bomb limits, umask-masked permissions, quarantine propagation |

### archive-series — Archived projects

Projects that have been retired or superseded live in
[**archive-series**](https://github.com/nlink-jp/archive-series), grouped by the
series each came from. Those repositories are read-only on GitHub: their
released assets stay downloadable, but they take no further changes.

Where a project has a successor, the archive catalog names it.
