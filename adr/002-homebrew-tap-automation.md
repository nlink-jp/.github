# ADR-002: Homebrew Tap Distribution & Automation

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-07-12 |
| Decision makers | nlink-jp maintainers |
| Triggered by | Manual Homebrew formula maintenance becoming unsustainable as the tool count grew (~40 macOS tools) |

## Context

nlink-jp ships ~40 macOS tools. macOS releases are Developer ID signed and
Apple-notarized (see ADR / §Code Signing). Distributing them via Homebrew would
let users track updates with `brew upgrade`, but hand-writing a formula/cask for
every release does not scale, and a naive approach risks breaking the one
property that matters most: **notarization must survive installation**.

Two hard constraints shaped the design:

1. **Notarization preservation.** A source-built formula recompiles the tool,
   which strips the Developer ID signature. The tap must install the *already
   notarized* release asset unmodified so Gatekeeper still accepts it. This was
   verified empirically: a cask-installed, quarantined `.app` on a clean VM
   (no signing keys) reports `spctl -a → accepted, source=Notarized Developer ID`.
2. **No checksum/version drift.** A central manifest or cross-repo sweep would
   compute sha256/version separately from the build, inviting drift when asset
   names or versions differ per tool.

The operator is a single maintainer working locally on macOS with no CI.

## Decision

**Distribute via a public tap, [`nlink-jp/homebrew-tap`](https://github.com/nlink-jp/homebrew-tap),
of Apple-Silicon-only prebuilt binaries, generated per-repo at release time.**

- **Prebuilt, never source-built.** Formula/cask install the notarized
  `darwin-arm64` zip as-is (`url` + `sha256` → `bin.install` / `app`).
- **arm64-only.** Consistent with the Release Archive Standard (darwin is Apple
  Silicon only; no Intel, no universal).
- **Distributed generation, not central.** Each repo carries a vendored
  `gen-brew.sh` (canonical in `.github/templates/`, symmetric with the signing
  scripts). At release time `make brew` parses name/version from the just-built
  zip, computes its sha256, renders the formula/cask, and pushes it to the tap.
  Because it reads the exact artifact that ships, sha256/version cannot drift.
- **Minimal Makefile hook.** Repos `include scripts/release-brew.mk` and set a
  few variables; the `package` target is never modified (the highest-risk edit
  surface across ~40 heterogeneous Makefiles is avoided entirely).
- **Eligibility = two classes.** Go CLI → formula; notarized GUI `.app` → cask.
  Python/uv, embedded (M5Stack), and pure-bash tools are excluded — they produce
  no signed single binary, so the tap's core value does not apply; Python uses
  `uv tool install` instead.

## Alternatives considered

- **A standalone Go generator binary** (`brew-formula-gen`). Rejected: it would
  itself need signing, notarizing, and distributing. The task is "sha256 +
  template + git push" — squarely the domain of a vendored bash script, exactly
  like `notarize-darwin.sh`.
- **Central manifest + cross-repo sweep.** Rejected: it decouples generation
  from the build, so checksums/versions drift, and per-tool asset-name
  differences force a complex manifest. Distributed generation makes the drift
  problem structurally impossible.
- **Submit to homebrew-core.** Rejected: core requires source builds (strips the
  signature) and open-source review overhead; a private tap keeps notarization
  intact and control local.
- **Editing each `package` target to emit the formula.** Rejected: mass edits
  across Go/Wails/Swift/Tauri Makefiles risk breaking the notarize order and
  release. The additive `include` hook confines the change to a few lines.

## Consequences

- **Release flow gains one step:** after uploading assets, `make brew` publishes
  the formula/cask (added to the Release Checklist).
- **`check-org.sh` gains check 10:** each repo's vendored `gen-brew.sh` +
  templates + `release-brew.mk` must match `.github/templates/`; re-vendor after
  changing a canonical template.
- **Two documented exceptions:** repo slug ≠ tool name is handled by `BREW_REPO`
  (e.g. the `markdown-viewer` repo ships `mdv`); a versioned-directory bundle
  release (`slack-router`) does not fit the flat template and is hand-maintained.
- **Verification learned:** extract `.app` zips with `ditto` (not `unzip`, which
  breaks the seal); `spctl -t exec` rejects bare CLI binaries by design, so CLIs
  are verified via `codesign --verify` + Developer ID authority, while casks
  (which keep the quarantine xattr) are the true Gatekeeper test.

## References

- `.github/templates/gen-brew.sh`, `formula.rb.tmpl`, `cask.rb.tmpl`, `release-brew.mk`
- `.github/tests/gen-brew.test.sh`
- CONVENTIONS.md §Homebrew Tap Distribution
- `_wip/homebrew-tap-automation/` (RFP + Phase 2 rollout plan)
