# nlink-jp Organization Conventions

This document defines the development policies and conventions shared across all
repositories in the [nlink-jp](https://github.com/nlink-jp) organization.

Every project must follow these conventions from the start.
Series-level and project-level `CONVENTIONS.md` / `CLAUDE.md` files may extend
these rules but must not contradict them.

## Architecture Decision Records (ADR)

Organization-wide technical decisions are recorded in [`adr/`](adr/).
Non-trivial design decisions and bug-fix strategies are written up as an ADR
(or a project-level design note) and approved **before** implementation starts —
not documented after the fact.

**Which log a record belongs in** (ADR-017) is decided by what it binds, not
by how substantial it is. Ask in order:

1. **Does it change how other projects are built, shipped, or documented** —
   a shared convention, a policy, a series restructure? → this log
   (`adr/NNN-slug.md`, three-digit).
2. **Is it the retirement of a tool in favour of another, or a move of
   responsibility between repositories?** That *fact* is organization-level;
   if the fact is all the record decides, it goes here.
3. **Everything else — including how a successor tool is designed** — goes in
   the project's own log (`docs/{en,ja}/adr/NNNN-slug.md`, four-digit
   numbered per project, mirrored in both languages). A hybrid record that
   both retires a tool and designs its successor keeps the design payload in
   the successor's log; the retirement stays visible here, in the index row
   and the redirect.

Both misplacement patterns have actually happened (nine records, moved out
on 2026-08-03): zip-porter's four internal design records (012–014, 016)
each bound one app, and five skill-design records (007–011) each bound one
skill, the organization-level retirement fact fitting in one index-row
clause. Each followed the record before it — **imitating an existing ADR is
not checking this section.**

Every new record in either log opens with this header table (ADR-017). The
**Binds** field forces the placement question at authoring time: a record in
`adr/` must say `organization`, a record in a project log must name that
project, and a mismatch is visible at a glance. Existing records are not
retrofitted.

```markdown
# ADR-NNN: <title>

| Field | Value |
|-------|-------|
| Status | Proposed / **Accepted** / Superseded / Moved |
| Date | YYYY-MM-DD |
| Binds | organization — or the project name, in a project log |
| Decision makers | nlink-jp maintainers |
| Triggered by | <what forces the decision now> |
```

Body sections: `Context`, `Decision`, `Consequences`, `Alternatives
considered`, `References` — write Alternatives even when the choice looks
obvious.

Numbers are never reused in either log: a decision that moves leaves a
redirect behind, because release notes and changelogs already link to it.

| ADR | Status | Summary |
|-----|--------|---------|
| [001](adr/001-gemini3-migration.md) | Accepted | Gemini 2.5 → 3 migration plan (defer until GA) |
| [002](adr/002-homebrew-tap-automation.md) | Accepted | Homebrew tap distribution — install notarized release assets, generate formula/cask at release time |
| [003](adr/003-mcp-tactics-skill.md) | Accepted | `mcp-tactics` Skill — cross-cutting selection layer for our MCP servers (selection/ordering only; `get_usage` owns parameters) |
| [004](adr/004-skills-series-umbrella.md) | Accepted | skills-series umbrella restructure — one repository per skill, released as GitHub Release skill zips |
| [005](adr/005-umbrella-standardization.md) | Accepted | Umbrella standardization — one file set (README/CLAUDE/AGENTS/.gitignore), README as the only catalog, enforced by check-org.sh |
| [006](adr/006-skill-validator-vendoring.md) | Accepted | Skill validator vendoring — per-repo copies of `validate-skill.sh` with a canonical in `.github/templates/`, byte-equality enforced by check-org.sh |
| [007](adr/007-service-research-skill.md) | Moved | `service-research` skill design — **moved** to [`service-research` ADR-0001](https://github.com/nlink-jp/service-research/blob/main/docs/en/adr/0001-agentic-research.md) (project-scoped; retires the `product-research` CLI) |
| [008](adr/008-incident-research-skill.md) | Moved | `incident-research` skill design — **moved** to [`incident-research` ADR-0001](https://github.com/nlink-jp/incident-research/blob/main/docs/en/adr/0001-deep-dive-research.md) (project-scoped) |
| [009](adr/009-incident-review-skill.md) | Moved | `incident-review` skill design — **moved** to [`incident-review` ADR-0001](https://github.com/nlink-jp/incident-review/blob/main/docs/en/adr/0001-retrospective-analysis.md) (project-scoped; retires the `ai-ir` / `ai-ir2` CLIs) |
| [010](adr/010-incident-research-ioc-stix.md) | Moved | `incident-research` v0.2 IoC/STIX design — **moved** to [`incident-research` ADR-0002](https://github.com/nlink-jp/incident-research/blob/main/docs/en/adr/0002-ioc-stix-output.md) (project-scoped; retires the `ioc-collector` CLI) |
| [011](adr/011-compliance-review-skill.md) | Moved | `compliance-review` skill design — **moved** to [`compliance-review` ADR-0001](https://github.com/nlink-jp/compliance-review/blob/main/docs/en/adr/0001-two-phase-review.md) (project-scoped; retires the `virtual-reviewer` PoC) |
| [012](adr/012-zip-porter-hardening.md) | Moved | `zip-porter` extraction hardening — **moved** to [`zip-porter` ADR-0001](https://github.com/nlink-jp/zip-porter/blob/main/docs/en/adr/0001-extraction-hardening.md) (project-scoped) |
| [013](adr/013-zip-porter-parallel-compression.md) | Moved | `zip-porter` compression throughput — **moved** to [`zip-porter` ADR-0002](https://github.com/nlink-jp/zip-porter/blob/main/docs/en/adr/0002-parallel-compression.md) (project-scoped) |
| [014](adr/014-zip-porter-zlib-parallel-deflate.md) | Moved | `zip-porter` single-file parallel deflate — **moved** to [`zip-porter` ADR-0003](https://github.com/nlink-jp/zip-porter/blob/main/docs/en/adr/0003-zlib-parallel-deflate.md) (project-scoped) |
| [015](adr/015-knowledge-repository.md) | Accepted | `knowledge` repository — org engineering knowledge base compiled from agent memory (themed bilingual docs); consult-and-feed loop added to Development Policy |
| [016](adr/016-zip-porter-batch-completion.md) | Moved | `zip-porter` batch completion reporting — **moved** to [`zip-porter` ADR-0004](https://github.com/nlink-jp/zip-porter/blob/main/docs/en/adr/0004-batch-completion.md) (project-scoped) |
| [017](adr/017-adr-authoring-conventions.md) | Accepted | ADR authoring conventions — mandatory `Binds` header field, placement decision tree with the real misplacement counterexamples, lesson fed to `knowledge` |

---

## Starting a New Project

A new project must go through three phases before writing production code:
**Plan → Scaffold → Develop**. Skipping the planning phase leads to rework,
inconsistent structure, and integration issues that are expensive to fix later.

### Phase 1: Planning

Before any code is written, produce and get sign-off on the following:

1. **Problem statement** — What problem does this tool solve? Who is the user?
   One paragraph is enough. If the scope cannot be explained concisely, it is
   too broad.

2. **Functional specification** — Define the tool's interface:
   - Commands and flags (CLI tools) or API surface (libraries)
   - Input/output formats (stdin/stdout, files, JSON schema)
   - Configuration method (config file, env vars, flags)
   - External dependencies (APIs, services, credentials)

3. **Design decisions** — Document non-obvious choices:
   - Why this language/framework?
   - What existing tools does it complement? (e.g. swrite works with stail and slack-router)
   - What is explicitly out of scope?

4. **Development plan** — Break the work into phases with milestones:
   - Phase 1: core functionality + tests
   - Phase 2: additional features
   - Phase 3: documentation, polish, release
   - Identify which phases can be reviewed independently.

5. **Required API scopes / permissions** — For tools that integrate with
   external services (Slack, Splunk, Google Cloud, etc.), enumerate all required
   OAuth scopes, API permissions, or IAM roles **at design time**. Discovering
   a missing scope at runtime is a preventable error.

6. **Series placement** — Decide which umbrella series the project belongs to.
   Every project must belong to exactly one series:

   | Series | Scope |
   |--------|-------|
   | cli-series | Interactive CLI clients for external services (user-authenticated) |
   | chatops-series | Slack ChatOps automation and monitoring tools (bot-authenticated) |
   | cybersecurity-series | AI-augmented security tools (threat intel, IR, risk assessment) |
   | lab-series | Experimental projects under active development |
   | lib-series | Shared libraries consumed by tools in other series |
   | lite-series | Local-first LLM interaction and pipeline tools |
   | skills-series | Claude Code Skills for development process automation (ADR-004 layout) |
   | util-series | Pipe-friendly data transformation and processing CLIs |

   If none of the existing series is a good fit, discuss whether a new series
   is warranted before creating one.

7. **External platform constraints** — If the tool integrates with external
   platforms (Slack, AWS, GCP, etc.), investigate their API limitations,
   rate limits, and UI rendering constraints **before** implementing.
   Discovering a platform limitation during development leads to rework.

The planning artifacts can be lightweight (a GitHub issue, a markdown file in
`docs/design/`, or a conversation summary) — the format matters less than the
content.

### Phase 2: Scaffolding

Create the repository with the correct structure **before** writing business
logic. This ensures org conventions are embedded from the start, not patched
in later.

#### Working directory: `_wip/`

New projects must be developed in the organization root `_wip/` directory,
**not** directly inside an umbrella series directory.

```
nlink-jp/                    ← organization root (workspace)
├── _wip/
│   └── <tool-name>/         ← develop here until ready for integration
├── util-series/
├── cli-series/
└── ...
```

**Why:** Adding a submodule to an umbrella repo requires the target path to be
empty. If you develop directly inside `util-series/<tool-name>/`, you must
`rm -rf` the working copy before running `git submodule add` — risking loss of
uncommitted work. Developing in `_wip/` eliminates this dangerous step entirely.

**Workflow:**

1. Create the project directory under `_wip/`:
   ```bash
   mkdir -p _wip/<tool-name>
   cd _wip/<tool-name>
   git init
   ```
2. Scaffold and develop following the conventions below.
3. When the project is ready for integration, create the remote repository and
   push:
   ```bash
   gh repo create nlink-jp/<tool-name> --public --source=. --push
   gh api -X PUT /repos/nlink-jp/<tool-name>/subscription -F subscribed=true
   ```
   The explicit watch is required: GitHub sunset automatic watching in
   May 2025, so a newly created repository is otherwise never watched and
   external issues/PRs would arrive silently.
4. Add the project as a submodule in the appropriate umbrella repo:
   ```bash
   cd <umbrella-series>/
   git submodule add https://github.com/nlink-jp/<tool-name>.git
   git commit -m "chore: add <tool-name> submodule"
   git push
   ```
   This clones a fresh copy from the remote — no file conflicts.
5. Remove the `_wip/` working copy after confirming the submodule works:
   ```bash
   rm -rf _wip/<tool-name>
   ```

> **Rule:** Never develop new projects directly inside an umbrella series
> directory. Always use `_wip/` as the staging area.

#### Go project scaffold

```
<tool-name>/
├── main.go                  ← package main, calls cmd.Execute()
├── cmd/
│   └── root.go              ← cobra root command
├── internal/                ← private packages
├── Makefile                 ← see template below
├── .gitignore               ← see template below
├── go.mod
├── docs/
│   ├── en/                  ← English docs (no language suffix)
│   └── ja/                  ← Japanese docs (*.ja.md suffix)
├── README.md
├── README.ja.md
├── CHANGELOG.md
├── LICENSE
├── CLAUDE.md                ← project-specific rules for AI agents
└── AGENTS.md                ← project summary, build commands, structure, gotchas
```

#### Python project scaffold (uv)

```
<tool-name>/
├── src/
│   └── <package_name>/      ← source package (underscore, not hyphen)
│       ├── __init__.py
│       └── ...
├── tests/                   ← pytest test directory
│   └── test_*.py
├── pyproject.toml           ← with [project.scripts] entry point
├── uv.lock
├── .python-version
├── Makefile                 ← see template below
├── .gitignore               ← see template below
├── docs/
│   ├── en/                  ← English docs (no language suffix)
│   └── ja/                  ← Japanese docs (*.ja.md suffix)
├── README.md
├── README.ja.md
├── CHANGELOG.md
├── LICENSE
├── CLAUDE.md
└── AGENTS.md
```

#### GUI app scaffold

For desktop `.app`-bundle projects (Wails, Tauri, Swift SPM), the
shape is framework-specific — Wails keeps its Go source under
`app/`, Tauri keeps the Rust crate under `src-tauri/`, Swift uses
`Package.swift` at the project root. What's **shared across all
three** is the signing wiring: a `scripts/` directory at the project
root holding the codesign and notarize scripts, and a `Makefile`
that calls them. See the dedicated
[**§Code Signing → Starting a new GUI app**](#starting-a-new-gui-app)
section below for the step-by-step scaffolding, including
framework-specific Makefile templates and reference projects.

#### Skill project scaffold (skills-series)

Skills follow ADR-004: **repository = skill**, with the skill content in a
`<skill-name>/` subdirectory that is the distribution boundary — `make
package` ships exactly that directory, so repo scaffolding can never leak
into the artifact.

```
<skill-name>/                ← repository (github.com/nlink-jp/<skill-name>)
├── <skill-name>/            ← the skill itself (the only thing that ships)
│   ├── SKILL.md             ← frontmatter `name:` must equal the directory
│   │                          name — the directory name is the slash command
│   └── ...                  ← references / scripts the skill instructs with
├── tests/
│   └── validate-skill.sh    ← vendored copy of .github/templates/ (ADR-006)
├── Makefile                 ← see template below
├── .gitignore               ← `dist/` and `.DS_Store` only
├── README.md
├── README.ja.md
├── CHANGELOG.md
├── LICENSE
├── CLAUDE.md
└── AGENTS.md
```

- `tests/validate-skill.sh` is a **vendored copy** of
  `.github/templates/validate-skill.sh`, kept **byte-identical** —
  `check-org.sh` (check 10b) fails on any drift. To change the validator,
  edit the canonical template and re-vendor into every skill repo. Never
  edit a repo's copy in place.
- Repo-specific tests (e.g. `meeting-notes` runs
  `python3 tests/run-script-tests.py` for its bundled scripts) are added as
  extra commands under the Makefile `check` target — the vendored validator
  stays untouched.
- Scaffold new skill repos from `rfp` as the reference shape (update every
  copied field — see the AGENTS.md rule in the Scaffold checklist).
- No `docs/` split and no binaries: the skill's own Markdown *is* the
  product; distribution is a GitHub Release zip whose root is the skill
  folder (see §Release Checklist).

#### Makefile template (Skill)

```makefile
SKILL   := <skill-name>
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
DEST    ?= $(HOME)/.claude/skills

.PHONY: install uninstall check test package clean

install:
	@mkdir -p "$(DEST)/$(SKILL)"
	@cp -R "$(SKILL)/." "$(DEST)/$(SKILL)/"
	@echo "installed: $(SKILL) -> $(DEST)/$(SKILL)"

uninstall:
	@rm -rf "$(DEST)/$(SKILL)"
	@echo "removed: $(DEST)/$(SKILL)"

check:
	@./tests/validate-skill.sh

test: check

# The zip root is the skill folder itself — the layout claude.ai accepts
# and the one that unzips cleanly into ~/.claude/skills/ (ADR-004).
package: check
	@rm -rf dist
	@mkdir -p dist
	@zip -qr "dist/$(SKILL)-$(VERSION).zip" "$(SKILL)" -x '*.DS_Store'
	@echo "packaged: dist/$(SKILL)-$(VERSION).zip"

clean:
	@rm -rf dist
```

Repo-specific tests are appended to the `check` recipe as extra lines
(e.g. `@python3 tests/run-script-tests.py`). If the skill bundles Python
scripts, also exclude `-x '*__pycache__*'` in the `package` recipe.

#### Makefile template (Go)

```makefile
BINARY  := <tool-name>
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
LDFLAGS := -ldflags "-X main.version=$(VERSION)"
DIST_DIR := dist

.PHONY: build build-all test clean

build:
	@mkdir -p $(DIST_DIR)
	go build $(LDFLAGS) -o $(DIST_DIR)/$(BINARY) .

build-all:
	@mkdir -p $(DIST_DIR)
	CGO_ENABLED=0 GOOS=linux   GOARCH=amd64 go build $(LDFLAGS) -o $(DIST_DIR)/$(BINARY)-linux-amd64   .
	CGO_ENABLED=0 GOOS=linux   GOARCH=arm64 go build $(LDFLAGS) -o $(DIST_DIR)/$(BINARY)-linux-arm64   .
	# darwin is arm64-only (no amd64, no universal — see §Release Archive Standard)
	CGO_ENABLED=0 GOOS=darwin  GOARCH=arm64 go build $(LDFLAGS) -o $(DIST_DIR)/$(BINARY)-darwin-arm64  .
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o $(DIST_DIR)/$(BINARY)-windows-amd64.exe .

test:
	go test ./...

clean:
	rm -rf $(DIST_DIR)
```

#### `.gitignore` template (Go)

```gitignore
# Build artifacts
dist/

# Go
*.test
*.out

# Credentials
.env

# macOS
.DS_Store

# Editor
.idea/
.vscode/
*.swp
*.swo
```

#### Makefile template (Python)

```makefile
.PHONY: test lint format build clean

test:
	uv run pytest tests/ -v

lint:
	uv run ruff check src/ tests/
	uv run ruff format --check src/ tests/

format:
	uv run ruff check --fix src/ tests/
	uv run ruff format src/ tests/

build:
	uv build --out-dir dist/

clean:
	rm -rf dist/ .pytest_cache .ruff_cache
```

#### `.gitignore` template (Python)

```gitignore
# Build artifacts
dist/

# Python
__pycache__/
*.py[cod]
*.pyo
*.egg-info/

# Virtual environment
.venv/

# Test / lint cache
.pytest_cache/
.ruff_cache/
.mypy_cache/
.coverage
htmlcov/

# Credentials
.env
.env.*

# Local deployment overrides
*.local.yaml
*.local.toml
*.local.json

# macOS
.DS_Store

# Editor
.idea/
.vscode/
*.swp
*.swo
```

#### Scaffold checklist

**Repository structure (Go):**

- [ ] `main.go` is at the project root (not `cmd/<name>/`)
- [ ] `Makefile` `build` target outputs to `dist/`
- [ ] `.gitignore` contains `dist/` and nothing else for build artifacts
- [ ] `go.mod` module path is `github.com/nlink-jp/<tool-name>`
- [ ] the CLI answers **`--version`** as well as any `version` subcommand, with
      identical output and a test pinning both (a Homebrew formula's `brew test`
      runs `--version` — see §Homebrew Tap Distribution)

**Repository structure (Python):**

- [ ] Source code is in `src/<package_name>/` layout
- [ ] `tests/` directory exists with at least one test file
- [ ] `Makefile` has `test`, `lint`, `build`, `clean` targets
- [ ] `pyproject.toml` has `[project.scripts]` entry point
- [ ] `.python-version` specifies the minimum Python version
- [ ] `.gitignore` contains `dist/` and standard Python exclusions

**Repository structure (GUI `.app` projects):**

- [ ] `scripts/codesign-darwin-app.sh` and `scripts/notarize-darwin-app.sh`
      copied verbatim from `nlink-jp/.github/templates/` (executable bits set)
- [ ] For WebKit-based frameworks (Wails / Tauri):
      `scripts/entitlements.plist` copied from
      `templates/entitlements-wails.plist` and **not** modified unless the
      app needs additional entitlements
- [ ] `Makefile` `package` target produces a stapled, distributable
      bundle: a zipped `.app` named `<name>-v<version>-darwin-arm64.zip`
      (no `.dmg` — see §Release Archive Standard)
- [ ] `make package` passes `spctl --assess` with
      `source=Notarized Developer ID` — the only release-gate that matters
- [ ] README documents the signed/notarized state (see
      [Starting a new GUI app](#starting-a-new-gui-app) step 6)
- [ ] No `signingIdentity`, team ID, key ID, or `.p8` path in any committed file

**Repository structure (Skill):**

- [ ] Skill content lives in `<skill-name>/` with `SKILL.md` directly inside;
      frontmatter `name:` equals the directory name (the directory name is
      the slash command)
- [ ] `tests/validate-skill.sh` vendored **byte-identical** from
      `.github/templates/validate-skill.sh` (executable bit set — ADR-006;
      check-org check 10b enforces this)
- [ ] Repo-specific tests, if any, hooked into the Makefile `check` target
      (never into the vendored validator)
- [ ] `make check` passes
- [ ] `make package` produces `dist/<skill>-vX.Y.Z.zip` with the skill folder
      at the zip root — unzip and verify `<skill>/SKILL.md` is directly
      inside (ADR-004; no README or repo scaffolding in the zip)
- [ ] `.gitignore` contains `dist/` (and `.DS_Store`)

**Documentation:**

- [ ] `README.md` and `README.ja.md` created with at least description and installation
- [ ] `CHANGELOG.md` created with `## [0.1.0]` section
- [ ] `CLAUDE.md` created with project-specific rules for AI agents
- [ ] `AGENTS.md` created with: project summary, build/test commands, key directory
      structure, gotchas, and module path — must describe **this** project
      (never copy another project's `AGENTS.md` without updating all fields)

**Organization integration:**

- [ ] Project developed in `_wip/<tool-name>/`, **not** inside an umbrella series directory
- [ ] Repository created under `nlink-jp` organization
- [ ] Repository is **public** (not private) unless there is a documented reason
- [ ] Repository **About** configured: description and topics set (see [Repository About](#repository-about))
- [ ] Repository **watched** (`gh api -X PUT /repos/nlink-jp/<tool-name>/subscription -F subscribed=true`) — auto-watch no longer exists
- [ ] Repository pushed from `_wip/` to remote before submodule integration
- [ ] Repository added as submodule to the appropriate series umbrella repo
- [ ] Series umbrella `.gitmodules` entry uses `https://github.com/nlink-jp/<tool-name>.git`
- [ ] Umbrella repo submodule pointer committed and pushed
- [ ] `_wip/<tool-name>/` removed after submodule integration confirmed
- [ ] `nlink-jp/.github/profile/README.md` updated if the tool is user-facing
- [ ] `check-org.sh` passes after all integration steps

### Phase 3: Development

Only after planning is complete and the scaffold passes `check-org.sh`, begin
writing production code. Follow the [Development Policy](#development-policy)
below for all implementation work.

---

## Development Policy

### Consult and feed the knowledge base

The organization's engineering lessons live in
[`nlink-jp/knowledge`](https://github.com/nlink-jp/knowledge) — themed bilingual
documents compiled from real incidents (ADR-015). The loop is mandatory, not
best-effort:

- **Consult before building.** When starting design or implementation work in a
  domain the knowledge base covers (release engineering, macOS GUI, MCP servers,
  LLM integration, shell scripting, …), read the relevant document first — the
  same standing the ADR index above has for technical decisions.
- **Feed back what you learn.** When work surfaces new reusable engineering
  knowledge — an incident, a non-obvious workaround, a pattern worth repeating —
  contribute it to `nlink-jp/knowledge` as part of completing that work, not
  deferred. Entries follow **symptom → why → how to apply**, Japanese authored
  first with English in the same commit, and pass the sanitization gate (no
  environment-specific values, no personal names).

### Security first

- Treat security as a design constraint, not an afterthought.
- Never store credentials in source code.
- Validate inputs at system boundaries (user input, external APIs, file I/O).
- Keep dependencies up to date; run vulnerability scanners as part of the quality gate.
- See [Security](#security) for specifics.

### Design and implement for testability

- Structure code so that units can be tested in isolation.
- Inject dependencies; avoid package-level globals that cannot be replaced in tests.
- Prefer pure functions and small, focused types.

### Build small, fix small

- Prefer small, composable units over large monolithic ones.
- When fixing a bug, make the smallest change that addresses the root cause.
- Do not refactor, reformat, or improve unrelated code in the same change.

### Implement code and tests together

- Tests are not optional or deferred — write them alongside the implementation.
- A feature is not complete until it has tests.
- Tests must cover the happy path and the relevant failure modes.

### Update documentation and code together

- Documentation drift is a bug.
- When behaviour changes, update `README.md`, `docs/`, and any affected translations
  in the same commit or PR.
- Japanese translations must be kept in sync with every English change.

### Documentation structure

Project root:
- `README.md` — English (canonical, displayed by GitHub)
- `README.ja.md` — Japanese (root-level special case, `.ja.md` suffix)

Additional documents (design docs, RFP, reference manuals, evaluation guides):
- `docs/en/*.md` — English, **no language suffix**
- `docs/ja/*.ja.md` — Japanese, **`.ja.md` suffix**

Do NOT duplicate root READMEs into `docs/en/` or `docs/ja/`.
Do NOT use a flat `docs/design/` directory — always separate by language.

### Make small commits

- Each commit should represent one logical change.
- Mixing features, fixes, and refactors in one commit makes history hard to read
  and reverts risky.
- Commit message format: `<type>: <imperative short description>`
  — common types: `feat`, `fix`, `docs`, `chore`, `security`, `test`, `refactor`.

---

## Build Conventions

### Always use `make`, never `go build` directly

All builds must go through the Makefile. **Never run `go build` (or `go install`) directly
in a project directory.**

- `go build` without `-o dist/...` drops the binary in the current directory,
  polluting the working tree and causing spurious `untracked content` in the parent
  submodule.
- The Makefile encodes the correct output path (`dist/`), LDFLAGS (`-X main.version`),
  and `CGO_ENABLED=0` for all targets.

| Task | Command |
|------|---------|
| Build for current platform | `make build` |
| Build all platforms | `make build-all` |
| Run tests | `make test` (or `go test ./...` — safe, no binary output) |
| Verify build + tests | `make check` |

> `go test ./...` is fine to run directly — it does not produce stray binaries.

### Recursive rewrites: prefer module-scoped tools, and install the guard

A command that walks a directory tree and rewrites files in place — `gofmt -w`,
`sed -i`, `prettier --write`, `black`, `ruff format` — destroys work far outside
the intended repository when the working directory is not what you assumed.
This has happened twice in this organization: `gofmt -w .` executed from the
workspace root reformatted every Go file in every series (26 repos the first
time, 39 the second). Nothing was lost, because nothing had been committed, but
both incidents produced a workspace full of unreviewed changes.

**Two controls, in this order.**

1. **Choose tools that fail instead of ranging.** Module-scoped commands stop at
   the module boundary, so a wrong working directory becomes a harmless error
   rather than a mass edit:

   | Instead of | Use | Behaviour outside a module |
   |---|---|---|
   | `gofmt -w .` | `go fmt ./...` | fails: "directory prefix . does not contain main module" |
   | `gofmt -w .` (single repo) | `gofmt -w /absolute/path/to/repo` | writes only where told |
   | `ruff format` | `ruff format /absolute/path` | writes only where told |

2. **Install the mechanical guard.** A written rule is not a control: the
   accident happens exactly when attention lapses, which is also when the rule
   is forgotten — the second incident occurred with the rule already written
   down. The guard is a Claude Code `PreToolUse` hook that refuses a recursive
   in-place rewrite whose target is relative or absent:

   ```sh
   .github/scripts/install-claude-guards.sh          # install / update
   .github/scripts/install-claude-guards.sh --check  # verify (check-org.sh runs this)
   ```

   It installs `.github/claude-code/guard-recursive-write.py` into
   `~/.claude/hooks/` and merges the hook into `~/.claude/settings.json`,
   leaving other settings untouched. It is idempotent, and it runs the guard's
   own test battery (`guard-recursive-write-test.py`) before installing, so a
   guard edited into uselessness cannot reach a machine.

   Allowed through: absolute targets, `~`-rooted targets, a command anchored by
   a leading `cd /absolute/path &&`, and every read-only command
   (`gofmt -l .`, `go fmt ./...`, `grep -r`).

   `check-org.sh` audits the installation, so a new machine that skipped setup
   shows up as a failed check rather than as the next incident.

   **Known limit:** the hook inspects shell commands. Code that performs the
   same rewrite from inside a script or program it launches is not covered.
   Narrowing writable paths (`sandbox.filesystem.denyWrite`, or a tighter set
   of `additionalDirectories`) is the stronger control where that matters.

### Build output directory

All build targets must output to `dist/`:

| Target | Output |
|--------|--------|
| `make build` | `dist/<binary>` |
| `make build-all` | `dist/<binary>-<os>-<arch>` |
| `make clean` | `rm -rf dist/` |

**Prohibited patterns:**

- Output to project root (`go build -o <binary> .`) — pollutes the working tree
  and causes `.gitignore` confusion.
- Output to `bin/` — non-standard for this organization. Use `dist/` exclusively.
- Using separate variables for `build` and `build-all` output dirs within one
  Makefile (e.g. `BIN_DIR` for one target and `DIST_DIR` for the other).

The rule is about the **path**, not the variable name: `BIN_DIR := dist` is
conventional, because the resolved output is still `dist/`. `check-org.sh`
resolves the variable's value and compares that, so any name is accepted as
long as one variable is used consistently and its value is `dist`.

### `.gitignore` rules for build artifacts

1. **Always include `dist/`** in `.gitignore`.
2. **Never include bare binary names** (e.g. `my-tool`) — without a leading `/`,
   git treats it as a pattern matching any path, which silently excludes
   `cmd/my-tool/` or other source directories with the same name.
3. **Do not include `/my-tool` or `bin/`** — if `make build` outputs to `dist/`,
   these patterns are unnecessary and become stale traps.

**Rule of thumb:** If `dist/` is in `.gitignore`, no other build artifact
patterns should be needed.

### `main.go` placement

`main.go` must be at the **project root**, not inside `cmd/<name>/`.

```
my-tool/
  main.go          ← entry point (package main)
  cmd/             ← cobra commands (package cmd)
    root.go
    ...
  internal/        ← private packages
```

Placing `main.go` inside `cmd/<name>/` creates a risk: if `.gitignore` excludes
the binary name without a leading `/`, the entire `cmd/<name>/` directory becomes
invisible to git — a **silent code-loss** scenario.

### Multi-binary Go projects

Some projects legitimately need multiple entry points (e.g. a main CLI and an
evaluation tool). In this case, use `cmd/` subdirectories:

```
my-tool/
  main.go              ← primary entry point (always at root)
  cmd/
    root.go
    eval/
      main.go          ← secondary entry point
```

**Rules for multi-binary projects:**

- The **primary** entry point must still be `main.go` at the project root.
- Secondary entry points may live under `cmd/<subcommand>/main.go`.
- `Makefile` must have explicit build targets for each binary, all outputting
  to `dist/`.
- Document the multi-binary structure in `AGENTS.md`.

### AGENTS.md accuracy

Each project's `AGENTS.md` must describe **that specific project**.
When creating a new project by copying from an existing one, always update:

- The title and description
- Build output paths
- Key structure listing
- Module path
- Environment variable names

Stale or copied-from-another-project `AGENTS.md` files mislead both human
developers and AI agents.

---

## Release Archive Standard

Every repo that ships a built release archive (Go CLI, native GUI) uses one
uniform archive convention across all platforms. Signing / notarization (next
section) rides on top of this.

**Applies to:** repos distributing built macOS / Linux / Windows archives. Not
Python (uv), pure bash, embedded (M5Stack), or libraries — those use their
native channels. Lab repos are exempt until they graduate to a notarized release.

### Naming (all platforms)

Every release asset is named:

    <name>-v<version>-<os>-<arch>.<ext>

| Token | Value |
|---|---|
| `<name>` | canonical name — the command name for a CLI (`mdv`), the repo name in kebab-case for a GUI (`image-forge-gui`) |
| `<version>` | git tag with a single leading `v` (`v0.3.2`). If a build reads the version without the `v` (e.g. Tauri's `package.json`), the Makefile adds it. |
| `<os>` / `<arch>` | `darwin` / `linux` / `windows` × `arm64` / `amd64` — arch is **always** explicit |
| `<ext>` | `.zip` for darwin & windows; `.tar.gz` permitted for linux. **darwin never uses tar.gz or dmg.** |

### Archive contents

- **CLI archive:** the canonical binary named `<name>` (no os/arch/version suffix
  inside the archive) + `README.md` + `LICENSE`. Extra license notices
  (`FONTS_LICENSE`, etc.) are allowed when warranted.
- **GUI archive:** the notarized + stapled `<Name>.app`, archived with
  `ditto -c -k --keepParent` to preserve the bundle signature. Nothing else is
  bundled — extra files would disturb the signed bundle; README/LICENSE live in
  the repo and on the release page. The `.app`'s internal display name is not
  normalized; only the archive name is.
- **One archive per (os, arch).** No parallel `.dmg` beside the zip.

### darwin architecture policy (effective 2026-07-12)

- **darwin ships arm64 only.** darwin-amd64 (Intel) is discontinued and
  **universal binaries are not produced** (wasted size).
- Remove darwin-amd64 and universal (`lipo`) from each Makefile's `build-all` /
  `package` / notarize steps. For GUI `.app`s, confirm the bundle is arm64-only
  (`lipo -archs` / `file`), not universal.
- **darwin only.** Linux / Windows keep their existing multi-arch matrix
  (linux-amd64, linux-arm64, windows-amd64, …).

Migration is progressive: bring each repo's Makefile into line, verify signing
and notarization still pass, then cut a fresh release (a packaging / build-config
version bump) so the published archive adopts the standard. Old tags are not
re-cut.

---

## Code Signing and Notarization (macOS)

### Principle

Public macOS release zips must be **Developer ID signed and Apple-notarized**.

End users should be able to download → unzip → run a release binary without
any of the Gatekeeper bypass rituals (right-click → Open, `xattr -d
com.apple.quarantine`, manual re-codesign). Local users (incl. the
maintainer) running these binaries from Dropbox-synced or other
FileProvider-managed paths must not be SIGKILL'd by macOS's
ad-hoc-signed + `com.apple.provenance` distrust policy.

This applies to every public Go CLI project. Wails / Swift / Tauri
`.app` bundles follow a related but distinct pipeline (see §Wails / GUI
apps below).

### Architecture

Two scripts, both committed to each project's `scripts/` directory:

| Script | Role | Skips when |
|---|---|---|
| `scripts/codesign-darwin.sh <binary> [identity]` | Signs darwin Mach-O with Hardened Runtime + Apple timestamp | Non-Darwin host, file not Mach-O, no matching identity in keychain |
| `scripts/notarize-darwin.sh <zip> [profile]` | Submits zip to Apple notary, waits for verdict | Non-Darwin host, no keychain profile present |

Both scripts skip gracefully when credentials are unavailable, so
contributors without an Apple Developer Program account, and CI
environments without injected credentials, can still build — they just
get ad-hoc-signed un-notarized output with a one-line warning instead
of a hard failure.

Canonical source: `templates/codesign-darwin.sh` and
`templates/notarize-darwin.sh` in `nlink-jp/.github`. Each project
copies these into its own `scripts/` directory verbatim. Updates to the
templates propagate by re-copy (no submodule).

### One-time machine setup

Required only on machines that actually sign + notarize releases:

1. **Apple Developer Program** membership ($99/year, individual or
   organization). The team must include the developer (or be the
   developer themselves for individual programs).

2. **Developer ID Application** certificate in the local keychain:

   ```
   Xcode → Settings → Accounts → Apple ID → Manage Certificates → +
       → Developer ID Application
   ```

   Verify:

   ```sh
   security find-identity -v -p codesigning
   # 1) <hash> "Developer ID Application: <name> (<TEAM_ID>)"
   ```

3. **App Store Connect API key (Team Key)** stored in the keychain
   under a generic profile name (`nlink-jp-notary` by convention):

   - https://appstoreconnect.apple.com/access/integrations/api →
     **Team Keys** tab → **+** → Access: **Developer** (minimum)
   - Download `.p8` to `~/Library/Keys/AuthKey_<KEY_ID>.p8`
     (one-time download; if lost, revoke and create a new key)
   - Copy the **Key ID** and the **Issuer ID** (shown at the top of
     the Team Keys page; Individual Keys do not expose an Issuer ID
     and cannot be used with notarytool's `--issuer` flow)
   - Store credentials in keychain:

     ```sh
     xcrun notarytool store-credentials nlink-jp-notary \
         --key   ~/Library/Keys/AuthKey_<KEY_ID>.p8 \
         --key-id <KEY_ID>
     # prompts interactively for Issuer ID — keeps it out of shell history
     ```

   - Verify:

     ```sh
     xcrun notarytool history --keychain-profile nlink-jp-notary
     # No submission history.  (success — credentials authenticated)
     ```

### Per-project Makefile integration

In each Go CLI project's `Makefile`:

```makefile
# Defaults: match a generic Developer ID Application cert and a generic
# keychain profile name. No personal identifier, team ID, or credential
# lands in the committed Makefile.
CODESIGN_IDENTITY ?= Developer ID Application
NOTARY_PROFILE    ?= nlink-jp-notary

# darwin ships arm64 only (no amd64, no universal). linux/windows keep their matrix.
PLATFORMS := darwin/arm64 linux/amd64 linux/arm64 windows/amd64

build:
	@mkdir -p dist
	go build $(GOFLAGS) -o dist/$(BINARY) .
	@scripts/codesign-darwin.sh dist/$(BINARY) "$(CODESIGN_IDENTITY)"

build-all:
	@mkdir -p dist
	@for p in $(PLATFORMS); do os=$${p%/*}; arch=$${p#*/}; \
		ext=""; [ "$$os" = windows ] && ext=".exe"; \
		GOOS=$$os GOARCH=$$arch go build $(GOFLAGS) -o dist/$(BINARY)-$$os-$$arch$$ext . ; \
	done
	@scripts/codesign-darwin.sh dist/$(BINARY)-darwin-arm64 "$(CODESIGN_IDENTITY)" "$(BINARY)"

# Archive: <name>-v<version>-<os>-<arch>.<ext>  (darwin/windows = zip, linux = tar.gz)
# The in-archive binary is the canonical <name>; README.md + LICENSE are bundled.
package: build-all
	@cd dist && for p in $(PLATFORMS); do os=$${p%/*}; arch=$${p#*/}; \
		ext=""; [ "$$os" = windows ] && ext=".exe"; \
		stage=_pkg; rm -rf $$stage; mkdir -p $$stage; \
		cp "$(BINARY)-$$os-$$arch$$ext" "$$stage/$(BINARY)$$ext"; \
		cp ../README.md ../LICENSE $$stage/; \
		base="$(BINARY)-$(VERSION)-$$os-$$arch"; \
		if [ "$$os" = linux ]; then ( cd $$stage && tar -czf "../$$base.tar.gz" * ); \
		else ( cd $$stage && zip -q "../$$base.zip" * ); fi; \
		rm -rf $$stage; \
	done
	@scripts/notarize-darwin.sh dist/$(BINARY)-$(VERSION)-darwin-arm64.zip "$(NOTARY_PROFILE)"
```

Copy the two scripts verbatim from `nlink-jp/.github/templates/`:

```sh
cp ~/works/nlink-jp/.github/templates/codesign-darwin.sh scripts/
cp ~/works/nlink-jp/.github/templates/notarize-darwin.sh scripts/
chmod +x scripts/codesign-darwin.sh scripts/notarize-darwin.sh
```

### What does NOT go in the repo

- The signing identity name (`Developer ID Application: <name>
  (<TEAM_ID>)`) — Makefile uses the generic `Developer ID
  Application` prefix; the keychain auto-matches by certificate
  type. The maintainer's real name (PII) stays out of source.
- The Team ID — it appears in signed binaries by design, but
  committing it serves no purpose.
- The App Store Connect API key (`.p8`), Key ID, or Issuer ID —
  these stay in the local keychain (via `store-credentials`) and
  in `~/Library/Keys/` (outside any repo).

The committed Makefile and scripts contain only generic identifiers
(`Developer ID Application`, `nlink-jp-notary`) that other developers
or future team members can override locally.

### Verifying a release

After `make package`, before uploading:

```sh
# Signature present + Developer ID issuer
codesign -dv dist/<binary>-darwin-arm64

# Notarization ticket attached (Apple-side online check)
spctl --assess --type install \
      --context context:primary-signature \
      dist/<binary>-darwin-arm64
```

For GUI `.app` bundles (Wails / Tauri / Swift), the verification
sequence is slightly different — bundles support stapling, so you
should confirm the ticket is embedded:

```sh
# Signature + Hardened Runtime + Developer ID issuer
codesign -dvv dist/<App>.app

# Embedded notarization ticket
xcrun stapler validate dist/<App>.app

# The only gate that matters: Gatekeeper accepts as notarized
spctl --assess --type execute --verbose=4 dist/<App>.app
# Expected: "<App>.app: accepted   source=Notarized Developer ID"
```

For the notarytool submission log on a specific submission:

```sh
xcrun notarytool log <submission-id> --keychain-profile nlink-jp-notary
```

### Why no stapling for CLI binaries

`stapler staple` only works on app bundles, `.dmg`, and `.pkg`.
Bare CLI binaries inside a zip cannot be stapled. Instead, the
notarization ticket lives on Apple's servers and macOS checks it
**online** the first time the binary is launched on a given
machine. This is the standard Apple-supported pattern for CLI
distributables. Offline first-launch on a fresh machine shows a
brief verification dialog; once cached, subsequent launches are
instant.

### GUI app (`.app`) signing

`.app` bundle projects use a distinct pipeline from CLI binaries
because:

- The signature must cover the whole bundle (`--deep`), not just
  the inner Mach-O executable.
- Hardened Runtime breaks WebKit JIT, so embedded-WebView frameworks
  (Wails / Tauri) need explicit JIT entitlements or the frontend
  silently renders blank. Native Swift / AppKit apps do **not**.
- `.app` bundles **can** be stapled, so the notarization ticket
  travels with the build and offline first-launch works without
  any dialog (unlike CLI binaries — see previous section).

**Reference templates** in `templates/`:

| File | Purpose |
|---|---|
| `codesign-darwin-app.sh` | Deep-sign an `.app` with Hardened Runtime + timestamp + optional entitlements. Skips gracefully without an identity. |
| `notarize-darwin-app.sh` | Submit `.app` (wrapped in temp zip), wait, then `stapler staple` the bundle. |
| `entitlements-wails.plist` | Minimal WebKit-JIT entitlements: `allow-jit` + `allow-unsigned-executable-memory`. Used by both Wails and Tauri. |

**Universal rules across all frameworks**:

- **`ditto`, not `cp -r`**: bundle signatures are stored in
  extended attributes; `cp -r` strips them and the launched binary
  aborts with "SIGKILL (Code Signature Invalid)". Use `ditto` for
  any bundle move/copy and `ditto -c -k --keepParent <app>.app
  <out>.zip` for distribution zips.
- **Sign first, staple second**: notarize before stapling, and
  staple the **same** `.app` file you ship. Stapling rewrites
  `_CodeSignature/` resources — never re-zip from a different
  `.app` after stapling.
- **Distribution format**: every GUI framework ships a zipped `.app`
  (`ditto -c -k --keepParent`), named `<name>-v<version>-darwin-arm64.zip`
  per §Release Archive Standard. **No `.dmg`** — Tauri is configured with
  `--bundles app` so it never emits one. (`.app` and `.dmg` both support
  `stapler staple`; CLI Mach-O binaries do not.)
- **App-specific entitlements**: if a project needs more than the
  base entitlements (Apple Events, microphone, location, etc.),
  **copy** the template into the project as
  `scripts/entitlements.plist` and add the extra keys there.
  Do **not** edit the template in `templates/` — every additional
  entitlement weakens Hardened Runtime guarantees and should be a
  per-app decision.

The next three subsections cover what's different per framework.

#### Wails (Go + WebKit)

Used by: `shell-agent-v2`, `csv-editor`. Pattern: `wails build`
emits an ad-hoc-signed `.app` under `build/bin/`, then a post-build
script applies Developer ID signing.

Per-project layout:

- `scripts/codesign-darwin-app.sh` — copied verbatim from
  `templates/`
- `scripts/notarize-darwin-app.sh` — copied verbatim from
  `templates/`
- `scripts/entitlements.plist` — copied from
  `templates/entitlements-wails.plist`
- `app/Makefile` — wires the scripts into `build` + `package`
  targets (Wails projects keep main.go under `app/`)

`app/Makefile`:

```makefile
APP     := <app-name>
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
LDFLAGS := -X 'main.version=$(VERSION)'

CODESIGN_IDENTITY ?= Developer ID Application
NOTARY_PROFILE    ?= nlink-jp-notary
ENTITLEMENTS      ?= ../scripts/entitlements.plist

CODESIGN_SCRIPT := ../scripts/codesign-darwin-app.sh
NOTARIZE_SCRIPT := ../scripts/notarize-darwin-app.sh

build:
        wails build -ldflags "$(LDFLAGS)"
        @$(CODESIGN_SCRIPT) build/bin/$(APP).app "$(CODESIGN_IDENTITY)" "$(ENTITLEMENTS)"
        mkdir -p dist
        rm -rf dist/$(APP).app
        ditto build/bin/$(APP).app dist/$(APP).app

package: build
        @$(NOTARIZE_SCRIPT) dist/$(APP).app "$(NOTARY_PROFILE)"
        cd dist && /usr/bin/ditto -c -k --keepParent \
                $(APP).app $(APP)-$(VERSION)-darwin-arm64.zip
```

Notes:

- The codesign script's 3rd arg points at the entitlements plist;
  Wails apps **must** pass it or WebKit JIT is killed by Hardened
  Runtime and the frontend silently renders blank.
- Some Wails projects also build CGO-linked sub-binaries
  (`go-duckdb`, etc.) — Wails's bundler picks those up and `--deep`
  signing covers them automatically.

#### Tauri (Rust + WebKit)

Used by: `mail-analyzer-gui`. Pattern: `tauri build -- --bundles app`
does the codesign + bundle step **inline** when `APPLE_SIGNING_IDENTITY`
is set in the environment (restricting to the `app` bundle so no `.dmg`
is produced); the post-build script then notarizes + staples the `.app`
and `ditto`-zips it. **nlink-jp ships a zipped `.app`, not a `.dmg`**
(see §Release Archive Standard).

Per-project layout:

- `scripts/entitlements.plist` — copied from
  `templates/entitlements-wails.plist` (Tauri uses WKWebView too;
  same JIT entitlements apply)
- `src-tauri/tauri.conf.json` — adds
  `bundle.macOS.entitlements: "../scripts/entitlements.plist"`
  (path is relative to `src-tauri/`). Do **not** also set
  `bundle.macOS.signingIdentity` — leave it unset so the
  environment variable (below) is the single source of truth.
- `Makefile` (at the project root, not under `src-tauri/`) — wraps
  `npm run tauri build` with the env var and the notarize+staple step.

`Makefile`:

```makefile
APP       := <app-name>
VERSION   := $(shell node -p "require('./package.json').version")
CODESIGN_IDENTITY ?= Developer ID Application
NOTARY_PROFILE    ?= nlink-jp-notary
NOTARIZE_SCRIPT   := scripts/notarize-darwin-app.sh

# We ship a zipped .app, not a DMG — no Rust-triplet arch juggling needed.
APP_PATH := src-tauri/target/release/bundle/macos/$(APP).app

build:
        @if security find-identity -v -p codesigning 2>/dev/null \
                | grep -q "$(CODESIGN_IDENTITY)"; then \
                APPLE_SIGNING_IDENTITY="$(CODESIGN_IDENTITY)" npm run tauri build -- --bundles app; \
        else \
                echo "[codesign] No '$(CODESIGN_IDENTITY)' identity; bundle keeps ad-hoc signature"; \
                npm run tauri build -- --bundles app; \
        fi

# Ship a zipped .app (no DMG): notarize + staple the .app, then ditto-zip it
# as <name>-v<version>-darwin-arm64.zip (the standard archive name).
package: build
        @$(NOTARIZE_SCRIPT) $(APP_PATH) "$(NOTARY_PROFILE)"
        @mkdir -p dist
        @cd $(dir $(APP_PATH)) && /usr/bin/ditto -c -k --keepParent \
                $(APP).app "$(CURDIR)/dist/$(APP)-v$(VERSION)-darwin-arm64.zip"
```

Tauri-specific traps to be aware of:

- **Ship the `.app`, not the `.dmg`.** `--bundles app` skips DMG
  generation entirely, so the Rust-triplet `aarch64` filename quirk and
  the `sed` arch conversion are gone — we name our own zip
  `<name>-v<version>-darwin-arm64.zip`.
- **Tauri's built-in notarize is incompatible** with our
  `nlink-jp-notary` keychain profile — it expects
  `APPLE_ID + APPLE_PASSWORD + APPLE_TEAM_ID` or an API-key triple
  in the environment. Leave those env vars unset so Tauri prints
  "Warn skipping app notarization" and we handle it ourselves with
  the same `xcrun notarytool` profile every other project uses.
- **Re-running `make package` re-runs `tauri build`**, which
  regenerates the `.app` and strips any staple. That is fine here —
  `package` always re-notarizes + re-staples the freshly built `.app`
  before zipping, so every run yields a correct archive.
- **Confirm the bundle is arm64-only** (`lipo -archs` on the inner
  Mach-O): universal slices waste space and are discontinued.

#### Native Swift / AppKit (Swift Package Manager)

Used by: `quick-translate`. Pattern: `swift build -c release`
produces a bare Mach-O binary; the Makefile manually assembles the
`.app` bundle (`Contents/MacOS/`, `Contents/Info.plist`,
`Contents/Resources/`) and signs at the end of the bundle step.

Key differences from Wails / Tauri:

- **No JIT entitlements needed.** Native Swift / AppKit does not
  embed WebKit / JavaScriptCore, so Hardened Runtime alone is
  sufficient. **Do not** copy `entitlements-wails.plist` into the
  project. Call `codesign-darwin-app.sh` with the 3rd argument
  empty; the script then omits `--entitlements` entirely.
- **Manual bundle assembly.** Unlike Wails or Tauri, SPM does not
  produce an `.app` — the Makefile copies the binary, the icon, and
  a templated `Info.plist` into the bundle structure itself.
- **No frontend pipeline.** Skip `npm install`, `vite build`, etc.

`Info.plist` (at the project root) uses Makefile-substituted
placeholders:

```xml
<key>CFBundleExecutable</key>       <string>${APP_NAME}</string>
<key>CFBundleIdentifier</key>       <string>${BUNDLE_ID}</string>
<key>CFBundleShortVersionString</key><string>${VERSION}</string>
<key>CFBundleVersion</key>          <string>${VERSION}</string>
```

`Makefile`:

```makefile
APP_NAME   := <CamelCase-name>
NAME       := <kebab-name>          # repo/command name — used for the archive name
BUNDLE_ID  := jp.nlink.<kebab-name>
VERSION    := $(shell git describe --tags --always --dirty 2>/dev/null || echo "0.1.0")
BUILD_DIR  := .build/release
DIST_DIR   := dist
APP_BUNDLE := $(DIST_DIR)/$(APP_NAME).app

CODESIGN_IDENTITY ?= Developer ID Application
NOTARY_PROFILE    ?= nlink-jp-notary
CODESIGN_SCRIPT   := scripts/codesign-darwin-app.sh
NOTARIZE_SCRIPT   := scripts/notarize-darwin-app.sh

build:
        @mkdir -p $(DIST_DIR)
        swift build -c release

build-app: build
        @rm -rf $(APP_BUNDLE)
        @mkdir -p $(APP_BUNDLE)/Contents/MacOS
        @mkdir -p $(APP_BUNDLE)/Contents/Resources
        @cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
        @sed 's/$${VERSION}/$(VERSION)/g; s/$${BUNDLE_ID}/$(BUNDLE_ID)/g; \
              s/$${APP_NAME}/$(APP_NAME)/g' Info.plist > $(APP_BUNDLE)/Contents/Info.plist
        @cp icon.icns $(APP_BUNDLE)/Contents/Resources/icon.icns
        @$(CODESIGN_SCRIPT) $(APP_BUNDLE) "$(CODESIGN_IDENTITY)"

package: build-app
        @$(NOTARIZE_SCRIPT) $(APP_BUNDLE) "$(NOTARY_PROFILE)"
        @cd $(DIST_DIR) && /usr/bin/ditto -c -k --keepParent \
                $(APP_NAME).app $(NAME)-$(VERSION)-darwin-arm64.zip
```

Notes:

- The codesign call has only two arguments
  (`$(APP_BUNDLE) "$(CODESIGN_IDENTITY)"`) — the entitlements arg is
  omitted intentionally.
- Non-sandboxed Swift apps can read/write files, talk to localhost
  HTTP, and access the Keychain without any entitlements. Only add
  entitlements if you genuinely need a sandbox-protected capability
  (microphone, location, etc.).
- If you need Apple Events / scripting access, that's a per-app
  entitlement and a Hardened Runtime exception
  (`com.apple.security.cs.disable-library-validation` etc.) — write
  a project-local `scripts/entitlements.plist` and pass it as the
  3rd arg to `codesign-darwin-app.sh`.

### Starting a new GUI app

When scaffolding a new `.app`-bundle project, the signing wiring is
the same minimal sequence regardless of framework:

1. **Pick the framework first** (Wails / Tauri / Swift SPM) — that
   determines which subsection above applies and which entitlements
   template (if any) to copy.
2. **Copy the templates into `scripts/`** (project root, never under
   `app/` or `src-tauri/`):

   ```sh
   mkdir -p scripts
   cp ~/works/nlink-jp/.github/templates/codesign-darwin-app.sh scripts/
   cp ~/works/nlink-jp/.github/templates/notarize-darwin-app.sh  scripts/
   chmod +x scripts/codesign-darwin-app.sh scripts/notarize-darwin-app.sh
   # WebKit-based frameworks only:
   cp ~/works/nlink-jp/.github/templates/entitlements-wails.plist scripts/entitlements.plist
   ```

3. **Add the `Makefile`** (or `app/Makefile` for Wails) using the
   template for the chosen framework above. Keep
   `CODESIGN_IDENTITY ?= Developer ID Application` and
   `NOTARY_PROFILE ?= nlink-jp-notary` as defaults — those are the
   only sane org-wide values and they leak no personal info.
4. **For Tauri**, also update `src-tauri/tauri.conf.json`:

   ```json
   "bundle": {
     "macOS": {
       "entitlements": "../scripts/entitlements.plist"
     }
   }
   ```

5. **Run `make package` once** and confirm
   `spctl --assess --type execute <app>.app` returns
   `source=Notarized Developer ID`. That's the only release gate that
   matters; the rest is cosmetic.
6. **Document signing state in the README**. The convention text is
   one of:

   - `> macOS releases are **Developer ID signed and
     Apple-notarized** (stapled). They launch without Gatekeeper
     prompts and work offline.`
   - For mixed-platform releases where Windows / Linux stay
     unsigned, say so explicitly so users aren't surprised by
     SmartScreen / no-signature warnings on the other OSes.

7. **Do not commit any user-private values** — see "What does NOT
   go in the repo" earlier in this section. The team ID, signing
   identity name, and notary key ID belong in the developer's
   keychain, never in the source tree.

Reference projects (one per framework, look at these when in doubt):

| Framework | Reference project |
|---|---|
| Wails | [shell-agent-v2](https://github.com/nlink-jp/shell-agent-v2) |
| Tauri | [mail-analyzer-gui](https://github.com/nlink-jp/mail-analyzer-gui) |
| Swift SPM | [quick-translate](https://github.com/nlink-jp/quick-translate) |
| Go CLI (for contrast) | [splunk-cli](https://github.com/nlink-jp/splunk-cli) |

### Why this matters

- **Trust UX for end users** — public release binaries that
  require manual Gatekeeper bypass tell every downloader "you're
  running an unsigned binary." Notarized binaries are the
  contemporary baseline for macOS distribution.
- **Sync-friendly local execution** — recent macOS versions
  SIGKILL ad-hoc-signed binaries that carry the
  `com.apple.provenance` xattr (added by Dropbox / iCloud /
  OneDrive FileProvider extensions). Developer ID signed
  binaries are portable across the sync boundary; ad-hoc are not.
- **Future-proofing** — Apple has tightened Gatekeeper's
  treatment of ad-hoc signatures in successive macOS releases.
  Developer ID + Notarization is the only path that's stable
  across future tightening.

---

## Repository About

Every repository must have its **About** metadata configured at creation time.
This metadata is displayed on the GitHub repository page and used for search
and discovery.

**Required fields:**

1. **Description** — A concise one-line summary of what the repository does.
   Set via `gh repo edit --description "..."` or the GitHub web UI.

2. **Topics** — Relevant keywords for discoverability.
   Set via `gh repo edit --add-topic <topic>`.

**Topic guidelines:**

- Include the primary language(s): `golang`, `python`, `bash`
- Include the problem domain: `cli`, `chatops`, `cybersecurity`, `llm`, etc.
- Include key technologies or services: `slack`, `gemini`, `duckdb`, etc.
- Use lowercase, hyphen-separated words (GitHub enforces this)
- Keep the total count reasonable (3–8 topics)

**When to update:**

- At repository creation (part of the scaffold checklist)
- When the project scope, language, or key dependencies change significantly
- When adding major new features that warrant additional topics

---

## Archiving a Repository

When a tool is retired or superseded:

1. Mark it in the umbrella README catalog (`~~...~~ **Archived** — superseded
   by [successor]` where applicable) and, if it was a listed tool, update the
   org profile README and the `nlink-web-site` catalog (see Release Checklist
   step 9).
2. Archive on GitHub: `gh repo archive nlink-jp/<tool-name>`. Released assets
   stay downloadable; the repo becomes read-only.
3. Switch the notification subscription from watching to ignoring —
   an archived repo cannot receive issues/PRs, so a lingering watch is noise:
   ```bash
   gh api -X PUT /repos/nlink-jp/<tool-name>/subscription -F ignored=true
   ```

`check-org.sh` treats GitHub's archived state as authoritative and excludes
archived repos from template-drift checks.

---

## Authentication

Credentials must never be stored in source code. Supported mechanisms in priority order:

1. **OS keychain** (recommended for interactive use): store tokens via system keyring APIs.
2. **Environment variables**: `<SERVICE>_TOKEN`, `<SERVICE>_API_TOKEN`, etc.
3. **`.env` file** in the working directory (loaded at startup, `.gitignore`d).
4. **Config file** at `~/.config/<tool>/config.{toml,yaml,json}` (sensitive fields only).

Config files that may contain secrets must warn on insecure permissions
(`perm & 0077 != 0`):

```
Warning: config file <path> has permissions <octal>; expected 0600.
  The file may contain credentials. Run: chmod 600 <path>
```

---

## Security

### Principle

Security is the **highest priority** — above features, above deadlines,
above convenience. A security violation in a public repository is
**irreversible** (git history is cached, forked, and indexed). Prevention
is the only acceptable strategy.

### Never commit protected information to public repositories

The following must **never** appear in committed files:

- **Personal information (PII)** — real names, email addresses, usernames,
  employee IDs, or any data that identifies a specific individual. Use
  generic placeholders (`nlink-jp maintainers`, `user@example.com`) instead.
- **GCP project IDs, project numbers** (e.g. `my-project-123456`)
- **Service account emails** (e.g. `sa@project.iam.gserviceaccount.com`)
- **API keys, tokens, passwords** (e.g. `xoxb-...`, `sk-...`, `AIza...`)
- **Bucket names, database connection strings** that reveal infrastructure
- **IP addresses, internal hostnames, account IDs**

This applies to all committed content: source code, documentation, ADRs,
commit messages, PR descriptions, and configuration templates. Content from
external sources (emails, tickets, logs) must be sanitized before inclusion.

**How to handle deployment configuration:**

1. Committed files use **placeholder values only** (`PROJECT_ID`, `BUCKET_NAME`,
   `SA_EMAIL`). These serve as templates.
2. Local overrides use the `.local.*` suffix (e.g. `cloudrunjob.local.yaml`)
   and are **excluded by `.gitignore`**.
3. Runtime values are injected via **environment variables** or
   **Secret Manager** — never baked into images or committed to source.

```
deploy/
  cloudrunjob.yaml         ← template with placeholders (committed)
  cloudrunjob.local.yaml   ← real values (gitignored, never committed)
  topics.toml              ← non-sensitive config (committed)
```

**`.gitignore` must include:**

```gitignore
# Local deployment overrides (contain environment-specific values)
deploy/*.local.*
*.local.yaml
*.local.toml
*.local.json
```

### Pre-commit secret detection

Every repository should detect accidentally committed secrets **before
they reach the remote**. Use one or more of:

1. **Pattern-based `.gitignore`**: exclude `*.local.*`, `.env`, `config.toml`
2. **Pre-commit hook**: scan staged files for patterns matching project IDs,
   tokens, or service account emails
3. **CI-level scanning**: run `gitleaks`, `truffleHog`, or equivalent in CI

Example pre-commit hook pattern (add to `.git/hooks/pre-commit`):

```bash
#!/bin/bash
# Block commits containing likely secrets
PATTERNS='xoxb-|xoxp-|sk-ant-|AIza|\.iam\.gserviceaccount\.com|AKIA[A-Z0-9]'
if git diff --cached --diff-filter=ACM | grep -qE "$PATTERNS"; then
  echo "ERROR: Possible secret detected in staged files."
  echo "Review with: git diff --cached | grep -E '$PATTERNS'"
  exit 1
fi
# Block go.mod local replace directives (leaks local paths)
if git diff --cached --diff-filter=ACM -- '*/go.mod' 'go.mod' | grep -qE '^\+.*replace.*=>.*/(Users|home)/'; then
  echo "ERROR: go.mod contains local replace directive (leaks local paths)."
  echo "Use a published version instead of a local path."
  exit 1
fi
```

### go.mod local replace directives

**Never commit `replace` directives with local filesystem paths** to public
repositories. A line like `replace foo => /Users/alice/src/foo` leaks the
username, OS, and directory structure.

- Use published module versions (e.g., `github.com/nlink-jp/nlk v0.5.1`)
- If a local replace is needed during development, remove it before committing
- `check-org.sh` (check 8) scans for this automatically

### Incident response for accidental secret exposure

If secrets or environment-specific values are pushed to a public repository:

1. **Immediately rotate** all exposed credentials (tokens, keys, passwords)
2. **Rewrite git history** using `git-filter-repo --replace-text` to remove
   the values from all commits, then `git push --force`
3. **Update submodule pointers** in all umbrella repositories (hashes change)
4. **Document the incident**: what was exposed, for how long, what was rotated
5. **Add the pattern** to pre-commit hooks to prevent recurrence

> History rewriting removes values from the repository, but cached copies
> may persist in GitHub's CDN, forks, or search engine caches for days.
> Credential rotation is therefore **mandatory** regardless of how quickly
> the history is rewritten.

### Additional security requirements

- Config files with credentials must check permissions on load (see [Authentication](#authentication)).
- Tools that transmit credentials over unencrypted HTTP must warn on stderr.
- Dependencies must be kept up to date; run `govulncheck` (Go) or `uv audit` (Python)
  as part of the quality gate.
- For the full security patch workflow, refer to the series-level security patch process
  documentation.

---

## CHANGELOG and Versioning

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) +
[Semantic Versioning](https://semver.org/).

Section categories: `Added`, `Changed`, `Fixed`, `Removed`, `Security`, `Docs`, `Internal`.
Prefix breaking changes with **Breaking:**.

Version bumps:
- Breaking API change → **minor** version while in `0.x` series.
- Security-only fix → **patch** version.

---

## Documentation Conventions

- Primary documentation in **English**.
- Japanese translation (`README.ja.md`, `docs/ja/`) maintained in parallel where applicable.
- `README.md` sections (in order): description → features → installation → configuration →
  usage → building → documentation links.
- Stale documentation is a bug.

---

## Umbrella Repositories

Every series is an umbrella repository: a catalog of git submodules, one
per project. Umbrellas follow one standard file set
([ADR-005](adr/005-umbrella-standardization.md)):

| File | Role |
|------|------|
| `README.md` | **The catalog** — one row per submodule (linked name + one-line description). Rows for former members only when explicitly labeled (moved / renamed / graduated). |
| `CLAUDE.md` | Org-rules header (this document, linked) + series-specific rules |
| `AGENTS.md` | Umbrella workflow only — clone/update/pointer-bump commands and gotchas. Never a second catalog: it links to README.md. |
| `.gitignore` | `.claude/settings.local.json` exclusion |

Optional series extensions: a series-level `CONVENTIONS.md` and `docs/`.

Umbrellas do **not** carry `README.ja.md`, `CHANGELOG.md`, `LICENSE`,
`Makefile`, or `tests/` — those belong to the tool repositories. Umbrellas
mint no tags or releases.

`check-org.sh` enforces the required files, that every submodule appears in
`README.md`, and that all `.gitmodules` URLs are HTTPS.

---

## Working with Submodules

All series (chatops-series, cli-series, cybersecurity-series, lab-series,
lib-series, lite-series, skills-series, util-series) manage projects as
git submodules. Submodule
checkouts are in **detached HEAD** state by default. Making commits in
detached HEAD state produces orphaned commits that are lost when you
switch to a branch.

**Always check out the main branch before making any changes inside a submodule:**

```bash
cd <umbrella-repo>/<project>
git checkout main
git pull
# make changes, commit, push as normal
```

> **Common mistake:** forgetting `git checkout main` before editing leads
> to commits on detached HEAD. The commit exists in reflog but is not on
> any branch and `git push origin main` reports "Everything up-to-date".
> Recovery: `git checkout main && git cherry-pick <commit-hash>`.

**After releasing a submodule project, update the umbrella pointer:**

```bash
cd <umbrella-repo>
git submodule update --remote <project>
git add <project>
git commit -m "chore: update <project> submodule pointer to vX.Y.Z"
git push
```

Skipping the pointer update leaves the umbrella repo pointing at a stale commit.
Run `check-org.sh` after the update to verify.

---

## Homebrew Tap Distribution

nlink-jp's macOS tools are distributed through a Homebrew tap,
[`nlink-jp/homebrew-tap`](https://github.com/nlink-jp/homebrew-tap) — Apple
Silicon only, prebuilt binaries. Users install with:

```sh
brew tap nlink-jp/tap
brew install nlink-jp/tap/<name>          # Go CLI (formula)
brew install --cask nlink-jp/tap/<name>   # notarized GUI (cask)
```

### Principle: prebuilt, never source-built

The tap installs the **already signed + notarized** `darwin-arm64` release zip
as-is (`url` + `sha256` → `bin.install` / `app`). Building from source would
strip the Developer ID signature; installing the notarized asset preserves it,
so `spctl -a` reports `source=Notarized Developer ID` even on a clean machine.

### Eligibility

Only tools that ship a signed + notarized single macOS arm64 binary or `.app`:

| Class | Distribution | Examples |
|---|---|---|
| Go CLI | formula | `gem-search`, `llm-cli`, MCP servers |
| notarized GUI | cask | `csv-editor` (Wails), `*-gui` (Swift), `mail-analyzer-gui` (Tauri) |

**Not eligible** (use their native channel): Python/uv tools (`uv tool install`),
embedded firmware (M5Stack), pure-bash tools — they produce no signed single
binary, so the tap's core value (notarization preservation) does not apply.

### Distributed generation (`make brew`)

Each eligible repo generates **its own** formula/cask at release time from the
real build artifact — no central manifest, no cross-repo sweep, so the
version/sha256 can never drift from what shipped. The generator is a vendored
shell script, symmetric with the signing scripts.

**Reference templates** in `templates/`:

| File | Purpose |
|---|---|
| `gen-brew.sh` | Parse name/version from the release zip, compute sha256, render the formula/cask, write + commit + push into the local tap checkout. `--print` / `--no-push` supported. |
| `formula.rb.tmpl` / `cask.rb.tmpl` | Formula (Go CLI) / cask (GUI) templates — arm64-only, prebuilt. |
| `release-brew.mk` | Minimal Makefile hook (`include` + a few vars). Adds `make brew` / `make brew-print`; the `package` target is never modified. |

**Per-project integration** — vendor the assets into `scripts/` and add the hook:

```makefile
# formula (Go CLI):
BREW_KIND := formula
BREW_DESC := One-line description of the tool
include scripts/release-brew.mk

# cask (notarized GUI): also set
#   BREW_NAME := $(APP)              # if the repo uses APP, not BINARY
#   BREW_APP  := $(APP).app
#   BREW_BUNDLE_ID := com.example.name
#   BREW_MACOS_FLOOR := :tahoe       # only if the app needs newer than :big_sur
```

Overrides for the uncommon cases: `BREW_REPO` (repo slug != tool name, e.g. the
`markdown-viewer` repo ships `mdv`); `BREW_ZIP` (when `VERSION` lacks a leading
`v`, e.g. Tauri's package.json version); `GEN_BREW := ../scripts/gen-brew.sh`
(when the Makefile lives in `app/`). A repo whose release is a versioned-
directory bundle (e.g. `slack-router`) does not fit the flat template and is
hand-maintained instead.

### Formula/cask conventions (from `brew audit` / `brew style`)

- `url` **before** `version`; `version` declared explicitly (the uniform
  `<name>-v<version>-darwin-arm64.zip` naming puts the version mid-string, where
  Homebrew cannot auto-scan it).
- `depends_on arch: :arm64`; formulae add `depends_on :macos`, casks use
  `depends_on macos:` with the floor from `BREW_MACOS_FLOOR` (default
  `:big_sur`; set it in the repo Makefile when the app requires newer, e.g.
  `instant-translate` needs `:tahoe` for the Translation API).
- `desc`: < 80 chars, no leading article, must not start with the tool name,
  write "command-line" not "command line", and casks omit "macOS"/"Mac".
- **A CLI must answer `--version`.** The generated formula's `test` block runs
  `<name> --version`, so a tool offering only a `version` subcommand exits
  non-zero, `shell_output` raises, and `brew test` fails. `brew install` still
  succeeds, which is why this surfaces only after the tool is in the tap — it
  went unnoticed in four tools until 2026-07-26. With cobra, set
  `rootCmd.Version = Version`; keep the flag's output identical to the
  subcommand's and pin both forms in a test (`cmd/version_test.go`).

### Verifying a tap release (no VM required)

Verification runs on the **local build machine** — a clean VM is an optional
extra, never a per-release gate. The notarization ticket is stapled (`.app`) or
checked online by Apple (CLI), so Gatekeeper's verdict does not depend on the
signing keys being absent from the machine.

- **GUI (`.app`)**: extract the shipped zip with `ditto -x -k` (not `unzip`,
  which mangles the seal), then `xcrun stapler validate` and
  `spctl -a -t exec -vv` → `accepted, source=Notarized Developer ID`.
- **CLI**: `spctl -a -t exec` rejects bare binaries by design ("not an app"), so
  check `codesign --verify --strict` + a Developer ID authority. To exercise the
  online notarization check, tag a copy as if downloaded and run it:
  ```sh
  cp dist/<binary> /tmp/qtest
  xattr -w com.apple.quarantine \
    "0181;00000000;manual;00000000-0000-0000-0000-000000000000" /tmp/qtest
  /tmp/qtest --version   # notarized → runs; un-notarized → Gatekeeper kills it
  ```
  (`brew install` strips quarantine, so this manual step is the formula
  equivalent of the cask's quarantined-`.app` Gatekeeper test.)
- **End-to-end after publishing**: `brew install nlink-jp/tap/<name>` (and
  `brew test`), then `codesign --verify` the installed binary to confirm the
  signature survived install.

A clean VM with no signing keys is a stronger one-off proof — used once to
validate the tap approach — but is **not** part of the routine release process.

### `check-org.sh` enforcement

Check 10 verifies every repo's vendored `scripts/gen-brew.sh` (and the templates
+ `release-brew.mk` it carries) matches the canonical copy in
`.github/templates/`. Re-vendor after changing a canonical template.

---

## Release Checklist

Before tagging a release, verify every item:

**Pre-release gates:**

- [ ] All tests pass (`make test` / `go test ./...` / `uv run pytest`)
- [ ] README.md and README.ja.md reflect current features and flags
- [ ] CHANGELOG.md has a dated entry for this version
- [ ] If inside a submodule: on `main` branch (not detached HEAD)
- [ ] For macOS public releases: Developer ID cert + `nlink-jp-notary`
      keychain profile present on the build machine (see §Code Signing
      and Notarization). Builds without them produce ad-hoc-signed
      un-notarized zips that should NOT be published.
- [ ] Release archives follow §Release Archive Standard: name
      `<name>-v<version>-<os>-<arch>.<ext>`, canonical in-archive binary,
      darwin is **arm64-only** zip (no darwin-amd64, no `.dmg`).
- [ ] Skill repos instead ship one `dist/<skill>-vX.Y.Z.zip`: unzip it and
      verify the zip root is the skill folder with `SKILL.md` directly
      inside (ADR-004). Code signing, notarization, and the per-platform
      archive matrix do not apply to skills.

**Release steps:**

1. Commit `chore: release vX.Y.Z`
2. Tag: `git tag vX.Y.Z && git push origin main --tags`
3. `gh release create` (no assets yet)
4. Build all platforms and notarize darwin builds in one shot:
   `make clean && make package`
   - Go CLI projects: the darwin **arm64** zip is signed with Developer
     ID and notarized by Apple (no darwin-amd64); linux `.tar.gz` /
     windows `.zip` pass through unsigned (no platform signing applicable)
   - GUI projects (Wails / Tauri / Swift): the `.app` is deep-signed,
     notarized, and **stapled**, then shipped as a zipped `.app` (no
     `.dmg`). See §Code Signing → GUI app (`.app`) signing for framework
     specifics
   - On a machine without credentials, the script falls back to
     ad-hoc + un-notarized — do not proceed past this step in that
     case
5. Verify the darwin signature + notarization (see §Code Signing →
   Verifying a release). For GUI bundles, `spctl --assess` must
   return `source=Notarized Developer ID` — this is the only release
   gate for GUI distribution
6. Upload zips one by one (`gh release upload`)
7. For tap-eligible tools (Go CLI → formula, notarized GUI `.app` → cask),
   run `make brew` to generate this release's formula/cask from the built
   darwin-arm64 zip and push it to `nlink-jp/homebrew-tap`
   (see §Homebrew Tap Distribution)
8. Update umbrella submodule pointer
9. Update `nlink-jp/.github/profile/README.md` if new tool (keep the tool list
   alphabetical). Tool additions, archivals, and description changes must also
   sync the `nlink-web-site` catalog and the repository About metadata — the
   catalog has multiple surfaces and they drift independently
10. Feed any new reusable engineering knowledge from this work back to
    `nlink-jp/knowledge` (see §Consult and feed the knowledge base)
11. Run `check-org.sh` to verify all green

---

## `check-org.sh` — Organization Health Check

`check-org.sh` is the automated compliance verifier for all series repositories.
It lives at `.github/scripts/check-org.sh` and should be run after releases,
submodule updates, and scaffold creation.

**Usage:**

```bash
.github/scripts/check-org.sh [DEST_DIR]
```

**What it checks (per series):**

| # | Check | What it catches |
|---|-------|-----------------|
| 1 | Remote sync | Local HEAD diverged from `origin/main` |
| 2 | Clean working tree | Uncommitted or untracked files |
| 3 | `.gitignore` coverage | Missing `.claude/settings.local.json` exclusion |
| 4 | No tracked secrets config | `.claude/settings.local.json` in git index |
| 5 | `CLAUDE.md` presence | Missing series-level `CLAUDE.md` |
| 6 | Build conventions | `make build` outputting to root or `bin/` instead of `dist/`; bare binary names in `.gitignore`; missing `dist/` in `.gitignore` |
| 7 | Secret scanning | Tracked files containing likely secrets (service accounts, tokens, API keys) |
| 8 | go.mod local replace | `replace` directives with local filesystem paths (leaks username/directory structure) |
| 9 | HTTPS URLs | `.gitmodules` using SSH instead of HTTPS |
| 10 | Vendored tap-generation assets | A repo's vendored `scripts/gen-brew.sh` (or the formula/cask template or `release-brew.mk`) drifted from `.github/templates/` (see §Homebrew Tap Distribution) |
| 10b | Vendored skill validator | A skill repo's `tests/validate-skill.sh` drifted from `.github/templates/validate-skill.sh` (ADR-006 — edit the canonical, re-vendor into every skill repo) |
| 11 | Submodule pointers | Recorded commit differs from `origin/main` of submodule |
| 12 | Release archive naming *(planned)* | Latest release assets match `<name>-v<version>-<os>-<arch>.<ext>`; darwin is zip & arm64-only (no darwin-amd64, no `.dmg`/`.tar.gz` for darwin) |

**Org-level checks (outside the series loop):**

| Check | What it catches |
|-------|-----------------|
| `knowledge` standalone repo | Missing local clone; `docs/en` / `docs/ja` file sets drifting apart; a document without a catalog row in `README.md` / `README.ja.md` (ADR-015) |

**Exit code:** `0` if all checks pass, `1` if any check fails.

> Check 12 is documented here as the target; that `check-org.sh` check is
> a follow-up task (see §Release Archive Standard).
