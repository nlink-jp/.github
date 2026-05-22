# nlink-jp Organization Conventions

This document defines the development policies and conventions shared across all
repositories in the [nlink-jp](https://github.com/nlink-jp) organization.

Every project must follow these conventions from the start.
Series-level and project-level `CONVENTIONS.md` / `CLAUDE.md` files may extend
these rules but must not contradict them.

## Architecture Decision Records (ADR)

Organization-wide technical decisions are recorded in [`adr/`](adr/).

| ADR | Status | Summary |
|-----|--------|---------|
| [001](adr/001-gemini3-migration.md) | Accepted | Gemini 2.5 → 3 migration plan (defer until GA) |

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
   | lite-series | Local-first LLM interaction and pipeline tools |
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
   ```
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
	CGO_ENABLED=0 GOOS=darwin  GOARCH=amd64 go build $(LDFLAGS) -o $(DIST_DIR)/$(BINARY)-darwin-amd64  .
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

**Repository structure (Python):**

- [ ] Source code is in `src/<package_name>/` layout
- [ ] `tests/` directory exists with at least one test file
- [ ] `Makefile` has `test`, `lint`, `build`, `clean` targets
- [ ] `pyproject.toml` has `[project.scripts]` entry point
- [ ] `.python-version` specifies the minimum Python version
- [ ] `.gitignore` contains `dist/` and standard Python exclusions

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
- Using separate variables for `build` and `build-all` output dirs (`BIN_DIR` vs `DIST_DIR`).

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

build:
	@mkdir -p dist
	go build $(GOFLAGS) -o dist/$(BINARY) .
	@scripts/codesign-darwin.sh dist/$(BINARY) "$(CODESIGN_IDENTITY)"

build-all:
	... cross-compile lines ...
	@scripts/codesign-darwin.sh dist/$(BINARY)-darwin-amd64 "$(CODESIGN_IDENTITY)"
	@scripts/codesign-darwin.sh dist/$(BINARY)-darwin-arm64 "$(CODESIGN_IDENTITY)"

package: build-all
	@cd dist && for f in $(BINARY)-*; do \
		case "$$f" in *.zip) continue ;; esac; \
		name=$${f%%.exe}; \
		cp ../README.md .; \
		zip -j "$${name}-$(VERSION).zip" "$$f" README.md; \
		rm -f README.md; \
	done
	@scripts/notarize-darwin.sh dist/$(BINARY)-darwin-amd64-$(VERSION).zip "$(NOTARY_PROFILE)"
	@scripts/notarize-darwin.sh dist/$(BINARY)-darwin-arm64-$(VERSION).zip "$(NOTARY_PROFILE)"
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

### Wails / GUI apps

Wails (`shell-agent-v2`, `data-agent`, `csv-editor`,
`mail-analyzer-gui`) and other `.app` bundle projects require a
distinct pipeline:

- `codesign --deep` over the bundle
- An entitlements `.plist` (typically allowing JIT, dyld vars,
  etc. as required by the framework)
- After notarize: `stapler staple <bundle>.app` (works for
  bundles, unlike bare CLI)
- Distribute as `.dmg` or zipped `.app`

A reference template will be added to `templates/` once one Wails
project completes the migration.

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

## Working with Submodules

All series (cli-series, chatops-series, cybersecurity-series, lab-series,
lite-series, util-series) manage projects as git submodules. Submodule
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

**Release steps:**

1. Commit `chore: release vX.Y.Z`
2. Tag: `git tag vX.Y.Z && git push origin main --tags`
3. `gh release create` (no assets yet)
4. Build all platforms and notarize darwin builds in one shot:
   `make clean && make package`
   - darwin zips are signed with Developer ID and notarized by Apple
   - linux/windows zips pass through (no signing applicable here)
   - On a machine without credentials, the script falls back to
     ad-hoc + un-notarized — do not proceed past this step in that
     case
5. Verify the darwin signature + notarization (see §Code Signing →
   Verifying a release)
6. Upload zips one by one (`gh release upload`)
7. Update umbrella submodule pointer
8. Update `nlink-jp/.github/profile/README.md` if new tool
9. Run `check-org.sh` to verify all green

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
| 10 | Submodule pointers | Recorded commit differs from `origin/main` of submodule |

**Exit code:** `0` if all checks pass, `1` if any check fails.
