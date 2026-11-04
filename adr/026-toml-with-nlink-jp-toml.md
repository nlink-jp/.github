# ADR-026: TOML is read with nlink-jp/toml, strictly

| Field | Value |
|-------|-------|
| Status | **Accepted** — nlink-jp/toml v0.1.0 and v0.1.1 released 2026-11-03; the 27 consumers migrated 2026-11-04, one release each (appendix) |
| Date | 2026-11-04 |
| Binds | organization |
| Decision makers | nlink-jp maintainers |
| Triggered by | Supply-chain reviews that kept finding the same third-party module, `github.com/BurntSushi/toml`, in the organization's Go tools; and, during the migration, the uneven ways those tools handled a key the config does not know |

## Context

The organization ships no code written outside it, and depends only on the
standard library, first-party SDKs and direct REST calls (the rule ADR-024
states for contributors). Yet the Go tools read their hand-written
`~/.config/<tool>/config.toml` through `github.com/BurntSushi/toml`: 27 active
repositories on 2026-11-03, at v1.4.0 to v1.6.0. One repository, mcp-bridge, had
chosen JSON for its configuration only to avoid that dependency, against the
organization's sectioned-TOML convention.

How the tools treated a key their config did not know varied:

- 13 called `MetaData.Undecoded()` and refused the key, each with its own
  message.
- 14 skipped it silently, so a typo left a setting that seemed to do nothing.
- Two tools named keys they had removed (`workspace.workspace_dir` under a
  `[workspace]` table that no longer exists) by searching that list.

The Python tools already read TOML with the standard library's `tomllib`
(Python 3.11+). Only Go had the dependency.

The decoder had to read the TOML 1.1.0 documents users already had, because
BurntSushi v1.6.0 accepts 1.1.0 by default.

## Decision

### 1. Go reads TOML with nlink-jp/toml; Python with tomllib

The organization's Go code decodes TOML with
**`github.com/nlink-jp/toml`** (lib-series) and no other TOML module, directly
or through a wrapper. It is standard library only, reads TOML 1.1.0 in full,
and passes every toml-test v2.2.0 document for 1.1.0. It decodes only; there is
no encoder.

Python code uses `tomllib`. A `tomli` fallback is not kept once a tool's
minimum Python is 3.11.

The library's contract is in its own repository:

- `docs/en/reference.md`: every exported name;
- `docs/en/decoding.md`: which value fits which Go type, how fields match keys,
  and every difference from BurntSushi/toml.

It matches struct fields to keys as BurntSushi/toml does, so that moving a
tool to it does not change what its config file means.

### 2. Hand-written config is read strictly

- **An unknown key is an error that names it** (`toml.UnknownKeysError`, keys in
  document order). An unknown table is listed together with every key beneath
  it, so a key under a removed table is still found by its full name.
- **A removed key is refused by name, with what replaces it**, not reported as
  unknown and never silently ignored. The tool looks for the key's
  `Key.String()` in `UnknownKeysError.Keys` and returns its own message.
- **`AllowUnknownKeys()` is used only where a file is shared with other
  readers**, and the code says so where it passes it. No tool used it at
  migration.
- **Two keys that differ only in case and reach one field are an error.** TOML
  keys are case-sensitive; BurntSushi kept one of the two values without a
  word.

A tool keeps its own wording for these errors. It takes the list from
`errors.As(err, &unknown)` instead of `Undecoded()`.

### 3. A config error is not a fallback to defaults

Code that loads the config "if it loads" (`if conf, err := Load(); err == nil`)
must not carry on with defaults when doing so changes where data is written or
what is deleted.

- Such a caller stops on the error.
- Only commands that do not depend on the config are exempt, such as `version`
  and `help`.
- Strict decoding makes this case common. Before, it arose only from a syntax
  error.

At migration, image-forge's `models` commands would otherwise have worked on
the default models directory: an unknown key discarded the config, and
`models_dir` with it. That was fixed in v0.30.0.

### 4. A change to the library reaches consumers by their own releases

- A fix to nlink-jp/toml is one library release, plus a dependency update and a
  release in each consumer that needs it, as for pathguard (ADR-022). Each
  consumer makes it inside itself (ADR-025 §6).
- The library stays at v0.x until the API has settled across consumers, and then
  becomes v1.0.0.
- An API change is decided in the library's repository, against its reference
  manual. `TestTheReferenceNamesEveryExportedName` fails when an exported name
  has no section there.

### 5. Enforcement

`check-org.sh` gains a check, added in its own commit after this record:

- **No active module requires `github.com/BurntSushi/toml` or
  `github.com/pelletier/go-toml`** directly or as an indirect requirement in its
  own `go.mod`.
- **Exception:** a module that receives one only through another third-party
  dependency is reported, not failed, and is named under Consequences.

A `go.sum` line `github.com/BurntSushi/toml vX/go.mod` that another module's
dependency graph brings in (old grpc versions do) is not a requirement, and is
not checked. It does not reach the binary: `go mod why -m` reports that the main
module does not need it. `go version -m` on a release binary is the evidence.

## Consequences

- **No release binary of the organization's Go tools contains a third-party TOML
  decoder.** At migration, each was checked with `go version -m`.
- **Breaking for the 14 lenient tools.** A config carrying a typo or a leftover
  key now stops the tool with the key named. Each released a new minor version,
  stated in its CHANGELOG: splunk-cli, already past 1.0, released v3.0.0.
  Before release:
  - every shipped example config and the maintainer's deployed configs were
    checked to decode strictly;
  - mail-analyzer's example, which placed the top-level `lang` under `[model]`,
    was corrected.
- **image-forge's ADR-0009 is amended.** It had promised that a leftover
  `[mcp] workspace_root` would be ignored. The key is now refused with ADR-0009
  and `work_dir` named.
- **GUIs that bundle a migrated CLI were rebuilt and released after it**: their
  `CLI_VERSION` pins it (check 16). They were checked on the machine before
  upload.
- **mcp-bridge's reason for JSON is gone.** Whether it moves to TOML is its own
  decision.
- **Remaining third-party dependencies are separate topics:**
  - markdown-viewer reads JSON through `github.com/spf13/viper`, which brings in
    `github.com/pelletier/go-toml/v2`;
  - many CLIs depend on `github.com/spf13/cobra`.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Keep BurntSushi/toml, pinned by `go.sum` | Pinning detects a tampered download; it does not make the code the organization's own, and every update is a new third-party review. The policy is about where code comes from, not whether a version is fixed |
| Vendor BurntSushi/toml's source into an organization module | It would still be code written outside the organization, shipped |
| Switch to pelletier/go-toml | The same dependency in another name |
| A small decoder for the subset our configs use | A subset parser that silently misreads valid TOML is worse than a library. A full TOML 1.1.0 decoder, read-only, is a bounded piece of work, and its conformance suite exists |
| Read 1.0.0 only | BurntSushi v1.6.0 already accepted 1.1.0 by default, so files using its syntax would stop reading |
| Lenient by default, strict as an option | 14 tools had silently ignored typos. Strictness that each tool must remember to switch on is how they came to differ |
| Let each lenient tool stay lenient with `AllowUnknownKeys()` | Considered per tool at migration. The owner chose strict for all (2026-11-04), after the shipped examples and the deployed configs were checked to decode strictly |
| Report only the topmost unknown key | Tools that name removed keys under removed tables could no longer find them; BurntSushi's `Undecoded()` listed both |

## References

- `nlink-jp/toml`: RFP (`docs/en/toml-rfp.md`), reference manual
  (`docs/en/reference.md`), decoding rules (`docs/en/decoding.md`)
- ADR-022: pathguard, the precedent for one organization module and its
  enforcement
- ADR-024: outside contributions, no third-party dependencies
- ADR-025: a project is changed only from inside it; each migration was its
  consumer's own change
- `nlink-jp/knowledge`:
  - testing: test the comparator itself; vendor an external conformance suite
    as data;
  - config-and-io: best-effort config loaders under strict decoding;
  - release-engineering: resumable batch releases.

## Appendix: the migration (2026-11-04)

Already strict: the tool keeps its message, and takes the list from
`UnknownKeysError`. Patch release.

| Tool | Release |
|------|---------|
| ask-gemini-mcp | v0.2.2 |
| ask-llm-mcp | v0.2.2 |
| bigquery-mcp | v0.1.2 |
| claude-usage-lens | v0.9.1 (claude-usage-lens-gui v0.4.1) |
| data-toolbox-mcp | v0.8.6 |
| gem-agent | v0.97.1 |
| gem-usage-lens | v0.2.2 (gem-usage-lens-gui v0.1.8) |
| lagent | v0.23.1 |
| pcap-analyzer-mcp | v0.6.5 |
| task-clock | v0.4.1 (task-clock-gui v0.5.2) |
| video-studio-mcp | v0.6.4 |
| voice-scribe | v0.5.5 |
| voice-studio-mcp | v0.6.4 |

Lenient before, strict now. Minor release; each has a test that an unknown key
is refused.

| Tool | Release |
|------|---------|
| data-analyzer | v0.5.0 |
| gem-cli | v0.5.0 |
| gem-image | v0.5.0 |
| gem-query | v0.6.0 |
| gem-scribe | v0.6.0 |
| gem-search | v0.5.0 |
| gem-summary | v0.3.0 |
| image-forge | v0.30.0: `[mcp] workspace_root` refused by name; an invalid config stops the `models` commands (image-forge-gui v0.13.0) |
| lite-rag | v0.5.0 |
| lite-switch | v0.3.0 (`go 1.23`) |
| llm-othello | not released; migrated on `main` |
| mail-analyzer | v0.4.0 (example config corrected) |
| splunk-cli | v3.0.0 |
| splunk-mcp | v0.4.0 |
