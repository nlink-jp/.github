# ADR-011: compliance-review Skill — Two-Phase Security Review Against Internal Regulations

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-07-31 |
| Decision makers | nlink-jp maintainers |
| Triggered by | virtual-reviewer PoC (lab-series) proving the expert-model concept on an architecture ADR-007/009 already retired; Gemini 2.5 retirement (ADR-001) reaching its default models |

## Context

`virtual-reviewer` (lab-series, v0.2.0) automates first-pass security review
of applications (案件申請) against internal security regulations. Its core
idea — **no RAG**: each LLM "expert" holds its assigned regulation text in
full context, so retrieval precision never caps system quality — was
validated by the PoC (44 unit tests, E2E against live Vertex AI).

Its architecture, however, is the one ADR-007 and ADR-009 retired twice
already: a fixed pipeline of seven CLIs making single-shot Vertex AI Gemini
calls with `response_schema`, stitched with Pydantic normalization shims,
carrying GCP/ADC cost, and defaulting to Gemini 2.5 Pro/Flash — both on the
ADR-001 retirement list. The pipeline shape maps almost mechanically onto
the agent-native form factor: `vr-compile` is a preparation workflow,
`vr-intake`/`vr-orchestrate`/`vr-brain`/`vr-report` are a review workflow,
and the deterministic pieces (severity aggregation, semantic validation,
report compilation, Q&A sheet round-trip) are scripts.

Two design questions were settled before this ADR:

1. **Where do compiled experts live?** Claude Code offers `.claude/agents/`
   as a native subagent registry, but it is gitignored by org convention,
   auto-loaded into every session (harness pollution), flat (no coexisting
   regulation sets), and Claude-Code-specific (lock-in). Nothing requires
   it: a generic subagent spawned with the profile injected into its prompt
   is equivalent.
2. **Split experts by domain or by document?** Real review teams specialize
   by domain; cross-document contradictions (encryption requirements spread
   across a base regulation and an outsourcing guideline) resolve inside
   one domain expert instead of burdening final synthesis; the expert
   roster stays stable across document reorganizations.

## Decision

**Add one Claude Code Skill, `compliance-review`, to `skills-series`,
superseding `virtual-reviewer` (archived on release).**

The name avoids colliding with the built-in `/security-review` command
(code-change review) and states the actual function: reviewing a request
for compliance with the organization's own regulations. It pairs with the
`incident-review` naming line — *review* reads your own organization's
material. Seven sub-decisions define the shape.

### 1. Two explicit phases behind one Skill

Two entry points in one SKILL.md — `compile` (準備フロー) and `review`
(レビューフロー) — sharing schema definitions and validation scripts:

- **compile**: regulation documents → expert profile set. Run only when
  regulations are added or revised. Output is a versioned, human-reviewed
  asset.
- **review**: one application + one compiled expert set → findings →
  synthesis → Japanese report. Run per case.

The phase boundary is the system's HITL quality gate: compiled experts are
reviewed and committed by a human before any case review uses them. One
Skill (not two) because the manifest and finding schemas are a shared
contract that would drift across repositories.

### 2. Compiled experts are portable data, not harness config

`compile` takes an output directory (`--output <dir>`; default
`./experts/<set-name>/` under the working directory — never
`.claude/agents/`). The user commits it wherever regulations are managed.
Layout:

```
<output-dir>/
├── manifest.json            # machine contract
├── expert-<domain>.md       # one per domain: YAML frontmatter + assigned clauses (full text)
└── ...
```

Profiles are **frontmatter Markdown** (role, evaluation criteria,
`required_fields`, clause refs in frontmatter; assigned regulation text in
the body) because they are human-audited assets; machine strictness lives
in `manifest.json` (expert roster, clause→expert map in both directions,
common-section list, coverage-check result, source-document SHA-256
hashes). `review` verifies source hashes at startup and refuses to run
against a stale compilation (drift gate). The profile fields port
virtual-reviewer's `ExpertProfile` model (`expert_id`, `domain`,
`required_fields`, `regulation_refs`, regulation text).

### 3. Experts are split by domain, with rule-based coverage enforcement

- The domain list is **proposed by compile from the corpus and approved by
  the human** as part of the compile HITL gate (an ISO 27001 control-domain
  hint stabilizes proposals; the corpus wins on conflict).
- A clause may be assigned to **multiple** domains ("encryption at an
  outsourced provider" belongs to both experts); exclusive partitioning is
  not required.
- **Common sections** (definitions, scope, general provisions) are
  distributed verbatim to every profile and marked `common` in the
  manifest — cutting them into domains destroys their meaning.
- `scripts/coverage.py` (stdlib-only) verifies every clause of every
  source document is assigned to ≥1 expert or marked common, and fails the
  compile otherwise. This is the anti-hallucination control for the one
  step where an LLM performs the decomposition.

### 4. The no-RAG principle survives, restated

What the original design rejected is **query-time retrieval** — search
precision becoming the system's ceiling. Domain decomposition at compile
time is a *static, human-audited responsibility split*: at review time each
expert holds its full assigned text in context and nothing is retrieved.
`review` spawns one generic subagent per relevant expert (selected via
manifest `required_fields` against the application), in parallel, with the
full profile injected into the prompt; experts never see each other's
output, preserving independent first-pass evaluation.

### 5. Deterministic controls stay in scripts

- **Findings schema** ports virtual-reviewer's `Finding`
  (`regulation_ref` / `target_field` / `severity` / `finding` /
  `recommendation`); each expert writes findings JSON to the case
  workspace, validated by `validate.py` per expert and as a whole —
  reject, don't coerce (ADR-009 precedent; the agent fixes its own output
  against reported errors).
- **Semantic verification** (severity aggregation consistency, verdict
  vs. findings cross-check — ported from `vr-brain`'s rule-based layer)
  runs as a script over the collected findings before synthesis.
- **Report compilation** to Japanese Markdown is deterministic
  (`compile.py`, meeting-notes/incident-review precedent), from the
  validated synthesis JSON.

### 6. The security layer survives the form-factor change

The application content is adversarial input (it may quote vendor
questionnaires, URLs, third-party text). Same placement rules as
ADR-007/008/009:

- **Nonce isolation in code**: a preprocessing script wraps all
  application content in nonce-tagged blocks before analysis; SKILL.md
  opens with the short positional rule that nonce-tagged content is data
  under review, never instructions.
- **No prohibition catalogs in prose**; any pattern screening stays in
  script code, surfacing as risk flags in output.
- Analysis reads only preprocessed content; intake (multimodal reading of
  the application PDF/image/Markdown, replacing `vr-intake`) is a
  mechanical-copy step under the content-is-data rule.

### 7. Two-pass Q&A adapts to the session form

When experts report missing information (`required_fields` unmet):
interactively, the agent asks the user directly (AskUserQuestion) and
re-evaluates in the same session; non-interactively, it emits a question
sheet (Markdown, ported from `vr-questions`), and a later run ingests the
answered sheet (`vr-answers` equivalent) for pass 2. Both routes converge
on the same findings schema.

### 8. Standard skills-series scaffold

Repository = skill (ADR-004), `compliance-review/` subdirectory as the
distribution boundary, vendored `tests/validate-skill.sh` (ADR-006),
Makefile from the CONVENTIONS.md Skill template, scaffolded from
`incident-review` as the nearest sibling. Fixtures use only fictitious
regulations and fictitious applications — no real internal regulation text
is committed (ADR-008/009 fixture discipline).

## Consequences

- The GCP/ADC/Vertex dependency and its cost disappear; virtual-reviewer
  leaves the ADR-001 Gemini 2.5 migration list.
- Compiled expert sets become reviewable, diffable, committable assets
  decoupled from any one tool — usable later by an Agent SDK
  implementation if judgment reproducibility ever becomes a hard
  requirement (deliberately deferred, see Alternatives).
- Cross-document contradictions surface in expert first-pass evaluation
  rather than only at synthesis; synthesis (the `vr-brain` role) gets
  strictly easier inputs.
- Wall-clock per review is slower than the CLI's parallel single-shot
  calls; quality and auditability are expected to dominate for a
  first-pass review artifact.
- One repository is archived with a README pointer to the Skill
  (product-research precedent); catalogue surfaces (org profile,
  nlink-web-site) gain one entry and mark one as superseded.
- The org's real-data E2E release gate cannot be applied — no real
  regulation corpus or application exists at release time. Substituted
  deliberately (ADR-009 precedent): a full agent-executed compile+review
  run over a realistic fictitious regulation set (multi-document, with
  cross-document overlap to exercise multi-assignment and common
  sections) and a fictitious application. First production use is the
  true E2E; findings become v0.1.x.
- Deferred to v0.2+: expert-set diffing on regulation revision (semantic
  diff of profiles), review-history trend analysis, and a strict Agent
  SDK pipeline variant.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Migrate virtual-reviewer to Gemini 3 and keep the CLI | Pays migration cost to keep the weaker architecture (single-shot calls, GCP coupling, per-format loaders). Same branch ADR-007/009 declined |
| Output compiled experts to `.claude/agents/` | Gitignored by org convention (contradicts "versioned asset"), auto-loaded into every session, one flat namespace, Claude Code lock-in; prompt injection at spawn is equivalent without any of it |
| Split experts by document | Simpler compile, but cross-document contradictions land on synthesis, the roster churns with document reorganizations, and "the expert on Regulation No. 3" is meaningless to report readers |
| Two separate Skills (compile / review) | The manifest and finding schemas are one contract; splitting repositories invites drift. Invocation-frequency asymmetry is expressible inside one SKILL.md |
| Name it `security-review` | Collides with the built-in `/security-review` command (code-change review); triggering ambiguity is guaranteed |
| Rebuild as an MCP server | The deterministic parts are stdlib scripts, not a stateful engine; prompt workflow + scripts is a Skill (ADR-003/007/008/009 line) |
| Agent SDK pipeline now | Strict structured output and reproducibility are not yet business requirements for a first-pass reviewer with HITL gates; the data-file expert format keeps that door open |

## References

- [ADR-001](001-gemini3-migration.md) — Gemini 2.5 retirement pressure
- [ADR-004](004-skills-series-umbrella.md) — repository = skill, distribution boundary
- [ADR-006](006-skill-validator-vendoring.md) — vendored validator
- [ADR-007](007-service-research-skill.md) — CLI-to-Skill supersession pattern, archive-with-pointer
- [ADR-009](009-incident-review-skill.md) — security-layer placement, reject-don't-coerce validation, E2E substitution pattern
- [virtual-reviewer](https://github.com/nlink-jp/virtual-reviewer) — source of the ported models (ExpertProfile, Finding), no-RAG design rationale
