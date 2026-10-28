# ADR-025: A project is changed only from inside it — work elsewhere files an issue

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-10-29 |
| Binds | organization |
| Decision makers | nlink-jp maintainers |
| Triggered by | Work on one project (agent-activity-lens) wrote ADRs, code and documentation into two other projects (gem-agent, lagent) on the strength of its own plan's approval |

## Context

On 2026-10-29 a new util-series tool, agent-activity-lens, was being planned:
it would count, from agent transcripts, which instruction files sessions load
and which files they touch. gem-agent and lagent do not record which
instruction files they load at startup. Instead of treating that as a limit of
the tool ("not recorded"), its RFP added a **Phase 0**: add an `instructions`
record to both runtimes.

After the RFP was approved, the session building the tool delegated Phase 0 to
two agent sessions, which, inside gem-agent and lagent:

- wrote and numbered ADRs in each project's own log (gem-agent ADR-0100,
  lagent ADR-0033) and added them to the projects' indexes — decisions the
  projects' owner had not made, recorded as the projects' own;
- edited the text of existing ADRs (gem-agent ADR-0089/0090, lagent
  ADR-0020/0021) to move line citations their code change had shifted;
- changed code, reference documentation and CHANGELOGs, and committed on
  `main` minutes after the owner had released gem-agent v0.92.1 and lagent
  v0.19.1;
- rebuilt the development binaries in each project's `dist/`.

The change was additive and readable by older versions. That did not make it
acceptable: lagent ADR-0023 places the transcript format under the cli-series
stability contract, the projects' owner had not been asked, and a tool that
measures the runtimes had altered what it measures. Both repositories were
reset to `origin/main` (nothing had been pushed), the owner's own session
restored `dist/`, and agent-activity-lens was cancelled.

Three things let it happen, none of them written down anywhere:

1. **A plan for one project contained a phase that changed another.** The
   approval of agent-activity-lens's RFP was read as approval of changes to
   gem-agent and lagent; inside someone else's plan, their weight was not
   visible.
2. **The workspace makes every repository one `cd` away.** Umbrellas check out
   every project side by side, and a session or a subagent it delegates to can
   write anywhere it can reach.
3. **A measuring tool treated missing data as the subject's defect.** The
   natural fix — make the subject record it — is a change to the subject.

## Decision

### 1. A repository is changed only by work done in it

A change to a repository is made as that repository's own work: its own
session or working context, its own conventions, ADR log, tests and release
cadence, decided by its owner. Work whose purpose is another project does not
change it.

### 2. From outside, a need is an issue

Work on one project that finds it needs something from another repository
opens an **issue** on that repository: what is needed, why, the evidence, and
— if useful — a proposed change. It does not edit files, commit, open a
branch, write or number an ADR, edit an existing ADR, or rebuild artifacts
there.

The requesting work then stays within its own boundary: it designs around the
absence or waits for the issue to be decided. Its plan names the dependency
as an open issue, **never as a phase of its own plan**.

### 3. What counts as changing a project

Code; documentation; ADRs (a new record, a number taken, an existing record's
text); record and output formats; configuration; build artifacts in `dist/`;
branches, tags and commits. Reading another project — its code, documents,
records — to understand it remains fine.

### 4. It binds people and agent sessions alike

The rule applies to maintainers and AI agent sessions equally, however close
the checkouts are. An agent session delegated by another carries the
delegating work's project boundary: being handed a task does not widen what a
session may change.

### 5. A measuring tool never changes what it measures

A tool that collects, measures or analyses another project's output does not
change that project to make it measurable. What the subject does not record is
reported as not recorded. Wanting the subject to record more is an issue on the
subject (§2), decided by its owner on its own merits.

### 6. Organization decisions are carried out inside each project

A decision in this log binds every project; carrying it out is each project's
own change, made in that project — one repository at a time, with its own
commit and release, as organization-wide sweeps already are. Updating an
umbrella's submodule pointer after a project's release is part of the release
process and is unchanged.

## Consequences

- A project may have to ship without what it wanted from another, stating the
  limit, or wait for an issue. That is the intended cost: the owner of each
  project decides what it becomes.
- Issues become the visible queue of cross-project requests, where they can be
  weighed against the subject's own plans instead of arriving as commits.
- `CONTRIBUTING.md` (+ `.ja`) states the rule for everyone, inside or outside
  the organization; `CONVENTIONS.md` §Development Policy and `AGENTS.md` state
  it for maintainers and agent sessions.

## Alternatives considered

**A. Allow cross-project changes once the requesting plan is approved.** This
is what happened: approving one project's plan was taken as approving changes
to two others, whose owner never saw them as changes to their projects.

**B. Allow additive, backward-compatible changes.** The change was additive
and compatible, and still wrong: it recorded decisions in the projects' names,
rewrote existing ADRs, landed on a just-released `main`, and changed what a
measuring tool measured.

**C. Cross-repository pull requests inside the organization.** A pull request
is still code written for a project outside its own work, and it presupposes a
design. An issue carries the need and leaves the design to the project.

**D. Keep the rule in agent memory only.** Memory binds one agent's sessions;
the rule belongs where every contributor and session reads it.

## References

- ADR-017 — which log a record belongs in (a project's ADRs are its own)
- ADR-024 — outside contributions (issues first)
- lagent ADR-0023 — the cli-series stability contract covers the transcript
  format
- `CONVENTIONS.md` §Development Policy, `CONTRIBUTING.md` (+ `.ja`)
