# ADR-006: Skill Validator Vendoring — Copy-Maintained, with an Enforced Canonical Template

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-07-31 |
| Decision makers | nlink-jp maintainers |
| Triggered by | `meeting-notes` becoming the third skill repository — the trigger ADR-004 set for revisiting the per-repo copies of `tests/validate-skill.sh` |

## Context

ADR-004 split skills-series into one repository per skill, each carrying its
own copy of `tests/validate-skill.sh` (the structural validator that `make
check` and `make package` run). Its Consequences section accepted two copies
as drift risk and said that *"if a third skill appears, hoisting it into
`.github/scripts/` becomes worthwhile."*

The third skill (`meeting-notes`) has appeared. Before deciding, the three
copies were diffed: they are **byte-identical** — no drift has occurred. The
validator is fully generic (it discovers `SKILL.md` directories with `find`
and carries no per-skill configuration), which is why the copies never
needed to diverge. `meeting-notes` also demonstrated the extension pattern:
its repo-specific Python script tests hang off the Makefile `check` target
(`python3 tests/run-script-tests.py`) *next to* the shared validator, not
inside it.

Hoisting turns out to conflict with a structural property the org relies on:
**each skill repository is a standalone public repository** (submodules are
just how the umbrella catalogs them). A Makefile that resolves the validator
via `../../.github/scripts/` only works inside this workspace's checkout
layout; from a fresh standalone clone, `make check` — and therefore `make
package`, which depends on it — would break. Fetching the script over the
network at check time trades that for a network dependency and a mutable
source.

Meanwhile the org already solved this exact problem once: Homebrew
tap-generation assets are **vendored per repo** with a canonical copy in
`.github/templates/`, and `check-org.sh` (check 10) fails when a vendored
copy drifts from the canonical.

## Decision

**Keep the per-repo copies, add a canonical template, and enforce
byte-equality — the same vendoring pattern as the tap-generation assets.**

1. The canonical validator lives at `.github/templates/validate-skill.sh`
   (in `templates/`, the established home for vendored canonicals — not
   `scripts/`, which holds org-level executables).
2. Every skill repository keeps its own copy at `tests/validate-skill.sh`,
   byte-identical to the canonical. The copy's header states where the
   canonical lives.
3. `check-org.sh` gains check **10b**: for every submodule that has
   `tests/validate-skill.sh`, `cmp` it against the canonical and fail on any
   difference. Silent drift — the only real weakness of copies — becomes a
   loud org-check failure.
4. To change the validator: edit the canonical, re-vendor into every skill
   repo, and commit each repo (check 10b goes red until all copies match).
5. Repo-specific tests are composed in the Makefile `check` target, never by
   editing the vendored validator.

## Consequences

- Standalone clones of any skill repo remain self-contained: `make check`,
  `make package`, and release verification work without the workspace.
- A validator change now costs one commit per skill repo plus umbrella
  pointer bumps. Accepted: the script is 70 lines, generic, and stable —
  the three copies went months without needing a single divergent change.
- ADR-004's "hoist into `.github/scripts/` at the third skill" consequence
  is superseded by this ADR.
- New skill repos vendor the canonical at scaffold time (see CONVENTIONS.md
  → Skill project scaffold).

## Alternatives considered

| Alternative | Why not |
|---|---|
| Hoist into `.github/scripts/`, reference by relative path (ADR-004's sketch) | Assumes the workspace checkout layout; `make check` and `make package` break in a standalone clone of the skill repo |
| Fetch the canonical from raw.githubusercontent.com at check time | Adds a network dependency to an offline check and makes the validator a mutable remote input |
| Keep copies with no canonical and no check | The status quo's weakness: nothing detects the fourth or fifth copy drifting silently |
| git submodule / subtree for a shared `tests/` | Heavyweight machinery for one 70-line file; submodules-in-submodules complicate every clone |

## References

- [ADR-004](004-skills-series-umbrella.md) — the restructure whose Consequences this ADR supersedes in part
- [ADR-002](002-homebrew-tap-automation.md) — the tap-asset vendoring pattern this ADR reuses
- [CONVENTIONS.md](../CONVENTIONS.md) — Skill project scaffold, `check-org.sh` check table
