# ADR-008: incident-research Skill — Deep-Dive Research on Public Security Incidents

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-07-31 |
| Decision makers | nlink-jp maintainers |
| Triggered by | service-research (ADR-007) covering *products*; no tool covers researching a security *incident* itself from news and primary sources |

## Context

`service-research` (ADR-007) vets a product or service, and its
`known_incidents` angle only asks "has this vendor had incidents?" as one
input to a product risk rating. There is no tool for the inverse and deeper
question: **given one publicly reported security incident** — a breach, a
ransomware case, a leak, an exploited vulnerability — collect the news and
primary sources, reconstruct what happened, and emit a structured report.

That work is currently done ad hoc in chat sessions, with the familiar
failure modes: sources cited from memory rather than read, timelines mixing
disclosure dates with occurrence dates, early reporting quoted as settled
fact, and no machine-readable output to compare or archive.

The organization has two shipped precedents for exactly this artifact
shape: `meeting-notes` and `service-research` — Skills whose product is a
prompt workflow plus a JSON schema plus stdlib-only validate/compile
scripts, distributed per ADR-004/ADR-006.

## Decision

**Add one Claude Code Skill, `incident-research`, to `skills-series`.**

Four sub-decisions define its shape.

### 1. Scope: public security incidents, single deep-dive

In scope: one named, publicly reported security incident (breach,
ransomware, data leak, supply-chain compromise, vulnerability
exploitation) researched in one pass. Out of scope for v0.1, by explicit
decision: continuous watch / re-research of an evolving incident, and
discovery sweeps ("find this week's notable incidents"). Non-security
news events (outages, recalls) are also out — the schema's value is its
security-specific structure.

This is **public-information research, not incident response**: it reads
what journalists, victims, regulators, and vendors have published. It
never touches the affected party's infrastructure — no scanning, no
probing, nothing beyond reading published pages (the mcp-tactics
OpSec line, applied here to a Skill).

### 2. The schema is timeline-centric with source-tier and confidence semantics

Three structural properties distinguish it from service-research's schema:

- **Timeline as the spine.** Incident knowledge is a sequence of dated
  facts (occurrence, detection, disclosure, updates), each entry carrying
  its own date and source. Occurrence date and disclosure date are
  separate fields — conflating them is the most common error in ad hoc
  incident summaries.
- **Three source tiers.** Every source is classified `primary` (victim
  statements, regulator filings, court records), `secondary` (press
  reporting), or `analysis` (security-vendor research). Claims resting
  only on secondary sources stay visibly weaker than ones with primary
  backing.
- **Confidence-qualified attribution.** Threat-actor attribution and
  attack-vector fields carry an explicit `confidence` level
  (`confirmed` / `reported` / `suspected` / `unknown`); for ongoing
  incidents, unconfirmed reporting is marked as such rather than
  upgraded to fact. Fabrication is prohibited; `unknown` is a valid
  answer.

### 3. Sources are pages actually read

The ADR-007 rule carries over verbatim: the agent runs multiple searches,
fetches and reads the actual articles, disclosures, and advisories, and
`sources` lists only URLs it actually opened. A stdlib-only
`scripts/validate.py` checks schema conformance per section (`--part`)
and overall; `scripts/compile.py` renders Markdown, Japanese by default
with `--lang en`.

### 4. Standard skills-series scaffold

Repository = skill (ADR-004), `incident-research/` subdirectory as the
distribution boundary, vendored `tests/validate-skill.sh` (ADR-006),
Makefile from the CONVENTIONS.md Skill template, scaffolded from
`service-research` as the nearest shape. `SKILL.md` opens with injection
defense — the skill's entire input is adversary-observable web content,
and incident coverage in particular attracts SEO-poisoned and
attacker-planted pages.

## Consequences

- Incident deep-dives become repeatable and comparable: same schema, same
  source-tier discipline, archived JSON alongside the Markdown report.
- `service-research` keeps its shallow `known_incidents` angle unchanged;
  a vendor vetting can now link out to full `incident-research` reports
  when an incident warrants depth. No overlap is removed in v0.1
  (revisit only if drift between the two actually appears).
- Report quality varies with the session model and with what the press
  has published — a thin news trail yields a thin report, made honest by
  `unknown` fields rather than padding.
- One more entry on the two catalogue surfaces (org profile,
  nlink-web-site) per the release checklist. No repository is archived
  by this ADR.
- v0.2+ candidates deliberately deferred: continuous-watch mode (diff an
  existing report against new reporting), discovery sweeps, and IOC
  extraction feeding the cybersecurity-series lookup tools.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Extend service-research's `known_incidents` into deep-dive mode | Two report types (product rating vs. incident reconstruction) behind one schema and one SKILL.md; both workflows get harder to follow. Precedent: mcp-tactics stays selection-only for the same reason |
| Build a news-collector CLI (feeds/APIs) with LLM summarization | Recreates exactly the plumbing ADR-007 just retired — and single-shot summarization over fetched text is the weak research phase the Skill form factor fixes |
| Rebuild as an MCP server | No state, credentials, or local engine to mediate; a pure prompt workflow is a Skill (ADR-003/ADR-007 line) |
| General "news-research" scope, security as one case | The schema's value (attribution confidence, source tiers, breach-specific fields) is security-specific; generalizing dilutes it. Explicit scope decision |

## References

- [ADR-003](003-mcp-tactics-skill.md) — Skill as the artifact form; OpSec framing
- [ADR-004](004-skills-series-umbrella.md) — repository = skill, distribution boundary
- [ADR-006](006-skill-validator-vendoring.md) — vendored validator
- [ADR-007](007-service-research-skill.md) — agentic research pattern; sources = pages read
- [service-research](https://github.com/nlink-jp/service-research) — scaffold reference and the adjacent product-scope tool
