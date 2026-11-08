# ADR-029: Design before implementation, and independent passes bounded by the design

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-11-08 |
| Binds | organization |
| Decision makers | nlink-jp maintainers |
| Triggered by | The maintainer's judgement on 2026-11-08 that mail-dissect (`_wip`, unpublished) cannot be recovered, and the retrospective that followed: new projects go from the RFP straight to code, and independent passes run open-ended until they happen to stop |

## Context

mail-dissect takes a suspicious message apart and returns facts for the
lookup tools. Its RFP fixed the purpose and the scope from the start — URLs
from the text, the HTML, the headers and HTML attachments, in their original
form, with the WHATWG host, whether a link's visible text names another host,
wrapped URLs, at most 100 of them. The "Phase 1 plan" that followed was a list
of principles and a table of build steps; URL reading was one row of it.
Implementation began seven minutes after that plan was committed.

With no design, what to read and how far was decided in the triage of
independent reviews. Each round's findings were treated as holes and became
design changes; the robustness rule "every message is written by an attacker"
was read as "miss nothing a browser would see"; each round added a defence (a
work meter, per-document allowances, a separate reading merged back, a re-read
on exhaustion), and each defence brought the next round's regressions. Six
rounds did not converge. The maintainer, on 2026-11-08: *whatever is done, it
keeps over-engineering, keeps adding things, and changes the design each time
in a direction that does not converge — the fundamental design has broken
down.* The same shape had appeared a week earlier in mailparse's lenient
address reader: six rounds of patches, then a rewrite.

The records show how the organization got here:

| Period | Design written before the code | Examples |
|---|---|---|
| 2026-04 | Architecture (decisions with alternatives), detailed design (packages, errors, test design), development plan whose Phase 1 *is* design, with completion criteria | `gem-image` (`docs/ja/architecture`, `design`, `development-plan`) |
| 2026-06 – 07 | Decision records only, no detailed design | `pcap-analyzer-mcp` (7 of 10 ADRs before the first code), `data-toolbox-mcp` (5 of 12) |
| 2026-08 – 09 | No ADR before the first code | `voice-scribe`, `zip-porter`, `chrome-pilot-mcp`, `lagent`, `timeout` |
| 2026-10 – 11 | The RFP (and a Phase 0 measurement) only | `toml`, `mailparse`, `cert-lookup`, `vpn-lookup`, `mermaid-to-png`, `mail-dissect` |

The design step was a practice, never a rule. CONVENTIONS.md Phase 1 asks for
an RFP-level plan and its development-plan template reads "Phase 1: core
functionality + tests" — implementation first. The `rfp` skill ends with
"proceed to Phase 2 (Scaffolding)". The planning artifacts "can be lightweight
… or a conversation summary". Following the written rules faithfully skips
design, so the skipping never surfaced as a violation and no check could see
it. A first commit that holds everything at once can hide a design that
existed; the trend is clear regardless.

Independent passes drifted the same way. §Verify with an independent pass
asks for one pass when the design is fixed and one before release. From
2026-09 the practice became rounds until the severity falls (knowledge,
development-process.md: "An independent pass converges in rounds"), with the
reviewer told to *break* the work. Without a design to compare against, the
question "is there a hole?" always has an answer, and every answer becomes
design. The design verification that does exist checks recorded lessons and
specifications — not whether the design covers what the RFP requires, which is
where an omission would show early.

## Decision

1. **Planning has two parts: requirements, then design.** The RFP (the
   current seven items) is the requirements. Before scaffolding and before any
   production code, the project writes three documents in its repository,
   mirrored in `docs/en/` and `docs/ja/`:
   - **Architecture (conceptual design)** — the components and how data flows
     between them; which component carries each RFP item; each component's
     contract (the facts it returns and what it does not); what is out of
     scope; the non-obvious decisions with their alternatives.
   - **Detailed design** — per component: inputs, outputs, the procedure,
     bounds, error and hostile-input handling, and the test design including
     what decides a test's expected result.
   - **Development plan** — the order of work and each step's completion
     criteria. Its Phase 1 is design (these documents, verified and
     approved); core implementation is Phase 2.

   The documents are proportional to the tool — a page each for a small one —
   but never absent, and never a conversation summary. A Phase 0 measurement
   that a design rests on comes before the design, not instead of it.

2. **Design verification checks the design against the RFP.** In addition
   to the existing checks (recorded lessons; the specifications, ADR-023), an
   independent reviewer answers fixed questions: Does every RFP item map to a
   component, and every component to an RFP item — nothing missing, nothing
   beyond? For each component, are its inputs, outputs, bounds, failure and
   hostile-input handling, and test oracles decided? The author triages; the
   maintainer approves the design. Implementation starts after that approval.

3. **Implementation follows the design.** A change of design is made in the
   design documents and approved before the code changes. A finding that asks
   for behaviour the design does not define is a design change request, not a
   defect: it goes to the maintainer, and by default it is recorded as out of
   scope.

4. **Independent passes are bounded before they start.** The brief states
   what is checked against what (the implementation against the detailed
   design; the design against the RFP), how many passes there will be, and
   when to stop. The default for an implementation is one pass before release
   and one pass over the fix diff only. A reviewer may attack the work, but
   against the contract the design states. Findings are triaged into
   non-conformance (fix), design gap (a design change request under item 3)
   and out of scope (record). A third pass needs the maintainer's go-ahead
   with a reason. A high finding in the fix-diff pass sends the work back to
   the design, not into another round of patches.

5. **Scope.** New projects, and projects in `_wip` that are mid-way: they do
   not continue implementation until their design is written and approved.
   Published tools keep the existing rule (a non-trivial change is designed in
   an ADR before implementation) and take item 4 for their passes. Existing
   repositories are not retrofitted with design documents.

6. **Where it is carried out** (ADR-025: each project changes itself, as its
   own change):
   - `.github`: CONVENTIONS.md — Phase 1 split into requirements and design,
     the development-plan template, the "lightweight" sentence limited to
     requirements, §Verify with an independent pass rewritten for items 2–4;
     AGENTS.md summary.
   - `rfp` skill: its next step points to design, and its development-plan
     section follows the new template.
   - `knowledge`: "An independent pass converges in rounds" revised to the
     bounded pass; the lesson of this record added to development-process.md.

## Consequences

- A project starts slower: three documents and a design review before the
  first line of code. How long that takes was not measured (the April
  projects committed their documents and code together); mail-dissect's review
  rounds on one reader ran over two days without converging.
- Reviews get shorter and end: each pass has a reference, a count and a stop
  condition, and the maintainer sees design questions as design questions
  instead of as patches.
- mail-dissect and code-audit (`_wip`) stop where they are until their designs
  are written; whether mail-dissect is redesigned or withdrawn is decided
  separately.
- `check-org.sh` does not check the documents' presence (see Alternatives);
  the rule relies on the planning phase being followed. Revisit if design is
  skipped again.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Record the lesson in knowledge and memory only | The practice already existed in April and decayed precisely because it was never written into the rules the work follows. |
| Keep the RFP-only planning and strengthen design verification | There is nothing to verify: the design would still be made during review. |
| Cap the number of review passes, without a design | It limits the time but not the drift — the reviewer still has no reference, and every finding still becomes design. |
| `check-org.sh` requires the three documents | It could see only that files exist; every existing repository would need an exemption list. Deferred: revisit if the skipping recurs. |
| Have the `rfp` skill also produce the design | Design is its own phase with its own verification and approval; joining them would hide the gate. A design skill may come later, decided on its own. |

## References

- mail-dissect `_wip` (unpublished): `docs/ja/mail-dissect-rfp.ja.md` (first
  version 75781c0) and `docs/ja/mail-dissect-phase1-plan.ja.md` (8b2038d).
- `util-series/gem-image` `docs/{en,ja}/`: architecture, design,
  development-plan (2026-04) — the practice this record writes down.
- `nlink-jp/knowledge` development-process.md: "An independent pass converges
  in rounds — and the author's fix is where the next defect is" (to be
  revised).
- ADR-017 (placement), ADR-023 (design from the documentation), ADR-025
  (change a project only from inside it).
