# Getting Started with nlink-jp Tools

A guide to start using nlink-jp tools. For any tool, nail down three things —
**how to get it**, **what it needs to run**, and **how you use it** — and the
required setup falls out.

## 1. How to get a tool

| What you want | What you need |
|---------------|---------------|
| Use a CLI / GUI on **macOS (Apple Silicon)** | Install from the Homebrew tap (Developer ID signed + Apple-notarized prebuilt binaries). Usually no extra setup |
| Use a prebuilt binary (e.g. Go tools on other OSes) | Nothing special — download from [GitHub Releases](https://github.com/orgs/nlink-jp/repositories) |
| Use a **Claude Code Skill** | Grab the skill zip from the skill repo's Releases and unzip into `~/.claude/skills/` (or upload to claude.ai: Settings → Skills) |
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
in more than one group** (e.g. news-collector is Vertex AI + Slack;
shell-agent-v2 is local LLM + macOS GUI). Each tool's README is the final word
on its requirements.

| Prerequisite | Setup needed | Example tools |
|--------------|--------------|---------------|
| **No credentials, offline** | None | json-to-table, json-filter, csv-to-json, rex, sdate, jstats, jviz, lookup, eml-to-jsonl, msg-to-jsonl, markdown-viewer, instant-translate, and most of the lookup family (tor-exit-lookup, icloud-relay-lookup, mac-lookup, whois-lookup, doh-lookup, rdns-lookup) |
| **A third-party API key / token** | Obtain a key from the service (steps in each README) | abuse-lookup (AbuseIPDB key), urlscan-lookup (urlscan.io key), asn-lookup (IPinfo token — only to fetch the DB; lookups are offline), malware-lookup (abuse.ch key optional) |
| **Vertex AI (Gemini)** | [Vertex AI Setup](setup-vertex-ai.md) | gem-cli, gem-query, gem-search, gem-image, gem-rag, gem-summary, gem-transcribe, mail-analyzer, news-collector, ask-gemini-mcp, etc. |
| **Local LLM (LM Studio / Ollama)** | [Local LLM Setup](setup-local-llm.md) | llm-cli, data-analyzer, lite-rag, lite-switch, mail-analyzer-local, slack-monitor, ask-llm-mcp, etc. |
| **Slack / Confluence / Splunk API** | See each tool's README | scat, stail, swrite, slack-router, md-to-slack, slack-mcp-extender, scli, confl-cli / splunk-cli, splunk-mcp |
| **Container runtime (Podman)** | Container steps in each README | data-toolbox-mcp, pcap-analyzer-mcp (analysis sandbox), shell-agent-v2 (sandboxed execution), cclaude |
| **Cloud (GCP / AWS)** | Deployment steps in each README | webhook-relay, m5-data-receiver |
| **macOS (Apple Silicon) only** | Homebrew cask or the Releases zip (.app) | active-lens-gui, claude-usage-lens-gui, load-spinner, image-forge / image-forge-gui, grid-edit, instant-translate, share-mounter, url-shelf, zip-porter, etc. |

## 3. How you use it

The same tool can be used in different forms, and each has its own path:

- **CLI**: pipe-composable via stdin/stdout. Most tools. Obtain as in §1.
- **GUI app**: menu-bar-resident or a regular window. macOS-centric, distributed
  via Homebrew cask or a Releases zip (signed + notarized .app).
- **MCP server**: registered with an AI agent such as Claude Code. Most start
  over stdio with `<tool> mcp` and are registered in the agent's MCP config.
  - Dedicated MCP: ask-gemini-mcp, ask-llm-mcp, data-toolbox-mcp,
    pcap-analyzer-mcp, splunk-mcp, chrome-pilot-mcp, voice-studio-mcp,
    video-studio-mcp
  - CLI + MCP: the whole lookup family (asn-lookup, abuse-lookup,
    tor-exit-lookup, icloud-relay-lookup, mac-lookup, whois-lookup, doh-lookup,
    rdns-lookup, malware-lookup, urlscan-lookup), image-forge
  - MCP proxies: mcp-guardian (governance), slack-mcp-extender (extends the
    official Slack MCP)
  - **An MCP server's prerequisites follow the service behind it (§2)** — e.g.
    ask-gemini-mcp needs Vertex AI, ask-llm-mcp needs a local LLM.
  - Guidance on which MCP server to reach for when is packaged as the
    [mcp-tactics](https://github.com/nlink-jp/mcp-tactics) Skill.
- **Claude Code Skill**: the organization's workflows (research, meeting
  minutes, compliance review, …) as slash commands in Claude Code / claude.ai.
  This is skills-series (compliance-review, incident-research, incident-review,
  meeting-notes, service-research, rfp, mcp-tactics). Install by unzipping the
  skill zip as in §1 — no binary build involved.

## 4. Decision flow

```
What does the tool you want do?
  │
  ├─ Local data transform / shaping / matching (JSON/CSV/regex/dates, ...)
  │   → mostly no setup needed (offline, no credentials)
  │   → macOS: brew; otherwise a Releases binary / source build
  │
  ├─ Investigate an IP / domain / URL / hash / MAC (the lookup family)
  │   → most run as-is, offline or credential-free
  │   → only abuse-lookup / urlscan-lookup / asn-lookup need a key/token (each README)
  │
  ├─ Uses Gemini (gem-* / mail-analyzer / news-collector, ...)
  │   → Vertex AI Setup
  │
  ├─ Uses a local LLM (llm-cli / *-local / lite-* / shell-agent-v2, ...)
  │   → Local LLM Setup
  │
  ├─ Drives Slack / Confluence / Splunk
  │   → configure auth per the tool's README
  │
  ├─ Called as an MCP tool from an AI agent
  │   → register the MCP server with your agent; prerequisites follow the backing service
  │   → selection guidance: the mcp-tactics Skill
  │
  ├─ Use an org workflow in Claude Code (research report / minutes / compliance review, ...)
  │   → install the skills-series skill zip into ~/.claude/skills/
  │
  ├─ macOS GUI app (menu bar / window)
  │   → brew --cask or the Releases zip; usually Apple Silicon only
  │
  └─ Needs a container / cloud (data-toolbox-mcp, webhook-relay, ...)
      → Podman / GCP / AWS steps in each README

  Note: on top of the above — every Python tool needs Python + uv, and
  building a Go tool from source needs the Go build environment.
```

## Identifying a tool's language

You can tell what a tool is written in from its repository:

- **Go**: has a `go.mod`. Prebuilt binaries are usually on GitHub Releases /
  the Homebrew tap
- **Python**: has a `pyproject.toml` or `uv.lock`
- **Swift / Rust (GUI)**: macOS-targeted; distributed via Homebrew cask or a
  Releases zip (.app)
- **Skill**: has a `SKILL.md`. No language runtime needed (runs inside Claude
  Code / claude.ai)

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

## Contributing

If you develop or modify tools rather than just use them, read
[CONVENTIONS.md](../../CONVENTIONS.md) (organization rules) and
[nlink-jp/knowledge](https://github.com/nlink-jp/knowledge) (the engineering
knowledge base — consult the relevant theme before building).

## Support

If you hit a setup problem, check the troubleshooting section of the relevant
guide. If that doesn't resolve it, ask in the team's Slack channel.
