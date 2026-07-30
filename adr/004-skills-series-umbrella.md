# ADR-004: skills-series Umbrella Restructure — One Repository per Skill, Released as Skill Zips

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-07-31 |
| Decision makers | nlink-jp maintainers |
| Triggered by | skills-series being the only series shaped as a monorepo, and its `make install` distribution serving Claude Code only |

## Context

Every other series in the organization is an **umbrella repository of
submodules** — one repository per tool, each with its own version tags,
CHANGELOG, GitHub Releases, and catalog entry. `skills-series` alone is a
monorepo: two skills (`rfp`, `mcp-tactics`) share one version line, and the
only installation path is `git clone` + `make install`, which copies the
skill directories into `~/.claude/skills/`.

Two properties of the current shape now chafe:

1. **Distribution reach.** The skill content already conforms to the standard
   Agent Skills format (a directory whose root holds `SKILL.md`). The portable
   unit of that format is *a zip whose root is the skill folder* — the exact
   artifact claude.ai, Claude Desktop, and mobile accept under
   Settings → Skills. `make install` reaches none of those surfaces and
   requires git; a Release asset reaches all of them and requires a browser.
2. **Process mismatch.** The org release checklist, submodule-pointer
   updates, `check-org.sh`, and the catalog surfaces all assume
   *repository = tool*. A skill that needs a fix today drags the whole
   series version with it, and the series is invisible to the per-repo
   machinery every other artifact type enjoys.

## Decision

**Split each skill into its own repository, convert `skills-series` into an
umbrella of submodules, and distribute each skill as a GitHub Release zip
whose root is the skill folder.**

Three sub-decisions define the shape.

### 1. Repository = skill, named after the skill

`nlink-jp/rfp` and `nlink-jp/mcp-tactics`, matching the org convention that
the repository carries the tool's name. Skill invocation names
(`/rfp`, `/mcp-tactics`) are unchanged — they come from the skill directory
name, not the repository name.

### 2. Skill content lives in a `<skill-name>/` subdirectory

```
rfp/                      ← repository
├── rfp/                  ← the skill (the only thing that ships)
│   └── SKILL.md
├── tests/validate-skill.sh
├── Makefile              install / uninstall / check / test / package
├── README.md, README.ja.md, CHANGELOG.md, AGENTS.md, CLAUDE.md, LICENSE
└── .gitignore            (dist/)
```

The subdirectory is the distribution boundary: `make package` zips exactly
that directory (producing `dist/<skill>-vX.Y.Z.zip` with `<skill>/` at the
zip root) and `make install` copies exactly that directory. Repo scaffolding
(READMEs, Makefile, tests) can never leak into the artifact, and no exclude
list has to be maintained — the alternative, `SKILL.md` at the repository
root, would require one.

Unlike binary releases, the zip does **not** bundle `README.md`: the Agent
Skills zip layout admits only the skill folder at its root, and extra
top-level entries risk breaking the claude.ai upload path.

### 3. GitHub Release zip is the distribution channel — not a marketplace

Skills release exactly like binaries: tag → `gh release create` → upload
`dist/*.zip`. Consumers either unzip into `~/.claude/skills/` /
`.claude/skills/`, or upload the zip as-is to claude.ai. A plugin
marketplace (`.claude-plugin/marketplace.json`) is deliberately **not**
adopted: it would prefix the invocation names (`/skills-series:rfp`), adds
infrastructure for an audience of effectively one org, and the Release asset
already serves every surface we target. `make install` remains as the
developer's local-iteration path, unchanged.

## Consequences

- Each skill gains independent versioning, CHANGELOG, and Releases; the
  existing release checklist applies verbatim (with `make package` producing
  skill zips instead of binaries).
- `skills-series` becomes a pure catalog: submodules + README, no Makefile,
  no tests. Its monorepo history stays in place; the split repositories
  start fresh at v0.1.0.
- `tests/validate-skills.sh` is copied into each skill repository (adapted
  to validate a single skill). Two copies of a 70-line structural validator
  is accepted drift risk; if a third skill appears, hoisting it into
  `.github/scripts/` becomes worthwhile.
- Per-skill repos carry the full documentation set (README ×2, CHANGELOG,
  AGENTS.md, LICENSE) — the same per-repo overhead every other series
  already pays.
- The pre-release archive check gains a skills-specific form: unzip the
  artifact and verify the zip root is the skill folder with `SKILL.md`
  directly inside it.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Keep the monorepo, add `make package` only | Fixes distribution but leaves the process mismatch: shared version line, no per-skill Releases, still the org's one structural exception |
| Plugin marketplace | Changes invocation names to `/skills-series:<name>`, adds a manifest layer, and targets a discovery problem a single-maintainer org does not have |
| `npx skills add` as the primary channel | Works from the repo layout for Claude Code, but ships whatever is on `main` (no version pinning) and does not serve the claude.ai upload path |
| `SKILL.md` at repository root | Packaging and install would need an exclude list for repo scaffolding; the subdirectory makes the distribution boundary structural |

## References

- [CONVENTIONS.md](../CONVENTIONS.md) — release process, Starting a New Project
- [ADR-003](003-mcp-tactics-skill.md) — the `mcp-tactics` skill this restructure carries over
- [skills-series](https://github.com/nlink-jp/skills-series) — the umbrella
- [Claude Help Center — How to create custom skills](https://support.claude.com/en/articles/12512198-how-to-create-custom-skills) — the zip layout accepted by claude.ai
