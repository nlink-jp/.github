# ADR-005: Umbrella Repository Standardization — One File Set, One Catalog Surface, Enforced

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-07-31 |
| Decision makers | nlink-jp maintainers |
| Triggered by | ADR-004 making skills-series the 8th umbrella and exposing that no two umbrellas carry the same file set |

## Context

The organization now runs **8 umbrella repositories** (cli, chatops,
cybersecurity, lab, lib, lite, skills, util). A survey (2026-07-31) found
three kinds of divergence:

1. **File set.** Five umbrellas carry `README.md` + `CLAUDE.md` only;
   cli-series adds a series `CONVENTIONS.md`; lite-series adds
   `AGENTS.md` + `CONVENTIONS.md` + `docs/`; skills-series (post-ADR-004)
   carries `AGENTS.md`. No umbrella's file set was wrong on purpose — there
   was simply nothing written down to converge on.
2. **Catalog drift.** lite-series' README still lists `lite-eml` and
   `lite-msg`, which were renamed and moved to util-series
   (`eml-to-jsonl`, `msg-to-jsonl`), and does not mark the archived
   `lite-llm`. Its AGENTS.md is worse: missing `lite-switch`, and showing
   an SSH clone URL despite the org's HTTPS-only submodule rule.
3. **No enforcement.** `check-org.sh` verifies CLAUDE.md presence and
   submodule pointers, but nothing ties the README catalog to the actual
   submodule list — which is exactly the check that would have caught (2).

## Decision

**Define one standard umbrella file set, keep the catalog in exactly one
file, and make `check-org.sh` enforce both.**

### 1. Required files

| File | Role |
|------|------|
| `README.md` | **The catalog** — one row per submodule (name linked to its repository + one-line description). Rows for former members are allowed only when explicitly labeled (moved / renamed / graduated). |
| `CLAUDE.md` | Org-rules header (mandatory CONVENTIONS.md link) + series-specific rules |
| `AGENTS.md` | Umbrella *workflow* only: clone/update/pointer-bump commands and gotchas. **Never a second catalog** — it links to README.md instead of repeating it. |
| `.gitignore` | `.claude/settings.local.json` exclusion (already enforced) |

### 2. Optional series extensions

`CONVENTIONS.md` (series-level rules, as in cli-series and lite-series) and
`docs/` (series-level documents, as in lite-series) remain legitimate
extensions per the org CONVENTIONS preamble.

### 3. Excluded files

`README.ja.md`, `CHANGELOG.md`, `LICENSE`, `Makefile`, `tests/` belong to
tool repositories, not umbrellas. An umbrella is a pointer catalog: it has
no behaviour to version, license, or test. (Japanese catalog surfaces
already exist: `nlink-web-site/index.ja.html` and each tool's README.ja.md.)
Existing umbrella tags/releases — skills-series' monorepo era — stay as
history; umbrellas simply stop minting new ones.

### 4. Enforcement in check-org.sh

Three new per-series checks:

- `README.md` and `AGENTS.md` present (CLAUDE.md was already checked)
- every submodule path appears as a `github.com/nlink-jp/<name>` link in
  `README.md`
- every `.gitmodules` URL is HTTPS

## Consequences

- Six umbrellas gain an AGENTS.md; lite-series' stale README rows and SSH
  URL get fixed in the same sweep; skills-series' AGENTS.md drops its
  two-row catalog table (README owns the catalog).
- The forward direction of catalog drift (a submodule invisible in the
  README) becomes machine-checked org-wide. The reverse direction (a README
  row whose submodule is gone) stays a judgment call — legitimate
  moved/graduated annotations exist — so it is a review item, not a check.
- A new umbrella (per ADR-004's _wip workflow) has an unambiguous scaffold
  to copy.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Full doc set on umbrellas (README.ja, CHANGELOG, LICENSE) | Catalog prose duplicated across two languages rots — the exact drift lite-series demonstrated; ja readers are served by nlink-web-site and per-tool READMEs |
| AGENTS.md carries a submodule table | A second catalog in the same repo; the two-surface drift lesson (profile README vs web site) applied at repo scale |
| Do nothing / align lazily | The survey already found real drift (lite-series) and an SSH URL; without a written standard the 9th umbrella diverges again |
| Enforce catalog in both directions | Reverse direction has legitimate exceptions (moved/renamed/graduated rows); a check would either forbid those or need an annotation grammar — not worth it at this scale |

## References

- [CONVENTIONS.md](../CONVENTIONS.md) — Umbrella repositories section (added by this ADR)
- [ADR-004](004-skills-series-umbrella.md) — the restructure that made the divergence visible
- [check-org.sh](../scripts/check-org.sh) — enforcement
