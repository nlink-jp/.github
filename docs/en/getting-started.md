# nlink-jp Tools Getting Started

A guide to get started with nlink-jp tools. Check the relevant setup guides based on the tools you want to use.

## Which Guide Should You Read?

Refer to the guides below based on the type of tool you want to use. If multiple guides apply, follow each setup guide in order.

### How to Obtain Tools

| What you want to do | Required guide |
|---------------------|---------------|
| Download and use pre-built binaries of Go tools | No special preparation needed (download from [GitHub Releases](https://github.com/orgs/nlink-jp/repositories)) |
| Build Go tools from source | [Go Build Environment Setup](setup-go-build.md) |
| Use Python tools | [Python + uv Setup](setup-python-uv.md) |

### Tool Prerequisites

| Service used by the tool | Required guide | Example tools |
|--------------------------|---------------|---------------|
| Vertex AI (Gemini) | [Vertex AI Setup](setup-vertex-ai.md) | gem-query, gem-search, gem-image, gem-cli, gem-rag, mail-analyzer, ai-ir2, ir-tracker, meeting-note, etc. |
| Local LLM (LM Studio) | [Local LLM Setup](setup-local-llm.md) | llm-cli, data-analyzer, lite-rag, magi-system, sai, etc. |
| Slack API | Refer to each tool's README | scat, stail, swrite, slack-router, sai, etc. |
| Confluence API | Refer to each tool's README | confl-cli |
| Splunk API | Refer to each tool's README | splunk-cli |

### Decision Flow

```
What tool do you want to use?
  |
  +-- gem-* / mail-analyzer / ai-ir2 / meeting-note, etc.
  |   -> Vertex AI Setup required
  |   -> If the tool is Python-based, Python + uv is also required
  |   -> If the tool is Go-based and you're building from source, Go Build Environment is also required
  |
  +-- llm-cli / data-analyzer / lite-* / magi-system, etc.
  |   -> Local LLM Setup required
  |   -> If the tool is Python-based, Python + uv is also required
  |   -> If the tool is Go-based and you're building from source, Go Build Environment is also required
  |
  +-- Other tools
      -> Follow each tool's README
      -> If the tool is Python-based, Python + uv is required
      -> If the tool is Go-based and you're building from source, Go Build Environment is required
```

## Checking a Tool's Language

You can determine whether a tool is written in Go or Python by looking at the tool's repository.

- **Go**: Has a `go.mod` file. Pre-built binaries are often available on GitHub Releases
- **Python**: Has a `pyproject.toml` or `uv.lock` file

If unsure, refer to each tool's README.

## Setup Guide List

| Guide | Description | Estimated time |
|-------|-------------|---------------|
| [Vertex AI Setup](setup-vertex-ai.md) | Google Cloud CLI, credentials, configuration files | 15-20 min |
| [Local LLM Setup](setup-local-llm.md) | LM Studio, model download, API server | 20-30 min (excluding model download time) |
| [Python + uv Setup](setup-python-uv.md) | Python, uv package manager | 10-15 min |
| [Go Build Environment Setup](setup-go-build.md) | Go, make, source build | 10-15 min |

## Support

If you encounter issues during setup, check the Troubleshooting section of each guide. If the problem persists, ask in the team's Slack channel.
