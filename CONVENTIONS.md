# nlink-jp Organization Conventions

This document defines the development policies and conventions shared across all
repositories in the [nlink-jp](https://github.com/nlink-jp) organization.

Every project must follow these conventions from the start.
Series-level and project-level `CONVENTIONS.md` / `CLAUDE.md` files may extend
these rules but must not contradict them.

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
- Japanese translations (`README.ja.md`, `docs/ja/`) must be kept in sync with every
  English change.

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
All projects in this organization follow this convention.

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

Both `lite-series` and `cli-series` manage projects as git submodules.
Submodule checkouts are in **detached HEAD** state by default.
Making commits in detached HEAD state produces orphaned commits that are lost
when you switch to a branch.

**Always check out the main branch before making any changes inside a submodule:**

```bash
cd <umbrella-repo>/<project>
git checkout main
git pull
# make changes, commit, push as normal
```

**After releasing a submodule project, update the umbrella pointer:**

```bash
cd <umbrella-repo>
git submodule update --remote <project>
git add <project>
git commit -m "chore: update <project> submodule pointer to vX.Y.Z"
git push
```

Skipping the pointer update leaves the umbrella repo pointing at a stale commit.
