# ADR-020: Records Repositories Hold Review Submissions Outside the Series Taxonomy

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-09-13 |
| Binds | organization |
| Decision makers | nlink-jp maintainers |
| Triggered by | The system-risk review submission covering gem-agent, lagent and mcp-bridge (2026-09-12) needing a home in version control; no existing repository fit, and forcing it into one would either demand an English mirror of a 140 KB Japanese document or publish a consolidated risk register |

## Context

The organization's repositories are tools: each belongs to a series, ships
releases, and keeps its documentation as an en/ja mirror that `make check`
and `check-org.sh` enforce. ADR-019 carved out the first non-tool category —
deployment repositories, holding one operator's configuration and data — and
exempted it from series membership and from `check-org.sh`.

A review submission is a second kind of non-tool artifact. It is a document
written for a specific audience (a risk reviewer) at a specific time, about
several tools at once, in the language of the review. It has to be kept as
submitted, because the finding numbers in it are what the reviewers, the
follow-up commits and the release notes refer to. Every candidate home
failed a different test:

- A product repository's `docs/ja/` demands an English twin under the mirror
  check, and the document covers three repositories, so it belongs to none
  of them. The product docs' History tier is for superseded documents only.
- The `knowledge` repository holds reusable engineering knowledge by theme;
  the lessons this review produced already went there, but the review itself
  is a dated record, not a theme.
- `.github` holds conventions, this log, and setup guides, and is public.
- All organization repositories except the web site are public. Each fact in
  the submission comes from a public repository, but the submission
  consolidates residual risks and incident references across products into
  one register, which is not something to publish.

ADR-019's definition does not cover this case: a review record is not
"configuration and/or accumulated data for one operator's use of a tool",
and unlike deployment data it is an organizational record, so ownership
should not follow an individual.

## Decision

**1. Introduce "records repository" as a second category outside the series
taxonomy.** A repository is a records repository when all of the following
hold:

- it holds documents produced *about* the organization's tools for an
  external or internal review — submissions, their snapshots, and the status
  of the findings they produced;
- it contains no code that ships;
- it has no version, no release cycle, and no build.

**2. Records repositories are exempt from series membership and from the
mirror convention.** They join no umbrella, appear in no catalogue, and are
not inspected by `check-org.sh`. Submissions are written in the language of
the review — Japanese, for the reviews the organization currently faces —
and no English mirror is kept. CONVENTIONS.md §Starting a New Project item 6
gains the exception beside ADR-019's.

**3. Records repositories are organization-owned and private.** A submission
is an organizational act, so the repository is owned by the organization;
it is private because a submission is a consolidated risk register.

**4. A submitted snapshot is immutable.** One dated directory per submission,
holding the document as handed over (Markdown source, PDF and Word
snapshots) and a `README.ja.md` with the submission metadata, the revision
history, and the status of every finding with the release that carried each
fix. A revision is a new dated file or a new directory; the submitted files
are never rewritten. Finding status is recorded in that README, not by
editing the document.

**5. §Security applies unchanged.** No secrets, PII, infrastructure
identifiers or absolute local paths — a document assembled in an agent
session can carry all four, so it is checked before it is added.

**6. The distinguishing test is what it ships.** As in ADR-019 decision 5: a
repository that grows a build, a release, or code that others consume has
become a project and takes the full checklist and a series.

First instance: `nlink-jp/security-reviews`, holding the 2026-09-12
gem-agent / lagent architecture and security-layer review.

## Consequences

- A second category the organization tooling deliberately does not see.
  `check-org.sh` gains no check, for the same reason as ADR-019: enumerating
  the category would need a registry, and there is nothing to verify in a
  repository with no build and no mirror.
- The finding numbers in a submission stay stable, because the file they
  live in is never rewritten. Follow-up commits and release notes can cite
  them.
- The en/ja convention gains its first explicit exemption for a whole
  repository. The exemption is bounded by decision 1: it applies to review
  records, not to documentation of a tool.
- The failure mode this admits is a document that should be product
  documentation being filed as a record to escape the mirror. Decision 1 is
  the guard: a record is about a submission at a point in time; if a document
  describes how a tool currently behaves, it belongs in that tool's `docs/`.

## Alternatives considered

| Alternative | Why not |
|---|---|
| File the submission under the primary product's `docs/ja/history/` | The mirror check demands an English twin; the document spans three repositories; History is for superseded documents |
| Extend ADR-019's deployment-repository category to cover records | A review record is not one operator's tool data, and its ownership is organizational, not individual — the two categories differ on exactly the axis ADR-019 decision 3 fixed |
| Keep the submission only as a released asset (a PDF attached to a release) | Products release code, not reviews; the Markdown source, the revision history and the finding status need version control, which release assets do not give |
| Store it in the maintainers' personal knowledge vault | Not version-controlled by the organization; a submission is an organizational record |

## References

- [ADR-017](017-adr-authoring-conventions.md) — ADR authoring conventions and the `Binds` field
- [ADR-019](019-deployment-repositories.md) — deployment repositories, the first non-tool category and the exemption this record parallels
- CONVENTIONS.md §Starting a New Project item 6 — series placement and its exceptions; §Security — what must never be committed
- `nlink-jp/security-reviews` — the first records repository (private)
