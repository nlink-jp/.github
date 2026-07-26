# Getting Started with nlink-jp Tools

A guide to start using nlink-jp tools. For any tool, nail down three things —
**how to get it**, **what it needs to run**, and **how you use it** — and the
required setup falls out.

## 1. How to get a tool

| What you want | What you need |
|---------------|---------------|
| Use a CLI / GUI on **macOS (Apple Silicon)** | Install from the Homebrew tap (Developer ID signed + Apple-notarized prebuilt binaries). Usually no extra setup |
| Use a prebuilt binary (e.g. Go tools on other OSes) | Nothing special — download from [GitHub Releases](https://github.com/orgs/nlink-jp/repositories) |
| Build a Go tool from source | [Go Build Setup](setup-go-build.md) |
| Use a Python tool | [Python + uv Setup](setup-python-uv.md) |

Homebrew tap on macOS:

```sh
brew tap nlink-jp/tap
brew install nlink-jp/tap/<name>          # CLI tools
brew install --cask nlink-jp/tap/<name>   # GUI apps
```

See [nlink-jp/homebrew-tap](https://github.com/nlink-jp/homebrew-tap) for the
full lineup. Anything not in the tap is available as a Releases binary or a
source build.

## 2. What a tool needs to run

Grouped by "what external thing the tool depends on." **A single tool can fall
in more than one group** (e.g. mail-triage is Vertex AI + cloud; quick-translate
is local LLM + macOS GUI). Each tool's README is the final word on its
requirements.

| Prerequisite | Setup needed | Example tools |
|--------------|--------------|---------------|
| **No credentials, fully offline** | None | json-to-table, json-filter, csv-to-json, rex, sdate, jstats, jviz, lookup, eml-to-jsonl, msg-to-jsonl, markdown-viewer, tor-exit-lookup, etc. |
| **A third-party API key / token** | Obtain a key from the service (steps in each README) | abuse-lookup (AbuseIPDB key), asn-lookup (IPinfo token — only to fetch the DB; lookups are offline) |
| **Vertex AI (Gemini)** | [Vertex AI Setup](setup-vertex-ai.md) | gem-cli, gem-query, gem-search, gem-image, gem-rag, gem-summary, gem-transcribe, mail-analyzer, ai-ir2, meeting-note, news-collector, product-research, etc. |
| **Local LLM (LM Studio / Ollama)** | [Local LLM Setup](setup-local-llm.md) | llm-cli, data-analyzer, lite-rag, lite-switch, mail-analyzer-local, quick-translate, cti-primer, magi-system, sai, slack-monitor, etc. |
| **Slack / Confluence / Splunk API** | See each tool's README | scat, stail, swrite, slack-router, md-to-slack, scli, ir-hub / confl-cli / splunk-cli |
| **Container runtime (Podman)** | Container steps in each README | data-toolbox-mcp, pcap-analyzer-mcp (analysis sandbox), shell-agent-v2 (sandboxed execution) |
| **Cloud (GCP / AWS)** | Deployment steps in each README | webhook-relay, mail-triage, m5-data-receiver |
| **macOS (Apple Silicon) only** | Homebrew cask or .dmg | active-lens-gui, claude-usage-lens-gui, load-spinner, image-forge / image-forge-gui, csv-editor, mail-analyzer-gui, etc. |

## 3. How you use it

The same tool can be used in different forms, and each has its own path:

- **CLI**: pipe-composable via stdin/stdout. Most tools. Obtain as in §1.
- **GUI app**: menu-bar-resident or a regular window. macOS-centric, distributed
  via Homebrew cask or .dmg.
- **MCP server**: registered with an AI agent such as Claude Code. Most start
  over stdio with `<tool> mcp` and are registered in the agent's MCP config.
  - Dedicated MCP: ask-gemini-mcp, ask-llm-mcp, data-toolbox-mcp,
    pcap-analyzer-mcp, voice-studio-mcp, video-studio-mcp, mcp-guardian
  - CLI + MCP: asn-lookup, abuse-lookup, tor-exit-lookup
  - **An MCP server's prerequisites follow the service behind it (§2)** — e.g.
    ask-gemini-mcp needs Vertex AI, ask-llm-mcp needs a local LLM.

## 4. Decision flow

```
What does the tool you want do?
  │
  ├─ Local data transform / shaping / matching (JSON/CSV/regex/dates/IP checks)
  │   → mostly no setup needed (offline, no credentials)
  │   → macOS: brew; otherwise a Releases binary / source build
  │
  ├─ Queries an external data service (needs an API key — IP reputation / AS, ...)
  │   → get the service's API key / token (each README)
  │   e.g. abuse-lookup, asn-lookup
  │
  ├─ Uses Gemini (gem-* / mail-analyzer / ai-ir2 / meeting-note, ...)
  │   → Vertex AI Setup
  │
  ├─ Uses a local LLM (llm-cli / *-local / lite-* / magi-system, ...)
  │   → Local LLM Setup
  │
  ├─ Drives Slack / Confluence / Splunk
  │   → configure auth per the tool's README
  │
  ├─ Called as an MCP tool from an AI agent
  │   → register the MCP server with your agent; prerequisites follow the backing service
  │
  ├─ macOS GUI app (menu bar / window)
  │   → brew --cask or .dmg; usually Apple Silicon only
  │
  └─ Needs a container / cloud (data-toolbox-mcp, webhook-relay, mail-triage, ...)
      → Podman / GCP / AWS steps in each README

  Note: on top of the above — every Python tool needs Python + uv, and
  building a Go tool from source needs the Go build environment.
```

## Identifying a tool's language

You can tell what a tool is written in from its repository:

- **Go**: has a `go.mod`. Prebuilt binaries are usually on GitHub Releases /
  the Homebrew tap
- **Python**: has a `pyproject.toml` or `uv.lock`
- **Swift / Rust (GUI)**: macOS-targeted; distributed via Homebrew cask or .dmg

If unsure, check the tool's README.

## Setup guides

| Guide | Covers | Rough time |
|-------|--------|-----------|
| [Vertex AI Setup](setup-vertex-ai.md) | Google Cloud CLI, credentials, config file | 15-20 min |
| [Local LLM Setup](setup-local-llm.md) | LM Studio, model download, API server | 20-30 min (excl. model download) |
| [Python + uv Setup](setup-python-uv.md) | Python, uv package manager | 10-15 min |
| [Go Build Setup](setup-go-build.md) | Go, make, source builds | 10-15 min |

The macOS Homebrew tap ([nlink-jp/homebrew-tap](https://github.com/nlink-jp/homebrew-tap))
is the shortest path to a signed binary with none of the above. If the tool uses
Vertex AI or a local LLM, you'll still need the matching prerequisite setup after
installing.

## Support

If you hit a setup problem, check the troubleshooting section of the relevant
guide. If that doesn't resolve it, ask in the team's Slack channel.
