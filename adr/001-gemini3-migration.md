# ADR-001: Gemini 2.5 → 3 Migration Plan

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-04-10 |
| Decision makers | nlink-jp maintainers |
| Triggered by | Google Cloud notification (2026-04-09): Gemini 2.5 retirement on Vertex AI |

## Context

Google has announced that Gemini 2.5 Pro, Flash, and Flash Lite on Vertex AI
will be discontinued no earlier than **October 16, 2026**. The confirmed
discontinuation date will be set once Gemini 3 reaches General Availability (GA).
Google will provide at least 6 months notice after the GA announcement.

Our organization has **13 tools** across 4 series that depend on Gemini 2.5 models.

Affected GCP projects: see the notification email for project IDs.

## Decision

**We will not migrate to Gemini 3 until it reaches GA.**

Rationale:
- Preview models may have breaking changes and incomplete features.
- Our current workflows are stable on Gemini 2.5.
- The extended timeline (Oct 16, 2026 at earliest) gives us sufficient buffer.

We will prepare for migration now so that the actual transition is smooth when
Gemini 3 reaches GA.

## Affected Tools

### Environment variable switchable (no code change required)

| Tool | Series | Default Model | Env Var |
|------|--------|--------------|---------|
| gem-cli | cli | gemini-2.5-flash | `GEM_CLI_MODEL` |
| mail-analyzer | util | gemini-2.5-flash | `MAIL_ANALYZER_MODEL` |
| gem-rag | util | gemini-2.5-flash | `GEM_RAG_CHAT_MODEL` |
| ioc-collector | cybersecurity | gemini-2.5-flash | `--model` flag |
| mail-triage | cybersecurity | gemini-2.5-flash | `MAIL_TRIAGE_MODEL` |
| ai-ir2 | cybersecurity | gemini-2.5-flash | `AIIR2_MODEL` |
| meeting-note | lab | gemini-2.5-flash | `MEETING_NOTE_MODEL` |
| mail-watcher | lab | gemini-2.5-flash | `GEM_MODEL` |
| magi-system2 | lab | gemini-2.5-pro / flash | `MAGI2_PRO_MODEL` / `MAGI2_FLASH_MODEL` |

### Code change required (hardcoded model names)

| Tool | Series | File(s) | Models |
|------|--------|---------|--------|
| product-research | cybersecurity | `research_agent.py` | gemini-2.5-pro (fixed by design) |
| news-collector | cybersecurity | `collector.py`, `processor.py` | gemini-2.5-pro, gemini-2.5-flash |
| ir-tracker | cybersecurity | `analyzer.py`, `translator.py` | gemini-2.5-pro, gemini-2.5-flash |
| virtual-reviewer | lab | `llm.py` (DEFAULT_MODELS dict) | gemini-2.5-pro / flash (5 roles) |

### Deployment config change required

| Tool | File | Current Value |
|------|------|--------------|
| mail-triage | `deploy/cloudrunjob.yaml` | `gemini-2.5-flash` |

## Migration Checklist (execute when Gemini 3 reaches GA)

- [ ] **Verify SDK support** — check that `google-genai` (Python) and `google.golang.org/genai` (Go) support Gemini 3 and Thought signature circulation
- [ ] **Evaluate model mapping** — decide Gemini 3 equivalents (e.g. 2.5-flash → 3-flash-lite for cost, or 3-flash for quality)
- [ ] **Update hardcoded defaults** — product-research, news-collector, ir-tracker, virtual-reviewer
- [ ] **Update deployment configs** — mail-triage cloudrunjob.yaml
- [ ] **Update test fixtures** — model names in test files across all 13 tools
- [ ] **Update documentation** — README.md, README.ja.md, AGENTS.md, CLAUDE.md for each tool
- [ ] **Implement Thought signature handling** — if required by the SDK, ensure all tools pass thought signatures in multi-turn conversations
- [ ] **Evaluate pricing impact** — compare total cost; consider tier shifts (Pro→Flash, Flash→Flash Lite)
- [ ] **E2E test each tool** — validate with real data before switching production
- [ ] **Update env vars in production** — for tools using environment variable configuration
- [ ] **Update this ADR status** — mark as **Superseded** or **Completed**

## Consequences

- No immediate action required on any tool.
- All new tools using Gemini should follow the existing pattern: environment variable override with a sensible default.
- When Gemini 3 GA is announced, this ADR becomes the migration runbook.
