# ADR-027: `mcp-tactics` Covers What Its Doctrine Governs; a Tool's Own Craft Ships as a Skill With the Tool

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-11-04 |
| Binds | organization |
| Decision makers | nlink-jp maintainers |
| Triggered by | Adding `report-studio-mcp` to `mcp-tactics` (mcp-tactics#1) and planning its writing-support skill as a skills-series repository (skills-series#1) — two questions that turned out to share one cause: `mcp-tactics`' scope was drawn by what a server is, not by the problem it exists to solve |

## Context

ADR-003 created `mcp-tactics` for one expensive failure: an agent silently
escalating from a passive lookup to an active one and alerting the party
under investigation. Its organizing principle is a single axis — who can
observe that you asked — which ADR-018 refined into four tiers, from no
external observer to contact from our own IP. Everything the skill teaches
well is a position on that axis or a consequence of one: urlscan's `search`
before `scan_url`, the keyed lookups last, investigation material kept on
the machine.

Its scope, however, was written as "MCP servers only" — every in-house
server, 15 at the time. That drew the boundary by what a thing is, not by
the problem. The production servers (`voice-studio`, `video-studio`,
`image-forge`) have no position on the axis — there is no party to alert
and no investigation material leaving — yet they were in the first release,
description and all. What followed from that one line:

- Their trigger words take room in a description that stands at 1,020 of the
  1,024 characters the apps accept, crowding the investigation triggers.
- With no axis to place them on, their entries filled with each server's own
  call sequence (voice-studio's five steps in `references/media.md`) — the
  craft of one tool, which ADR-003 §2 says belongs to the server.
- Each new production server raises the same question again. `report-studio-mcp`
  (mcp-tactics#1) has no tier to sit in, and its writing guidance had no home:
  `get_usage` is the call contract, `mcp-tactics` is the wrong altitude, so
  the RFP reached for a separate skills-series repository (Discussion Log 7,
  skills-series#1).

That last reach has been made once before and reversed. `voice-studio-mcp`
planned its production skill as a separate skills-series project and moved
it into its own repository after v0.1.0 (its ADR-0009, ADR-0011): most of the
skill named the server's contracts, every change to them needed a
synchronized edit elsewhere, and nothing failed when one was missed.

## Decision

**1. `mcp-tactics` covers the servers its doctrine governs.** A server
belongs in it when choosing it, or the order of its calls, changes who can
observe an investigation or where its material goes. A server for which
neither can change — one that only produces an artifact on this machine
from what it is given — does not, however it is built. This replaces
ADR-003's "MCP servers only" scope; the four tiers (ADR-018) and the
"selection and ordering only, never parameters" rule (ADR-003 §2) stand.

Applied today: `voice-studio`, `video-studio` and `image-forge` leave
`mcp-tactics`, and `report-studio-mcp` is not added. The rest stay —
including `data-toolbox` (evidence analysed locally rather than sent
elsewhere), the two transcription servers (whether a recording leaves the
machine) and the second-opinion servers (material sent to another model's
provider).

**2. A tool's own craft ships as a skill bundled with the tool.** How to do
good work with one tool — preparing its input, choosing among its options,
acting on what it reports, the hand-offs into and out of it — is a skill in
that tool's repository, changed in the same commits and releases:

- It uses the skills-series layout — `<skill-name>/` at the repository root
  — and the organization's skill validator in the tool's `make test`.
- The tool's tests hold it to the server in both directions: every tool,
  error or warning code and directive it names exists in the server, taken
  from the server's own registrations where it has them, and every retired
  name is held absent. A presence-only test let a retired argument survive in
  eight files of voice-studio's skill.
- It builds on `get_usage` and does not restate it; `get_usage` stays the
  call contract and keeps the minimum a client without the skill needs.
- It ships as a separate release asset, and the tool's README tells each
  caller it declares how to install it.

A tool gets one only when it has craft beyond its `get_usage`.

**3. skills-series holds skills that are not one tool's craft** — work over
many tools or none. When a tool's RFP first mentions a skill, the placement
is decided per piece of content: what is this tool's craft goes with the
tool; what is not (writing a report in general, say) is a skills-series
question.

**4. Carried out inside each project** (ADR-025). This repository adds the
CONVENTIONS section, the index row, and ADR-003's "Amended by" reference.
The rest are issues in their own repositories:

- `mcp-tactics` — remove the production servers, their triggers and
  `references/media.md`'s production half; close mcp-tactics#1.
- `report-studio-mcp` — a bundled skill for its craft and the
  investigation → manuscript → `render` hand-off.
- `skills-series` — skills-series#1 narrowed to what is not report-studio's
  craft, or closed; that series' decision.
- `voice-studio-mcp` — move its skill to the root layout and derive its
  tests from the server.

## Consequences

- `mcp-tactics` is again one doctrine with one axis, and its description's
  room goes to the investigations it exists for.
- Production servers have no cross-fleet router. Their purpose is stated in
  the first sentence of their own instructions, and a hand-off between them
  (voice-studio → video-studio) is the craft of the tools involved — in
  their skills or their `get_usage`.
- A tool and its craft are reviewed and released together; drift is caught
  as far as the tests derive from the server.
- The skill and the server install separately (Homebrew installs the binary
  only); the tool's README is where a user learns there is a skill.
- How the skill validator is distributed (today a vendored copy, ADR-006) is
  a separate question; this record only requires that bundled skills are
  validated by it.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Keep production servers in `mcp-tactics` as "situations", widening its doctrine to cost and data flow in general | Tried in drafting this record: it turned the scope error into a general theory of tool guidance, and the router into a catalogue whose entries have nothing to rank |
| Add `report-studio-mcp` like the other production servers | Repeats the scope error for a fourth server |
| A separate tactics skill for production servers | There is no choice to guide: the artifact asked for names the server |
| Keep a tool's skill in skills-series | voice-studio moved it back after release because every contract change needed a synchronized edit elsewhere |
| Put the craft in `get_usage` only | `get_usage` is the contract; judgement about writing for a tool is not, and keeping it there grows the contract with prose |

## References

- [ADR-003](003-mcp-tactics-skill.md) — `mcp-tactics`; its Scope is replaced by Decision 1
- [ADR-004](004-skills-series-umbrella.md) — skills-series as one repository per skill
- [ADR-006](006-skill-validator-vendoring.md) — the skill validator's distribution
- [ADR-018](018-mcp-observability-tiers.md) — the four tiers
- [ADR-025](025-change-a-project-only-from-inside-it.md) — how Decision 4 is carried out
- `voice-studio-mcp` ADR-0009, ADR-0011; `skills/skills_test.go`
- `report-studio-mcp` RFP, Discussion Log 7
- nlink-jp/mcp-tactics#1, nlink-jp/skills-series#1
