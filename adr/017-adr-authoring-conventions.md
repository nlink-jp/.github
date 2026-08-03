# ADR-017: ADR Authoring Conventions — Mandatory Binds Field and a Placement Decision Tree

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-08-03 |
| Binds | organization |
| Decision makers | nlink-jp maintainers |
| Triggered by | Nine of this log's first sixteen records turning out project-scoped and moving out on 2026-08-03; the root-cause review found no placement rule existed when they were written, and nothing at authoring time forces the question today |

## Context

Between 2026-07-31 and 2026-08-03 this log accumulated nine project-scoped
records: five skill-design ADRs (007–011, authored 2026-07-31) and four
zip-porter internals ADRs (012–014 and 016, authored 2026-08-01 through
2026-08-03). All nine predate the placement rule: CONVENTIONS.md gained its
"which log a decision belongs in" paragraph only on 2026-08-03, together
with the first move. Until then the section said just "organization-wide
technical decisions are recorded in `adr/`" — it named no location for
project decisions at all, so the only codified log became the default sink.

Two mechanisms then did the damage:

1. **Imitation.** ADR format is learned by reading existing records (there
   is no template), and placement was learned the same way: the first
   misplaced record became the reference shape for the following eight.
   Imitating an existing ADR is not checking the convention.
2. **Residual ambiguity.** Even the 2026-08-03 rule mis-sorted hybrid
   records: its "a tool retired in favour of another goes here" clause read
   as keeping four of the five skill ADRs org-side, although their substance
   is one skill's design each. A hybrid clause (design payload to the
   successor's log, retirement fact stays in the index row and redirect) was
   added the same day.

What remains unaddressed is the forcing function. The placement rule lives
in prose that nothing obliges an author to consult at the moment of writing;
the header-table format (Status / Date / Decision makers / Triggered by) is
itself uncodified folklore; and the lesson exists only in machine-local
agent memory — exactly the gap the `knowledge` repository (ADR-015) exists
to close.

## Decision

**1. Codify the record template.** CONVENTIONS.md §ADR gains the canonical
header table and body-section list (Context / Decision / Consequences /
Alternatives considered / References). New records in both logs use it;
imitation then copies the correct shape.

**2. Make a `Binds` header field mandatory in new records.** Its value is
`organization` in this log and the project's name in a project log. Writing
it forces the placement question at authoring time — before the number is
spent — and a value that contradicts the log it sits in is visible at a
glance in review. Existing records are not retrofitted; for moved ones the
index rows and redirects already carry the information.

**3. Replace the placement prose with a decision tree plus the real
counterexamples.** Three ordered questions (constrains other projects? /
pure retirement fact? / everything else, incl. hybrid design payloads),
followed by the two misplacement patterns that actually happened, named as
counterexamples. Abstract criteria failed twice; worked examples are the
teaching device.

**4. Feed the lesson to the knowledge base.** One entry in
`knowledge` `docs/{en,ja}/development-process.md` (symptom → why → how to
apply), per the ADR-015 consult-and-feed loop.

## Consequences

- Authoring cost is one extra header row per record.
- There is no mechanical enforcement: `check-org.sh` does not verify the
  field. A presence check would catch only omission, not the wrong value —
  and the wrong value is the actual failure mode. Revisit if misplacement
  recurs despite the template.
- The org log's index now teaches placement by counterexample: five Moved
  rows from this cleanup sit next to the rule that would have prevented
  them.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Add a `check-org.sh` check that org-log Accepted records carry `Binds: organization` | Catches omission, not misjudgment (the observed failure mode); declined for now to keep the checker semantic-free — revisit on recurrence |
| Retrofit `Binds` into all existing records | Churn across 17 org + ~40 project records to state what index rows and redirects already record; no new decision is being made in those files |
| Rely on agent memory alone | Machine-local and advisory — the exact limitation ADR-015 names; a template field is present at the moment of writing, memory may not be |
| Leave the 2026-08-03 prose rule as-is | The nine misplacements were produced by imitating records, not by reading prose; prose alone leaves imitation as the operative channel |

## References

- [ADR-015](015-knowledge-repository.md) — knowledge base and the consult-and-feed loop
- ADR-007–011 redirects ([007](007-service-research-skill.md), [008](008-incident-research-skill.md), [009](009-incident-review-skill.md), [010](010-incident-research-ioc-stix.md), [011](011-compliance-review-skill.md)) — the skill-design misplacements
- ADR-012–014/016 redirects ([012](012-zip-porter-hardening.md), [013](013-zip-porter-parallel-compression.md), [014](014-zip-porter-zlib-parallel-deflate.md), [016](016-zip-porter-batch-completion.md)) — the app-internals misplacements
