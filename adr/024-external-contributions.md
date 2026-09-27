# ADR-024: External contributions — issues first, and accepted changes are re-implemented, not merged

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-09-27 |
| Binds | organization |
| Decision makers | nlink-jp maintainers |
| Triggered by | A third outside pull request in five months arriving in a shape the organization could not merge — and the observation that nothing told contributors what shape would work |

## Context

Three pull requests have come from outside the organization so far. Each was
made in good faith, and each hit a rule the contributor had no way to know:

| Pull request | What it did | What it could not have known |
|---|---|---|
| csv-editor #1 (2026-05) | A Linux port, a cell-editor UI change and three hardening fixes in one PR, with an AI agent's planning files (`.kilo/plans/`) committed | One change per PR; agent working files do not belong in a repository |
| splunk-cli #3 (2026-05) | Release builds automated with GitHub Actions | Releases are built, signed and notarized on the maintainer's machine by design: signing keys stay in a local keychain, and macOS runners are billed at a multiple of Linux ones |
| instant-translate #1 (2026-09) | Six independent changes in one PR, with no tests and no documentation | One change per PR; tests and both READMEs are part of a change |

All three were closed. The valuable parts — three hardening fixes and a
Windows bug report (csv-editor), a font-size setting, a way to remove the
hotkey and a cramped-layout report (instant-translate) — were re-implemented
by the maintainers and shipped with credit. That is the practice already:
the organization does not take community-written code into its releases
(supply-chain policy, applied to dependencies and tools alike), and every
line it ships is written or rewritten to its own conventions, with tests,
bilingual documentation and a signed, notarized release.

None of this was written anywhere a contributor would look. The organization
has no `CONTRIBUTING.md`; the two repositories that have one (shell-agent-v2,
scat) describe building the tool, not contributing to it. `CONVENTIONS.md`
states the local signing flow but not "no CI", and states nothing about
third-party code.

## Decision

### 1. Issues first

Bug reports and feature ideas go to an issue before any code. A bug report
names the macOS (or OS) version, the tool's version and the steps. A feature
is discussed in the issue first — what problem it solves, not just what to
add.

### 2. Pull requests are welcome as proposals; accepted changes are re-implemented

Maintainers generally do not merge an outside pull request as-is. A pull
request is read as a precise proposal: when the change is wanted, the
maintainers write it themselves — to the repository's conventions, with
tests and documentation — and credit the contributor in the commit message
and the changelog. This is stated up front so that nobody spends effort
expecting a merge the policy rules out.

### 3. What a pull request should look like when one is sent

- One change per pull request, linked to its issue.
- Tests for new behaviour, and `README.md` and `README.ja.md` updated together.
- The repository's whole test suite run before sending (usually `make test`),
  with every test passing — not only the new ones.
- A note in the pull request on how it was checked: OS and version, the
  settings and inputs tried, and what was not tried — beyond the contributor's
  own everyday use.
- No AI-agent working files (`.claude/`, `.kilo/`, `.cursor/`, plans, notes).
  Changes prepared with AI tools are fine; review them yourself first.
- No CI workflows (`.github/workflows/`): releases are built, signed and
  notarized locally.
- No new third-party dependencies: the standard library, the platform's
  first-party SDKs, or a service's REST API directly.

### 4. Where it lives

As the organization's default community health files in `nlink-jp/.github`:
`CONTRIBUTING.md` (English, linking to `CONTRIBUTING.ja.md`) and
`PULL_REQUEST_TEMPLATE.md`. GitHub shows them for every repository that has
none of its own (GitHub documentation: *Creating a default community health
file*; the `.github` repository must be public, which it is). Repositories
with their own `CONTRIBUTING.md` link to the organization's policy for
contributions.

The last two items were added on 2026-09-27, after a close reading of
instant-translate #1: its existing tests did not compile against its own
change, so the suite had never been run, and its language filter broke
detection for any language outside the two the contributor used (IDs such as
`zh` and `en-GB` that the recognizer does not know silently match nothing —
measured).

## Consequences

- A contributor sees the policy on the "contribute" link and in the pull
  request form, before writing code.
- The two practices that were only the maintainers' habit — no CI, no
  community code — are now stated publicly, in the contribution guide.
- Fewer pull requests may be sent. That is acceptable: the issues that carry
  the same information are what the organization acts on.
- Every repository with its own `CONTRIBUTING.md` must keep its link to the
  organization policy; a new one written later must add it.

## Alternatives considered

**A. A `CONTRIBUTING.md` in every repository.** A copy in each repository,
and the copies would drift. The organization default reaches every repository without one,
including ones created later.

**B. Leave "re-implemented, not merged" unsaid and decide case by case.**
That is what happened three times: contributors did the whole job, then
learned it could not be merged. Stating it costs some pull requests and
saves contributors' effort.

**C. Review and merge outside pull requests.** Rejected by the supply-chain
policy: what ships is written or rewritten by the maintainers, and releases
are signed with keys only they hold.

**D. Discourage pull requests altogether.** A pull request is often the
clearest description of a proposal; it is welcome as that.

## References

- GitHub documentation — *Creating a default community health file*
- `CONVENTIONS.md` §Code Signing and Notarization (local signing and
  notarization)
- The three pull requests: nlink-jp/csv-editor#1, nlink-jp/splunk-cli#3,
  nlink-jp/instant-translate#1
