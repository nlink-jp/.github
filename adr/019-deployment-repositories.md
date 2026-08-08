# ADR-019: Deployment Repositories Are Not Series Members

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-08-08 |
| Binds | organization |
| Decision makers | nlink-jp maintainers |
| Triggered by | `news-digest` ([news-digest ADR-0001](https://github.com/nlink-jp/news-digest/blob/main/docs/en/adr/0001-public-engine-private-corpus.md)) splitting a public engine from a private corpus, producing a repository that holds only one operator's configuration and accumulated data |

## Context

CONVENTIONS.md §Starting a New Project requires that "every project must
belong to exactly one series", and the umbrella repositories plus
`check-org.sh` enforce that membership. The taxonomy has served every
repository built so far, because every repository so far has been a tool: it
builds something, it has a version, it is released, and it is public.

`news-digest` produces a repository that is none of those things. Its corpus
repository holds a feed list, a relevance profile, noise-filter rules, the
collected article records, and the generated digests. It has no build, no
tests of its own, no version, and no release cycle. Its contents are private
by necessity — a relevance profile names the operator's line of business and
its customers' products, and the corpus itself records what that operator is
watching.

Forcing it into the taxonomy has no good outcome. Adding it to a public
umbrella as a submodule either exposes private data or lists a private
member from a public catalogue. Applying the project checklist demands a
release cycle, a `CHANGELOG.md`, and README pairs for something that ships
nothing. And organization ownership would move one person's subscriptions
and reading history onto the organization account.

This is not specific to `news-digest`. Any tool that separates a public
engine from private operational data produces the same artifact, and the
separation is exactly what makes such a tool publishable at all. The
category needs to exist before the second instance arrives, rather than
being improvised again.

## Decision

**1. Introduce "deployment repository" as a category outside the series
taxonomy.** A repository is a deployment repository when all of the
following hold:

- it holds configuration and/or accumulated data for one operator's use of a
  tool that lives elsewhere;
- it contains no code that ships;
- it has no version, no release cycle, and no build.

**2. Deployment repositories are exempt from series membership.** They join
no umbrella, appear in no catalogue, and are not inspected by
`check-org.sh`. CONVENTIONS.md §Starting a New Project item 6 gains the
exception and a pointer to this record.

**3. Ownership follows the data, not the tool.** A deployment repository may
be owned by an individual rather than by the organization, and is private by
default. The tool being public says nothing about who owns the corpus.

**4. The contract lives in the tool's repository.** The tool documents the
file the deployment repository must provide (declaring schema and config
versions, paths, and destinations), ships sanitized examples, and refuses to
run against a version it does not support. The deployment repository carries
no copy of the tool's code.

**5. The distinguishing test is what it ships.** A repository that ships
nothing and has no version is a deployment repository. If it grows a
`Makefile`, a release, or code that others consume, it has become a project
and takes the full checklist and a series.

## Consequences

- A category of repository that organization tooling deliberately does not
  see. `check-org.sh` gains no check: there is nothing to verify in a
  repository that is in no umbrella, and a checker that enumerated
  deployment repositories would need a registry that is itself unowned.
- The failure mode this admits is a real project mislabeled to skip the
  checklist. Decision 5 is the guard, and it is observable: a project has
  build output and a version, a deployment repository has neither.
- Private operational data stays out of public umbrellas without anyone
  having to make an exception case-by-case.
- First instance: the corpus repository for `news-digest` — individually
  owned and private, per decision 3.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Add a `data-series` umbrella | The umbrella would be public and would list private members owned by individuals; umbrella standardization (ADR-005) also expects a catalogue and per-member release cycles that do not exist here |
| Place it in `lab-series` | lab-series is for experimental *tools* under active development. This has no code, and it is not experimental — it is the steady state |
| Keep configuration and data inside the tool repository | Precisely what [news-digest ADR-0001](https://github.com/nlink-jp/news-digest/blob/main/docs/en/adr/0001-public-engine-private-corpus.md) exists to undo. It is what made the predecessor unpublishable |
| Require organization ownership of deployment repositories | The data belongs to whoever operates the tool. Forcing organization ownership puts an individual's subscriptions and reading history on the organization account, and would make personal use of an organization tool an organizational act |
| Say nothing and handle it ad hoc | ADR-017 documents what improvisation costs in this log: the first unrecorded judgment becomes the template the next eight imitate |

## References

- [ADR-004](004-skills-series-umbrella.md) — skills-series umbrella, one repository per skill
- [ADR-005](005-umbrella-standardization.md) — umbrella standardization and the catalogue rule this category is exempt from
- [ADR-017](017-adr-authoring-conventions.md) — ADR authoring conventions and the `Binds` field
- [news-digest ADR-0001](https://github.com/nlink-jp/news-digest/blob/main/docs/en/adr/0001-public-engine-private-corpus.md) — the design that triggered this record
- CONVENTIONS.md §Starting a New Project — item 6 (series placement) and its exception
