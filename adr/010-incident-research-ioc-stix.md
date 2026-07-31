# ADR-010: incident-research v0.2 — IoC Extraction and STIX 2.1 Output (absorbing ioc-collector)

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-07-31 |
| Decision makers | nlink-jp maintainers |
| Triggered by | ioc-collector fits the CLI→Skill conversion profile (ADR-007/008/009 precedents); ADR-008 explicitly deferred "IOC extraction feeding the cybersecurity-series lookup tools" to v0.2+ |

## Context

`ioc-collector` (cybersecurity-series, Python, ~900 lines) researches a
security incident from a URL / CVE ID / free-text query via Gemini web
research and emits a Markdown report plus a STIX 2.1 bundle. Its profile
matches the three completed CLI→Skill conversions exactly: the core value
is a research prompt workflow plus output schemas, the Gemini plumbing
(Vertex AI client, ADC, config) is pure maintenance cost, and it sits on
the Gemini 3 migration list (ADR-001).

Meanwhile `incident-research` (ADR-008) already researches the same
subject — one publicly reported security incident — with a stronger
research discipline (source tiers, read-before-cite, confidence
qualifiers) but produces no indicator output. ADR-008 listed IOC
extraction as a deliberately deferred v0.2+ candidate.

Running two research pipelines over the same incidents, one weaker,
differing only in output format, is the drift ADR-008 warned about.
A separate ioc Skill was considered and rejected (see Alternatives):
the decision is to converge.

## Decision

**Extend `incident-research` to v0.2 with an IoC layer and a STIX 2.1
compiler; archive `ioc-collector` after release.** No new Skill, no new
repository.

Five sub-decisions define the shape.

### 1. `iocs` becomes a required top-level array in schema.json

Each entry: `type` (enum mirroring the STIX SCO set carried over from
ioc-collector: `ipv4-addr`, `domain-name`, `url`, `file-hash-md5`,
`file-hash-sha1`, `file-hash-sha256`, `file-name`, `process-name`,
`other`), `value`, `description`, and `source_url` (must be a URL listed
in `sources` — same rule as timeline entries). An empty array is valid:
many incidents never get published indicators, and "none published" is
an answer, not a gap to fill. Fabricating indicators is prohibited by
the same schema-description language that already governs attribution.

Top-level (a sibling of `sources`), not nested under `attack_details`:
it is a machine-consumed list with its own compiler, like `sources`.

### 2. Defanged at rest, refanged only inside the STIX compiler

IoC values are stored **defanged** in the JSON and rendered defanged in
the Markdown report (safe sharing by default — the ioc-collector rule).
ioc-collector's `defang.py` is ported as a stdlib-only helper: the
refang/defang pattern tables, idempotency, and the no-defang type set
(hashes, file/process names) carry over as-is; only the Pydantic enum
import is replaced. Real (refanged) values exist only inside the
generated STIX bundle, which is the machine-facing artifact.

### 3. STIX 2.1 emission is a deterministic bundled script, stdlib-only

A new `scripts/stix.py` reads a **validated** report JSON and emits the
STIX 2.1 bundle (Indicators with `pattern_type: stix` + one Report
object referencing them). The LLM never writes STIX by hand.

The bundled-scripts rule of this repo (stdlib-only Python, no
third-party dependencies) means the `stix2` library does not come
along. The generated object set is deliberately narrow — bundle,
report, indicators, `indicator--<uuid4>` / `report--<uuid4>` ids,
RFC 3339 UTC timestamps — so a stdlib reimplementation is small, and
correctness is held by script tests against fixture bundles instead of
library-side validation.

One deviation from ioc-collector: entries of type `other` are kept in
the JSON and Markdown but **excluded from the STIX bundle** (with a
stderr note). ioc-collector stored them as `pattern_type: sigma`, which
misdeclares free-text as a Sigma rule; dropping that hack is correct
rather than lossy.

### 4. IoC collection is a workflow step, not a new mode

During section research (primarily the `attack_details` pass), IoCs are
collected from pages actually read, each with the `source_url` of the
page it appeared on. `validate.py` gains the `iocs` checks;
`compile.py` renders a defanged IoC table in the Markdown report.
STIX emission runs as a standard final step after full-report
validation — it is cheap and deterministic, so it is not optional
behavior to configure.

### 5. ioc-collector is archived after v0.2.0 ships

Same sequence as product-research (ADR-007) and ai-ir/ai-ir2 (ADR-009):
release incident-research v0.2.0, verify, then archive the
`ioc-collector` repository with a README pointer to the Skill. This
removes ioc-collector from the Gemini 3 migration scope (ADR-001) and
from both catalogue surfaces.

## Consequences

- One research pipeline per incident: the stronger discipline
  (source tiers, confidence, read-before-cite) now also governs
  indicator extraction, which ioc-collector never had.
- **Schema break:** v0.1 reports fail validation against the v0.2
  schema (`iocs` is required). Accepted — reports are point-in-time
  artifacts, not a migrated dataset; the version bump signals it.
- The lightweight ioc-collector use case ("one URL in, IoCs out") now
  rides the full deep-dive workflow and costs accordingly. Accepted
  trade-off of the merge decision; if the pain is real, a slim
  extraction path is a v0.3 candidate — not speculatively built now.
- STIX correctness shifts from the `stix2` library to a fixed narrow
  generator plus fixture tests. Bundles remain plain STIX 2.1 JSON,
  consumable by standard tooling.
- `--non-interactive` / stdin pipeline automation of ioc-collector has
  no Skill equivalent and is dropped with the archive.
- v0.2+ candidates from ADR-008 that remain open: continuous-watch
  mode, discovery sweeps. New candidate: feeding extracted IoCs into
  the cybersecurity-series lookup MCP servers within the session.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Separate `ioc-research` Skill alongside incident-research | Duplicates the entire research pipeline (search, source tiers, read-before-cite) for a different output format; the two would drift exactly as ADR-008's Consequences warned. Deliverable-per-skill (ADR-007/008) applies to disjoint scopes, not the same subject |
| Keep ioc-collector CLI and migrate it to Gemini 3 | Pays the migration and Vertex plumbing cost to keep the weaker of two research pipelines alive |
| Use the `stix2` library in bundled scripts | Violates the repo's stdlib-only rule; bundled scripts must run on any host the skill lands on, with no package installation step |
| Let the LLM emit the STIX bundle directly | Nondeterministic spec conformance; validation would have to chase free-form output. Deterministic compile from validated JSON is the established meeting-notes/incident-research pattern |
| Make `iocs` optional in the schema | Optional fields rot — absence becomes ambiguous ("none published" vs "step skipped"). Required-but-empty keeps the extraction step honest |

## References

- [ADR-001](001-gemini3-migration.md) — migration scope this ADR shrinks
- [ADR-004](004-skills-series-umbrella.md) — repository = skill, distribution boundary
- [ADR-006](006-skill-validator-vendoring.md) — vendored validator
- [ADR-007](007-service-research-skill.md) — CLI→Skill conversion + archive precedent
- [ADR-008](008-incident-research-skill.md) — the extended Skill; IOC extraction named as v0.2+ candidate
- [ADR-009](009-incident-review-skill.md) — archive-after-supersede precedent
- [ioc-collector](https://github.com/nlink-jp/ioc-collector) — the absorbed CLI (defang tables and SCO type set carry over)
