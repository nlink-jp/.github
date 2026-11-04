# ADR-028: One Release Kit, Pinned by Version — No More Copies of Templates or Makefile Recipes

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-11-04 |
| Binds | organization |
| Decision makers | nlink-jp maintainers |
| Triggered by | The owner's judgement, while settling ADR-027, that maintaining copies is a loss in itself — the skill validator first, then every vendored release script and recipe — and measurements taken the same day of what is copied, how the copies differ, and how a pinned Go tool behaves |

## Context

**What is copied.** Measured on 2026-11-04 over the live repositories
(archived ones excluded), 100 repositories hold 491 copies of files from
`.github/templates/`. They include Go command-line tools and servers, Swift
apps, a Wails app, and the nine skill repositories.

| File | Copies | Kept equal by |
|---|---|---|
| `gen-brew.sh`, `release-brew.mk` | 90 each | check 10 |
| `codesign-darwin.sh` | 71 | nothing |
| `notarize-darwin.sh` | 71 | check 10 |
| `formula.rb.tmpl` | 70 | check 10 |
| `codesign-darwin-app.sh` | 20 | nothing — excluded as "intentionally diverging" |
| `notarize-darwin-app.sh`, `verify-app-zip.sh`, `cask.rb.tmpl` | 20 each | check 10 |
| `validate-skill.sh` | 9 | check 10b |

CONVENTIONS also prescribes Makefile recipes that each repository copies into
its own `Makefile`: the signing calls in `build`, the archive loop in
`package`, and `verify-release`. These copies have already drifted into
variants. Across the 99 root Makefiles, `verify-release` exists in 27
byte-distinct forms (21 of them unique to one repository), and `package` in
22. Checks 15, 17, 18 and 19 look inside these recipes for specific strings.

**What the copies have cost.**

- **A defect is copied with the file.** In 2026-09 the CLI `verify-release`
  recipe was fail-open in 59 repositories: `|| true` absorbed a `&&` chain,
  and the gate accepted three of the five failing states. The fix took a
  59-repository sweep. The sweep still missed one repository that already
  existed, because both the converter and check 15 looked for the fix's
  marker (`exit $$rc`) anywhere in the Makefile, and that repository had the
  marker in another target.
- **The checks run after the release.** Checks 10 and 10b compare copies when
  `check-org.sh` runs, the last step of the release checklist.
- **A copy's meaning depends on where it sits.** `validate-skill.sh` treats
  the parent of its `tests/` directory as the repository root, so the
  bundled-skill layout in CONVENTIONS had to be placed around it.
- **Every change is a sweep** across up to 90 repositories.
- **Most behaviour is untested.** `gen-brew.sh` has a test
  (`tests/gen-brew.test.sh`), and two exercise scripts drive repositories'
  release gates. The signing and notarization scripts and the skill validator
  have no tests.
- **The one sanctioned divergence is not one.** Check 10 skips
  `codesign-darwin-app.sh` because GUI repositories "intentionally diverge".
  All nine differing copies have the canonical's code and differ only in
  comments. A file with no reason to vary went unwatched.

ADR-022 already retired copying for one judgement (pathguard's credential
list): one module, consumers on a checked version, no copies.

**What ADR-006 required, and what was measured against it.** ADR-006 kept
copies so that a standalone clone checks itself offline, without a mutable
remote source. Measured on 2026-11-04 with an existing nlink-jp module:

- `go run <module>/<cmd>@<version>` contacts the module proxy on every run,
  and fails with `GOPROXY=off` ("loading deprecation … module lookup
  disabled").
- A `tool` directive (`go get -tool`, run as `go tool <name>`) runs with
  `GOPROXY=off` once the module is cached. Its content is pinned by `go.sum`
  and the checksum database.
- **A `tool` directive in a product's own `go.mod` changes the product.** The
  directive needs `go 1.24` or later. `go get -tool` raised a consumer's
  `go` line (1.22 → 1.24, and 1.24 → 1.26.2). Building the same code under
  the raised line changed the binary's `DefaultGODEBUG` (TLS and x509
  defaults among them). Six repositories that hold copies are below 1.24
  today. Apart from the `go` line, the directive left the product's
  dependency list and its `go version -m` dependencies unchanged.
- **The same directive in a separate module leaves the product alone.** In a
  small module of its own (its own directory and `go.mod`), run as
  `go -C <dir> tool <name>`, it left the product's `go.mod`, `go` line and
  `./...` untouched, and it ran with `GOPROXY=off`. A `go.mod` that holds only
  a tool, placed at a repository root, makes `go test ./...` and `go vet
  ./...` fail with "no packages".

## Decision

**1. One release kit.** A single Go module in lib-series holds the behaviour
of every template, as subcommands of one command:

- skill validation
- code signing of a binary and of an `.app`, with optional entitlements
- notarization of a zip and of an `.app`
- app-zip verification
- Homebrew formula and cask generation, and the tap release
- release archive packaging and `verify-release`

The templates it fills (formula, cask, entitlements) are embedded in it. It
uses the standard library only. It calls the OS tools (`codesign`, `xcrun`,
`ditto`, `gh`) through an injected runner, so every gate's behaviour is tested
without signing. Its RFP surveys the existing variants of each recipe.
Every difference becomes either an explicit option of the kit or is named as
drift and dropped. The RFP also settles the kit's name and interface.

**2. Used by version, from a module of its own.** Each repository in scope
pins the kit in a small module of its own, in its own directory. That module
holds only the kit's `tool` directive, and Makefiles call
`go -C <dir> tool <kit> …`. The product's `go.mod`, `go` line and
dependency graph are never touched. Go, Swift and skill repositories work
alike, and none of them gains a root `go.mod` it does not build. The RFP
names the directory; the name must not collide with an existing package
directory. A Makefile keeps its own variables and the calls; recipe bodies
live in the kit.

**3. Inputs are explicit.** The kit takes what it works on as arguments: the
skills root, the binary, the archive, the version. Nothing derives meaning
from where a file sits.

**4. Scope: the repositories that do what the templates did** — sign or
notarize darwin artifacts, generate tap entries, or ship a skill.
Repositories that do none of these are not bound until they start: libraries,
Python packages published elsewhere, firmware, and the kit itself, which
releases with its own gates as a Go program.

**5. check-org checks the version, the absence of copies, and the calls.**
For every live repository in scope:

- **Version.** The kit module is at or above a **floor** version recorded in
  this repository. The floor is raised when a fix must reach every
  repository — a gate that fails open, a signing or security defect — not on
  every kit release.
- **No copies.** The repository holds none of the former template files.
- **Calls.** Each gate its release relies on is called through the kit, and
  no call's exit status is swallowed (no `|| true`, no `-` prefix, no pipe
  into `head`). This shape check replaces the string checks that 15, 17, 18
  and 19 make inside recipes.

The exercise scripts stay in this repository and keep driving each
repository's own Makefile: the kit's tests prove the gates, and the exercise
proves that a repository's release actually reaches them.

**6. Migration.**

- The kit is a new project and goes through its RFP; this record does not
  create it.
- Once the kit is released, this repository rewrites every CONVENTIONS text
  that prescribes a copy:
  - the scaffolds and the Makefile templates
  - signing and notarization integration
  - GUI app signing, including its reference templates and the new-app
    steps
  - §Homebrew Tap Distribution
  - the release archive standard
  - the release checklist step that names `verify-app-zip.sh`
  - the bundled-skill section
  - the check-org check table

  It also adds the new checks.
- Each repository then moves to the kit as its own change — carrying out an
  organization decision inside each project (ADR-025) — at its next release
  or in a sweep.
- Before a repository's copies are removed, its move is proven mechanically:
  - the kit's archives match the old recipes' archives in names and
    members;
  - the exercise script shows the new gates rejecting the same states.
- Until a repository has moved, checks 10 and 10b still apply to it.
- When no live repository holds a copy, `templates/` loses the copied files,
  checks 10 and 10b and the recipe-string checks are removed, and holding a
  former template becomes a failure.

## Consequences

- A fix ships once in the kit and reaches each repository as a one-line
  version bump. Raising the floor makes the urgent ones mandatory. That
  bump is still a sweep across about 100 repositories, but of one line each,
  with nothing to merge.
- A recipe defect is no longer copied into the next repository scaffolded
  from an old one, and the gates' behaviour is tested in one place before any
  release uses it.
- The floor itself is still checked by check-org, after release. What moves
  before release is the gate's behaviour — tested in the kit — not the check
  that a repository uses a recent kit.
- Every release and every skill check depends on Go and, on first use, on the
  module proxy. Release machines already have both. A standalone clone of a
  skill repository now needs Go, where it needed only bash.
- The kit is on the critical path of every release. A broken kit release
  does not spread by itself, because a repository moves only when it bumps.
- ADR-002 rejected a standalone generator because it would need its own
  signing, notarization and distribution. A tool run through `go -C … tool` is
  built from source on the machine that runs it, so it needs none of them.
  ADR-002's other choice — not to edit dozens of differing Makefiles — is
  given up deliberately: those Makefiles already differ (27 forms of
  `verify-release`), and the differences are where defects hide.
- To be measured in the kit's Phase 0:
  - that Swift builds ignore the kit's module directory
  - how the Wails layout (`app/go.mod`) and slack-router's `build-tools/`
    take the kit
  - what happens in repositories that keep a Go module cache inside their
    checkout

## Alternatives considered

| Alternative | Why not |
|---|---|
| Keep copies, kept equal by check-org (ADR-006, ADR-002) | The copies create the drift the checks find after release; a fail-open recipe reached 59 repositories, and a marker-based check missed one |
| `go run <module>@<version>` from the Makefile | Contacts the proxy on every run and fails offline (measured) |
| Point `GOPROXY` at the local module cache | Works offline, but it is a per-Makefile environment trick that records no version anywhere check-org can read |
| The `tool` directive in the product's own `go.mod` | Raises the product's `go` line, which changes its runtime defaults (measured); six repositories are below the directive's own minimum |
| A tool-only `go.mod` at the root of Swift and skill repositories | `go test ./...` and `go vet ./...` fail there, and the root then looks like a Go product it is not |
| A Homebrew-installed binary | Machine state with no per-repository pin; check-org cannot see which version a repository uses |
| Put the module in `nlink-jp/.github` | A Go module path element may not begin with a dot (`go get` refuses it) |
| Require the latest kit, as pathguard does | With about 100 consumers, every kit release would turn check-org red until every repository bumps; a floor separates urgent fixes from routine releases |
| Replace only the skill validator | The same reasoning holds for the release scripts and recipes, with ten times the copies; the owner chose the full scope |
| A git submodule of `templates/` | Submodules inside submodules for every clone, and still a copy pinned by commit rather than by version |

## References

- [ADR-002](002-homebrew-tap-automation.md) — tap automation; its vendoring of the tap assets is superseded, release-time generation stands
- [ADR-006](006-skill-validator-vendoring.md) — superseded
- [ADR-022](022-pathguard.md) — the first copies retired for a versioned module
- [ADR-024](024-external-contributions.md) — no third-party dependencies
- [ADR-025](025-change-a-project-only-from-inside-it.md) — how the migration is carried out
- [ADR-027](027-mcp-tactics-scope-and-bundled-skills.md) — bundled skills, whose layout the validator's placement constrained
- `scripts/check-org.sh` checks 10, 10b, 15, 17, 18, 19; `scripts/exercise-release-gate.sh`, `scripts/exercise-app-zip-gate.sh`; `tests/gen-brew.test.sh`
