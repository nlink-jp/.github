# ADR-022: One path judgement for the fleet — nlink-jp/pathguard

| Field | Value |
|-------|-------|
| Status | **Accepted** — pathguard v0.1.0 and v0.2.0 released 2026-09-22; the nine servers of ADR-021 migrated one release each (appendix) |
| Date | 2026-09-22 |
| Binds | organization |
| Amends | [ADR-021](021-work-dir-contract.md) §4 (validation), §7 (inputs) and §10 (enforcement) |
| Decision makers | nlink-jp maintainers |
| Triggered by | The organization audit finding that the nine transplanted copies of ADR-021's credential list compared places as strings on a case-insensitive disk and had drifted from the runtimes' list and from each other; and the owner's observation (2026-09-22) that this is a general path-safety judgement, not a work-directory feature |

## Context

ADR-021 §10 chose transplanting: "there is no shared Go module across these
servers", so voice-scribe's `internal/mcp/workdir` was copied into each server,
and §7's credential list was spelled in each copy. Nine copies later, the audit
found the same defects in all of them, plus some that only one copy had grown:

- **Places were compared as strings.** APFS folds case by default, so another
  spelling of a refused place was a different string and passed:
  `work_dir=~/.SSH`; `GCLOUD/credentials.db` under an accepted `~/.config`;
  `WS.STATE/tokens.json` under the parent of slack-mcp-extender's state
  directory — its OAuth tokens, sent to Slack. Two servers grew identity
  comparisons of their own after reviews broke the name comparison twice
  (chrome-pilot-mcp's `refusedLocation`/`insideByIdentity`); the rest did not.
- **The copies were not the runtimes' list.** gem-agent and lagent declare what
  their sandboxes refuse in `internal/sandbox/lane.go`; the servers' copies
  lacked `~/.kube`, `~/.config/gh`, `~/.azure`, `~/.netrc`, `~/.npmrc`,
  `~/.docker/config.json`, `~/.claude.json`, the shell histories and more.
- **The directory actually used was never judged.** Validating `work_dir` does
  not validate `<work_dir>/<workspace_id>`: `work_dir=~/.config` with
  `workspace_id=gh` is `~/.config/gh`. For data-toolbox-mcp that directory is
  mounted into a container as `/work`. image-forge read caller-named model paths
  without the list at all.
- **One list served two different questions.** A read on this machine and an
  upload that leaves it were judged alike, although §7's own exception says the
  upload's bound is different.

Every one of these is a property of the judgement, not of a server. Fixing
nine copies nine times is how they drifted in the first place.

Two rules stood in the way of one module. §10 said there is none, and several
servers' `CLAUDE.md` said "no external dependencies". The owner settled the
second on 2026-09-22: the rule excludes third-party code, not this
organization's own modules that hold the same rule.

## Decision

### 1. One module, two layers

The judgement lives in **`github.com/nlink-jp/pathguard`** (lib-series),
standard library only:

- `pathguard` — places, the one list, the comparison, and two policies (§3).
  Nothing in it knows about MCP.
- `pathguard/workdir` — ADR-021's contract: resolution (argument →
  `_meta["jp.nlink/work_dir"]` → `work_dir_required`), validation, the error
  codes with `details`, and `CheckBeneath` for directories beneath a validated
  work directory.

A server keeps a thin adapter — reading `_meta` from its protocol layer,
naming its own places (`ServerDir`, or `Place` with its own reason), mapping
`workdir.Error` onto its error type — and **never a copy of the list or of the
comparison**.

### 2. How a place is compared

A place is its deepest existing ancestor-or-self plus the remaining segments,
folded. A path matches when one of its existing ancestors is the same file
(`os.SameFile`) and its remaining segments begin with the place's — and,
always as well, when its name folded the way the disk folds names (APFS: full
and simple Unicode case folding) lies inside the place's. Every hop of a chain
of links is a form of the path and is judged; the targets of links directly
inside a credential or agent-control place are protected too. A path that
cannot be resolved — a chain of links that does not end, a NUL byte, longer
than the system's limit — is refused (`unresolvable_path`). A place without an
absolute path, or an empty or relative home, refuses every call rather than
protect nothing (`unconfigured`, `home_unknown`). With no home given, both
`$HOME` and the account's home are protected.

### 3. Two policies (amends §7)

- **Local** — a read or write on this machine: the credential and
  agent-control places under the home, any `.env` (its templates
  `.env.example`, `.env.sample`, `.env.template` and `.env.dist` are allowed),
  and the server's own places. System places are not in it: they refuse a work
  directory (§4), not a file.
- **Outbound** — a file that leaves the machine: Local plus a file named as a
  secret (`id_rsa` and the other key names, `credentials.json`,
  `*service-account*.json`) and a path that passes through a credential
  directory or file name as whole segments, anywhere — not only under the home
  (except `.claude`, `.gemini` and `.codex`, which also name project
  directories with another meaning).
  slack-mcp-extender's uploads and chrome-pilot-mcp's `upload_file` are
  Outbound.

The list is the runtimes' list: `credentialDirs`, `homeOnlyDirs`,
`credentialFiles` and `credentialNames` in gem-agent's and lagent's
`internal/sandbox/lane.go`. Until the runtimes depend on pathguard, pathguard
holds a copy (`testdata/runtime-lists.json`) and `check-org.sh` holds the three
equal (§6). §7's floor-not-boundary rule is unchanged: the list is still a
floor, and the sandboxing proxy is still deferred.

### 4. Validation (amends §4)

The order is required → invalid → not found → **denied → not writable**: a
refused directory is reported as refused, whatever its permissions. The denied
list is no longer written out per server; it is pathguard's:

- system directories — `/` and `/private/var` exactly, and everything under
  `/bin`, `/sbin`, `/usr`, `/etc`, `/private/etc`, `/System`, `/Library`,
  `/Applications`;
- the home directory itself (exactly);
- the credential and agent-control places;
- the server's own places.

`work_dir_denied` carries `details {work_dir, resolved, reason}` with `reason`
one of `system_dir`, `home_dir`, `sensitive_path`, `server_dir` (or the
server's own reason), `unresolvable_path`, `home_unknown`, `unconfigured`.

### 5. The directory actually used is judged

A server that writes under `<work_dir>/<workspace_id>` judges that directory
with `Resolver.CheckBeneath` at the point of use (`work_dir_denied`, details
`{path, reason}`). A workspace manager takes the check as a **required**
constructor argument and refuses to work without one, so a tool added later
cannot reach a workspace unjudged.

### 6. Enforcement (amends §10)

Transplanting is retired; voice-scribe is no longer a transplant source.
Enforcement is:

- pathguard's own tests, including a benchmark of the worst case;
- each server's adapter and wiring tests (the places it names, the workspace
  check, the direction of each file argument), checked by mutation at
  migration;
- **`check-org.sh`'s pathguard section**: every consumer requires the latest
  pathguard tag; no consumer spells a floor entry in its own non-test Go code;
  and the runtimes' lists equal pathguard's copy, read with `go/ast`
  (`scripts/runtime-lists.go`) so a reformatted declaration neither fails nor
  hides a change.

§10's schema arch test (no retired spelling, `work_dir` wherever a result
carries a path, `additionalProperties: false`) stays as it was.

## Consequences

- **A fix to the judgement is one pathguard release plus a one-line dependency
  update per consumer**, and `check-org.sh` names every consumer left behind.
- **Newly refused across the fleet**: every other spelling of a refused place;
  the runtimes' places the copies lacked; link targets inside credential
  places; unresolvable paths; a workspace directory inside a refused place;
  on upload, secret names and credential names anywhere. **Newly accepted**:
  the `.env` templates.
- **Cost**: a check stats every ancestor of every form, because existence is
  not monotone on this disk (`/.vol/<dev>` against `/.vol/<dev>/<ino>`). About
  2 ms typically; 0.33 s at the worst case measured, a chain of links at the
  path-length cap.
- **The runtimes still hold their own list** until they adopt pathguard;
  `check-org.sh` holds it equal meanwhile. Adoption there also needs a
  measurement of how the Seatbelt profile compares paths, since it matches
  strings.
- **A GUI that bundles a server needs its own release** when the server
  changes (image-forge-gui bundles image-forge).

## Alternatives considered

| Alternative | Why not |
|---|---|
| Keep transplanting and fix each copy | That is how nine copies came to disagree with the runtimes and with each other, and every copy broke the same way. The defects were in the judgement, which a copy duplicates |
| Share only the list, keep the comparison per server | Every bypass the audit found lived in the comparison (string against identity, one spelling against the disk's folding), not in the list |
| Put the judgement in gem-agent's `internal/` packages | Servers cannot import another module's `internal/`, and a runtime and a server release on different schedules |
| Name the module `workdir` | The work directory is one consumer. The same judgement answers reads, uploads, workspace directories and model paths (the owner's point, 2026-09-22) |
| Compare the resolved path only, or the path as given only | ADR-021 §7 already found both holes (a link into `~/.ssh` resolved away from the name; a link planted in an ordinary directory stepping through). Identity plus folded name, on every hop, covers both and the case-insensitive disk |
| Judge uploads by the Local policy | The recipient (Slack, a web page) can send the file anywhere, so "the caller could have read it itself" is not the bound that matters — §7's own exception |

## Appendix: the migration

| Server | Release | Project ADR |
|---|---|---|
| voice-scribe | v0.5.0; v0.5.1 judges the workspace directory; v0.5.2: a refused path gets the same answer whether or not it exists | ADR-0013 |
| gem-scribe | v0.5.0; v0.5.1 judges the workspace directory; v0.5.2: a refused path gets the same answer whether or not it exists | ADR-0004 |
| image-forge | v0.29.0 (also judges caller-named model paths); image-forge-gui v0.12.1 bundles it; v0.29.1 judges an input image before looking for it (image-forge-gui v0.12.2) | ADR-0010 |
| voice-studio-mcp | v0.6.0; v0.6.1: the workspace judges every read | ADR-0014 |
| video-studio-mcp | v0.6.0; v0.6.1: the workspace judges every read, pages are re-verified at the spawn, a `%` path is refused | ADR-0009 |
| data-toolbox-mcp | v0.8.0; v0.8.1: a refused path gets the same answer whether or not it exists, `attach_files` judged | ADR-0012 |
| pcap-analyzer-mcp | v0.6.0; v0.6.1: a refused path gets the same answer whether or not it exists | ADR-0010 |
| chrome-pilot-mcp | v0.9.0 (uploads Outbound) | ADR-0007 |
| slack-mcp-extender | v0.5.0 (uploads Outbound; a file's directory may not be a system directory or the home itself; a refused path gets the same answer whether or not it exists) | ADR-0004 |

The existence sweep of 2026-09-22 (the v0.5.2 / v0.8.1 / v0.6.1 / v0.29.1 releases above) left gaps
that live in pathguard itself — a `..` walk out through an entry of a credential directory, the last
of `Forms` not always being the end of the walk, `work_dir` validated not-found-before-denied (§4),
the cost of preparing the places on every check, hard links into credential directories, Unicode
normalisation. Each server's project ADR lists them under its 2026-09-22 amendment; they are for
pathguard's next release.

## References

- [ADR-021](021-work-dir-contract.md) — the work-directory contract this record amends
- nlink-jp/pathguard — `docs/en/pathguard-rfp.md` (the design, the review rounds and the known limits)
- `knowledge` `docs/{en,ja}/security.md` — identity comparison on a case-insensitive disk
- `knowledge` `docs/{en,ja}/mcp-server-design.md` — the work-directory section
- [ADR-015](015-knowledge-repository.md) — consult-and-feed loop
- [ADR-017](017-adr-authoring-conventions.md) — record template and the `Binds` field
