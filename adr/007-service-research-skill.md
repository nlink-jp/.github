# ADR-007: service-research Skill — Retiring the product-research CLI in Favor of Agentic Research

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-07-31 |
| Decision makers | nlink-jp maintainers |
| Triggered by | product-research's "autonomous web research" being a single grounded Gemini call, plus its hardcoded `gemini-2.5-pro` sitting on the ADR-001 migration list |

## Context

`product-research` (cybersecurity-series, Python) researches a product or
service — overview, terms of service, privacy practices, data security, AI
agent behavior — and emits a structured report (Markdown + JSON with a
three-tier risk rating). Decomposing its ~480 lines:

| Part | Lines (approx.) | Nature |
|---|---|---|
| Two system prompts (8 research angles + extraction rules) | ~50 | The actual product |
| Pydantic schema (7 models, ~50 described fields) | ~100 | The actual product |
| Markdown report formatting | ~40 | The actual product |
| genai client, streaming, 429 retry/backoff, argparse, file saving, progress UI | ~290 | Plumbing that a Claude Code session provides natively |

Two problems motivate revisiting it now:

1. **The research phase under-delivers its own README.** "Autonomous web
   research" is implemented as *one* `generate_content` call with Google
   Search Grounding. Nothing iterates, nothing follows up on gaps, and —
   despite the system prompt's instruction to "check official documents
   directly" — nothing ever opens a ToS or privacy-policy page. The `sources`
   list is whatever grounding metadata claims, not pages actually read.
2. **It is on the ADR-001 casualty list.** `gemini-2.5-pro` is hardcoded
   (deliberately, at the time), making product-research one of the five
   repositories requiring code changes when Gemini 2.5 is retired
   (2026-10-16 or later). Migration effort spent on plumbing we don't need
   is waste.

The organization has one precedent for exactly this move: `meeting-note`
(CLI, single-shot Gemini generation) → `meeting-notes` (Skill, agentic
loop with per-fragment validation and retry), completed 2026-07-31.

## Decision

**Add one Claude Code Skill, `service-research`, to `skills-series`, and
archive the `product-research` CLI when the Skill ships v0.1.0.**

Four sub-decisions define its shape.

### 1. A Skill, not a Gemini 3 migration

The CLI's value is its prompts, schema, and report format — all Markdown-
and JSON-shaped content. Rehosting them as a Skill turns the research phase
into what the README always claimed: the agent runs **multiple searches**,
**fetches and reads the actual ToS / privacy-policy / security pages**,
loops until the schema's angles are covered, and cites only URLs it actually
opened. The model dependency, GCP project, ADC auth, Vertex AI cost, and
429 retry machinery all disappear, and the repository leaves the ADR-001
migration list.

### 2. Named `service-research`, scoped to products *and* services

`github.com/nlink-jp/product-research` already exists and repository names
cannot be reused after archival (the `meeting-note` → `meeting-notes`
lesson). The new name keeps the *research* identity; SKILL.md states
explicitly that both products and services are in scope.

### 3. The JSON schema carries over structurally intact

No downstream tool consumes the CLI's JSON today (verified across the
workspace), so compatibility is a soft constraint. The schema carries over
with its field structure preserved — it is well-designed, and old and new
reports stay comparable — as `schema.json` (JSON Schema draft translated
from the Pydantic models). A stdlib-only `scripts/validate.py` checks
emitted reports: schema conformance, `overall_risk_level` enum, and
non-empty `sources`. Reports default to Japanese with English on request
(the CLI was ja-only; same widening meeting-notes applied).

### 4. Standard skills-series scaffold

Repository = skill (ADR-004), `service-research/` subdirectory as the
distribution boundary, vendored `tests/validate-skill.sh` (ADR-006),
Makefile from the CONVENTIONS.md Skill template, scaffolded from `rfp`
as reference shape. Contents: `SKILL.md` (workflow; injection defense at
the top, since the skill reads adversary-controllable web content),
`schema.json`, `references/report-format.md`, `scripts/validate.py`.

## Consequences

- ADR-001's "code change required" list shrinks from five repositories to
  four; two GCP projects lose one Vertex AI caller.
- The old CLI's pipe mode (`--json-only | jq`) and any cron/batch use
  outside a Claude session are gone. No such use is known; if it resurfaces,
  the Skill runs headless via `claude -p`.
- Report quality now varies with the session model instead of a pinned
  Gemini version — accepted, as the same is true of every skill.
- Output length is no longer a single-generation artifact, so the
  truncation/corruption class that motivated meeting-notes' fragment loop
  is structurally avoided rather than retried around.
- One more entry on the two catalogue surfaces (org profile,
  nlink-web-site) and one archival with README pointer, per the release
  checklist.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Migrate the CLI to Gemini 3 at GA | Keeps ~290 lines of plumbing and per-run Vertex cost to preserve a single-shot research phase that is the tool's actual weakness |
| Rebuild as an MCP server | MCP earns its keep mediating state, credentials, or local engines; this is a pure prompt workflow — the Skill form factor *is* the tool |
| Keep CLI and Skill in parallel | Two surfaces for the same prompts and schema; guaranteed drift (the two-surface catalogue lesson) |
| Reuse the `product-research` name for the skill repo | Impossible while the archived repo holds the name; renaming the archive would break existing links |

## References

- [ADR-001](001-gemini3-migration.md) — Gemini 2.5 retirement, migration list
- [ADR-003](003-mcp-tactics-skill.md) — precedent: Skill as the artifact form
- [ADR-004](004-skills-series-umbrella.md) — repository = skill, distribution boundary
- [ADR-006](006-skill-validator-vendoring.md) — vendored validator
- [meeting-notes](https://github.com/nlink-jp/meeting-notes) — precedent: CLI → Skill conversion
- [product-research](https://github.com/nlink-jp/product-research) — the CLI being retired
