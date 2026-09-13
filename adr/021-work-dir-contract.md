# ADR-021: The work-directory contract for file-mediated MCP servers

| Field | Value |
|-------|-------|
| Status | **Accepted** — implemented and released across the fleet on 2026-09-13 (voice-scribe was the reference, project ADR-0010) |
| Date | 2026-09-13 |
| Binds | organization |
| Decision makers | nlink-jp maintainers |
| Triggered by | The same parameter carrying three spellings and three meanings across nine servers, and a measurement of the four calling runtimes (2026-09-13) showing that the per-call argument is the only channel all four can supply |

## Context

### The principle already exists; the spelling does not

`knowledge/docs/ja/mcp-server-design.md` §"ファイルで返すなら、出力先は起動フラグ
ではなく呼び出しごとの引数" settles the direction: a server that returns paths takes
the destination as a per-call absolute-path argument, because the only party that
knows which paths the caller can read back is the caller. What it deliberately left
open — "綴りは各サーバーのスキーマ様式に従ってよい" — is what this record closes.

### What the fleet does today

| Server | Parameter | Meaning | Required | Fallback when omitted |
|---|---|---|---|---|
| image-forge | `workspace_root` | root; workspace at `<root>/<workspace_id>/` | no | config `[mcp] workspace_root` |
| voice-studio-mcp | `workspace_root` | same | no | `~/.voice-studio` |
| video-studio-mcp | `workspace_root` | same | no | `~/.video-studio` |
| voice-scribe | `workspace_root` | same (`workspace_id` defaults to `default`) | no | config |
| gem-scribe | `workspace_root` | same | no | config |
| splunk-mcp | `workspace_root` | directory for spilled result files | conditional | none — errors above the inline threshold |
| chrome-pilot-mcp | `workspaceRoot` | directory the file is written into directly | no | `--workspace-root` launch flag |
| pcap-analyzer-mcp | `workspace_dir` | directory analysis output is written under | **yes, every call** | none |
| slack-mcp-extender | `workspace_dir` | base for resolving *input* relative paths; default `dest_dir` | no | none (absolute paths only) |
| data-toolbox-mcp | — | server-owned workspace under config `workspace_dir`; returns `host_work_dir` | n/a | n/a |

Three spellings (`workspace_root` / `workspaceRoot` / `workspace_dir`), and three
distinct roles wearing them: *root that workspaces are created under*, *directory
written into directly*, and *base for resolving caller-supplied relative paths*.
Six of the ten fall back to a server-owned default when the argument is omitted,
and silently: the fallback is not an error, the call succeeds, and the result looks
normal. That is the failure this contract exists to prevent — a destination chosen
by the operator's launch line is readable by the caller only by coincidence.

### What the four runtimes can actually supply (measured 2026-09-13)

A stub stdio MCP server that logs its environment, the `initialize` params, and the
answer to a server-initiated `roots/list` was run under each runtime.

| Runtime | Version | `roots` capability | `roots/list` answer | Env reaching the server | Server process cwd |
|---|---|---|---|---|---|
| Claude Code | 2.1.236 (proto 2025-11-25) | declared, `listChanged: true` | `[file://<project dir>]` — the session scratchpad is **not** in it | `CLAUDE_PROJECT_DIR`, `CLAUDE_CODE_SESSION_ID`; **no scratchpad variable** | project dir |
| ChatGPT Codex | codex-cli 0.154.0-alpha.6.2 (proto 2025-06-18) | **not declared** | `[]` | stripped to `HOME`/`PATH`/`TMPDIR`/`SHELL`/`USER`/`LOGNAME` — **no session variables, and no inherited ones** | session cwd |
| gem-agent | current | not declared | n/a | full environment incl. `GEMAGENT_WORK_DIR`, `GEMAGENT_PROJECT_DIR`, `GEMAGENT_SESSION_ID` | project dir |
| lagent | current | not declared | n/a | same with `LAGENT_*` | project dir |

Three consequences follow, and they are why this record can be written as one rule
rather than a per-runtime table:

1. **`roots` is not a transport.** Claude Code answers with the project directory
   only — never the scratchpad, the one directory it writes to without prompting —
   and Codex answers with an empty list. The protocol's own mechanism cannot carry
   the value for two of the four.
2. **The environment is not a transport.** Codex strips it, so `${...}` expansion
   in a registration entry — the mechanism that put `--workspace-root
   ${GEMAGENT_WORK_DIR}` in chrome-pilot's launch line — reaches only our own two
   runtimes — and there an undefined variable expands silently to the empty
   string, so the flag is passed and the server falls back anyway.
3. **The per-call argument is the only channel all four can supply**, because in all
   four the model is told its own writable directory in the system prompt.

### Defects this state is producing now

- **pcap-analyzer is unusable from Claude Code.** Its `allowed_paths` guardrail on
  `pcap_path` lists the two agent state roots and `~/Downloads`. Claude Code stages
  files under `/private/tmp/claude-<uid>/…`, which is on no list, so a capture the agent
  just staged is rejected. The caller's own work directory is not implicitly trusted
  as an input location.
- **data-toolbox returns `host_work_dir`** under `~/.data-toolbox/<ws>/work` — a path
  no calling runtime's file tools can open. `attach_files` (content inline) is the
  reason this is survivable, not the design saying so.
- **chrome-pilot's launch flag is the only reason `~/.config/gem-agent/mcp.json` and
  `~/.config/lagent/mcp.json` must be two separate files** rather than one shared
  one: it is the single entry whose value is runtime-specific. Two copies of an
  otherwise identical file cost one drift risk per server added or removed.
- **None of our servers is registered with Codex** (`~/.codex/config.toml` carries
  only OpenAI's own entries). Any per-runtime scheme invented now has to be invented
  a third time when they are.

## Decision

### 1. One name, one meaning

The parameter is **`work_dir`** on every server, including those whose schemas are
otherwise camelCase. Its meaning is fixed and is the caller's, not the server's:

> `work_dir` — an absolute path to a directory the **caller** can read back and
> write into. Every file the server produces for this call lands under it, and every
> caller-supplied relative path is resolved against it.

`workspace_root`, `workspaceRoot` and `workspace_dir` are retired as tool-argument
names. `workspace_id` is unaffected: it keeps naming a workspace *within* `work_dir`.

### 2. Resolution order, and no silent default

1. the `work_dir` argument of this call;
2. the request `_meta` key `jp.nlink/work_dir` (a runtime that knows the session's
   work directory sets it on every `tools/call`, schema-blind and therefore
   uniform across servers);
3. **error**. A server-owned default is never used to satisfy a call that returns
   paths. Existing config keys stay as defaults for the server's own CLI and for
   tools that return no paths.

### 3. Where the parameter appears

| Tool shape | Schema |
|---|---|
| always returns paths, **or resolves a caller-supplied relative path** | `work_dir` listed in `required` |
| returns paths conditionally (a threshold, a flag) | optional; `work_dir_required` error when the condition fires. **No server in this fleet is in this row any more** — see below |
| returns no paths and reads no caller-staged file | parameter absent |

The conditional row emptied itself while this record was being applied. Its only
member was splunk-mcp, whose condition was "the result set is too large to
return inline" — and a server cannot know what is too large for a caller it
cannot see. That spill is withdrawn in favour of an explicit `max_rows` cap with
the omission counted, per the owner's decision of 2026-09-06, leaving a sharper
rule behind: **`work_dir` is for a server whose product is a file** — an image,
an audio master, a video, an extracted object — **not for one whose product is
data that could be paged.** Data comes back in the response, capped and counted;
if it needs to be on disk, the calling runtime is what puts it there.

The second half of the first row came out of building the reference
implementation: voice-scribe's `transcribe` returns the transcript in the
response as well as writing it, so by the returning-paths rule alone it would
have been conditional — but it reads the recording from
`<work_dir>/<workspace_id>/`, so without the work directory it cannot even find
its input. Reading and writing are the same requirement.

A server can be on both sides of §3 at once, and the two scribes are: the
transcript **file** is a product (an srt goes to a video player), so `work_dir`
stays required, while the transcript **text** is data, so the response carries
it under an explicit cap with the remainder counted rather than switching to a
preview. Their `inline_threshold` — which dropped the text entirely past 8 KB —
was withdrawn on 2026-09-14 for the same reason splunk's and pcap's spills were
(voice-scribe ADR-0011, gem-scribe ADR-0003). The test of §3 is what the
*product* is, not whether a response happens to be large.

### 4. Validation — a closed list

Every server applies exactly these, in order, and returns a structured
`{code, message, details}` error:

| Check | Error code |
|---|---|
| present after step 2 | `work_dir_required` |
| absolute, no `~`, no `..` segment | `work_dir_invalid` |
| exists and is a directory — **it is not created**; a typo must fail loudly, and the caller's own directory always exists | `work_dir_not_found` |
| writable | `work_dir_not_writable` |
| not a system location (`/`, `/etc`, `/usr`, `/bin`, `/sbin`, `/System`, `/Library`, `$HOME` itself) and not the server's own config or state directory | `work_dir_denied` |

Symlinks are resolved once, and the resolved path is what is validated, used and
returned. Unknown properties are rejected (`additionalProperties: false` plus
`DisallowUnknownFields`); for one release cycle, a rejected property named
`workspace_root`, `workspaceRoot` or `workspace_dir` returns `work_dir_required`
with a message naming the new field, so a stale caller corrects itself in one turn.

### 5. Layout under `work_dir`

- A server with a workspace concept writes under `<work_dir>/<workspace_id>/`.
  The namespace is **shared on purpose**: `voice-studio` writing audio and
  `video-studio` reading it in the same workspace is the media pipeline.
- A server without one writes directly under `<work_dir>`, with the server's
  identity in the filename (`chrome-pilot-screenshot-<ts>.png`,
  `splunk-<sid>.jsonl`) so two servers sharing one session directory cannot collide.

### 6. Every result echoes where it went

A result that carries files carries `work_dir` (resolved, absolute) and, per file,
`path` (relative to `work_dir`) and `abs_path` — image-forge's existing shape. A
caller that had its work directory injected via `_meta` learns the destination from
the result, not from its own request.

### 7. Inputs: no operator allowlist, a blacklist floor, and writes stay inside

The operator allowlists (`allowed_paths`, `allowed_roots`) are deleted, not renamed.
They could not express what they were meant to express: the matcher is a
resolved-path prefix test with no per-repository granularity, so covering the ~105
repositories under one work root means listing `~/works` — or `~`, at which point
the list admits `.ssh`, `.aws` and `.config` and has stopped meaning anything. What
an operator could actually write was a short list of narrow non-project roots, which
is why a capture staged by Claude Code is refused today. Pointwise designation is
what was missing, and `work_dir` is pointwise designation: the caller names one
directory per call.

- **Reads** may name an absolute path outside `work_dir`, except a fixed,
  **in-code** blacklist of credential and agent-control locations: `~/.ssh`,
  `~/.aws`, `~/.config/gcloud`, `~/.gnupg`, `~/Library/Keychains`, `~/.claude`,
  `~/.codex`, `~/.config/{gem-agent,lagent}`, and any `.env`. The list is code, not
  config: a knob here would recreate the hand-maintained model of the runtimes that
  this section removes.
- **The check runs on both spellings of the path — as given, and symlink-resolved —
  against both spellings of every entry.** pcap-analyzer, the first adopter with
  absolute inputs, found why by being driven for real: `~/.ssh/config` on that
  machine is a symlink into a cloud-sync folder, so resolving before comparing made
  the path stop looking like `~/.ssh` and walked past the list. Comparing only the
  unresolved form has the mirror hole — a link planted in an ordinary directory
  steps through it.
- **Writes** land only under `work_dir`. No workflow in this fleet needs a server to
  write anywhere else, and a host write is the persistence channel (`~/.zshrc`, git
  hooks, launchd plists), not a read the caller asked for.
- The blacklist is a **floor, not a boundary**. The next secret file is not on it.
  Bounding what a server process may touch at all is a separate, deliberately
  deferred piece of work — a sandboxing MCP proxy that spawns servers under a
  profile, which is the only mechanism that also reaches the runtimes we do not
  own. Until it exists the operator is running these servers unconfined, which is
  exactly today's posture: measured 2026-09-13, none of the four runtimes confines
  a spawned MCP server (`~/.ssh` readable, `$HOME` writable, children spawnable
  under all four).
- One exception: a server that **transmits a file to an external service**
  (slack-mcp-extender's uploads) takes its input only from under `work_dir`. Its
  output leaves the machine, so "the caller could have read this itself" is not the
  bound that matters.

### 8. The alternative to adopting the contract is returning bytes

A server may keep a server-owned workspace — data-toolbox's container mirror is a
real reason to — but then it **must not return host paths**. It returns content as
MCP content blocks (`attach_files`). Adopt the contract or return bytes; returning a
path the caller cannot open is the one prohibited outcome.

### 9. Runtime obligations

- **gem-agent / lagent** — set `_meta["jp.nlink/work_dir"]` to the session work
  directory on every `tools/call`; keep telling the model the same path; drop
  chrome-pilot's `--workspace-root` launch flag, which makes the two registration
  files identical again. Answering `roots/list` with the two roots the file tools
  are confined to (`project`, `work`) is worth doing for third-party servers, but
  carries nothing for this contract.
- **Claude Code** — the model passes its session scratchpad directory (writable
  without prompts, and the same place its own intermediates go). Nothing else in
  Claude Code can supply it.
- **Codex** — the model passes the session cwd, or a gitignored subdirectory of it
  when the tree must stay clean; `$TMPDIR` is the other writable root. Environment
  and `roots` are both closed, so the argument is the whole mechanism.
- **mcp-tactics** — one sentence, in the skill's own voice, naming `work_dir` and
  the per-runtime value above. A schema the model can satisfy is not the same as a
  model that thinks to satisfy it: without a line that fires at selection time, the
  parameter stays available and unused.

### 10. Enforcement is a test, not a convention

There is no shared Go module across these servers — each is self-contained and the
skeleton is transplanted — so the contract is enforced per repository:

- a transplanted `internal/mcp/workdir` package holding resolution (§2),
  validation (§4) and the error codes, with its own table tests, plus the
  protocol layer's `RequestMeta` accessor that carries `_meta` to handlers.
  **voice-scribe is the transplant source** (project ADR-0010): copy those two
  files, the contract test, and the schema wording for `work_dir`;
- an arch test that walks the registered tool schemas and asserts: no schema
  mentions a retired spelling; every tool whose result type carries a path exposes
  `work_dir`; every schema sets `additionalProperties: false`. A rule
  stated only in prose is re-decided by whoever adds the next tool; a test decides
  it once.

## Consequences

- **Breaking, deliberately and loudly.** Every caller of a renamed parameter fails
  with a named error that says what to send instead; nothing silently writes to a
  default. Nine servers change their tool schemas.
- **The two registration files converge.** With chrome-pilot's launch flag gone the
  gem-agent and lagent `mcp.json` files have no remaining difference, and the
  standing reason to keep them apart disappears.
- **Codex becomes registrable without new invention** — the argument is the whole
  contract, and Codex's stripped environment stops being a blocker.
- **Migration order** (loud, never silent, in between): servers series by series,
  each with tests + README/README.ja + CHANGELOG + release → `mcp-tactics` in one
  commit → runtime `_meta` injection → registration cleanup → knowledge + memory.
- **The knowledge entry is amended, not replaced**: §"ファイルで返すなら…" keeps its
  symptom and reasoning and gains the settled spelling, the measured runtime table,
  and the "adopt the contract or return bytes" rule.
- **Server configuration stops modelling the runtimes.** Two servers' config files
  name `~/.local/state/gem-agent` and `~/.local/state/lagent` by hand today; after
  §7 no server configuration mentions a runtime, and adding a fifth calling runtime
  requires no server change.
- **Servers get smaller, not larger.** Deleted: three operator allowlists and their
  config keys, doctor output and documentation; every server-owned default root.
  Added: one resolution helper and one fixed blacklist, both runtime-free.
- One audit falls out of §8: every data-toolbox result that carries `host_work_dir`.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Keep `workspace_root` as the canonical name (six servers already use it — three renames instead of nine) | It names the server's structure, not the caller's directory, and reads as a lie in the three servers that create nothing under it. Every server is being touched anyway for §2–§4, so the marginal cost of the rename is a string |
| Keep per-server spellings; unify only semantics and validation | The fleet-wide split is exactly what strict decoding turns into a per-server surprise for the model. One name is one thing to remember across ten servers |
| Carry it in MCP `roots` | Measured: Codex declares no `roots` capability and answers `[]`; Claude Code answers with the project directory, never the scratchpad. It cannot carry the value for half the fleet's callers |
| Carry it in the environment (`MCP_WORK_DIR`, or `${GEMAGENT_WORK_DIR}` expansion) | Codex strips the environment; Claude Code exports no session directory. It reaches only the two runtimes that already have `_meta` |
| Default to the server process's cwd — measured to be the caller's project/session directory in all four runtimes | True today only for stdio servers spawned per session, false for anything launchd-managed or remote, and it writes intermediates into a git working copy — the reason gem-agent's `workdir` package exists |
| A session-scoped `set_work_dir` tool instead of a per-call argument | Server-side session state that a reconnect or a restart silently invalidates, and a wasted turn before every workflow |
| `_meta` only, with no argument | Only our own two runtimes can set it; Claude Code and Codex would have no channel at all |
| Keep the operator allowlists and let `work_dir` sit beside them | The allowlist cannot name a project: prefix matching over ~105 repositories means `~/works` or `~`, and `~` admits the very files the list exists to keep out. What it can express is narrow non-project roots — which is why it currently names two runtimes' state directories by hand and refuses a capture Claude Code just staged |
| Keep a narrow allowlist as the boundary and skip the sandboxing proxy | It bounds one tool per server (`load_data`, `pcap_path`, the upload) and nothing else the process does. A process-level bound is a different mechanism at a different timescale; pretending the allowlist is that mechanism is what let the two get conflated in the first place |

## Appendix: the migration, server by server

Twenty-six tool schemas across nine servers, plus one audit.

| Server | Tools | Rename | Beyond the rename |
|---|---|---|---|
| image-forge | 2 | **done** (project ADR-0009) | `required`; the default root and both ways to configure one (`--workspace-root`, `[mcp] workspace_root`) deleted; the model store denied |
| voice-studio-mcp | 4 | **done** (project ADR-0013, amending ADR-0010) | `required`; the `~/.voice-studio` fallback deleted |
| video-studio-mcp | 1 | **done** (project ADR-0008) | `required`; the `~/.video-studio` fallback deleted |
| voice-scribe | 1 | **done** — reference implementation (project ADR-0010; response cap ADR-0011) | `internal/mcp/workdir` + `mcpserver.RequestMeta`; default root deleted; `work_dir_*` codes; contract arch test; retired spellings answered by name. `audio` was relaxed to an absolute path plus the blacklist once pcap-analyzer had settled that shape |
| gem-scribe | 1 | **done** (project ADR-0002; response cap ADR-0003) | the same shape as voice-scribe — a transplant, not a design |
| splunk-mcp | — | **out of scope** | The spill it needed `work_dir` for is gone: a server cannot know the caller's context window, so results are capped with `max_rows` and the omission counted, and file-mediating a large response is the runtime's job (owner's decision 2026-09-06). No work directory, no argument |
| chrome-pilot-mcp | 2 (+1 handler) | **done** (project ADR-0005, amending ADR-0004) | the only camelCase exception falls; the server stops creating the directory; `--workspace-root`, `[workspace] root` and the temp-dir fallback deleted |
| pcap-analyzer-mcp | 12 | **done** (project ADR-0008) | `allowed_paths` deleted, blacklist floor, unknown config keys rejected by name, `_meta` channel, contract tests. Settled the both-spellings rule above |
| slack-mcp-extender | 3 | **done** (project ADR-0003) | `allowed_roots` deleted and the config key rejected by name; `work_dir` *is* the containment policy's only root, built per call; uploads come from inside it, downloads land in it (§7's one exception) |
| data-toolbox-mcp | 8 | **done** (project ADR-0011) | workspaces moved under the caller's `work_dir`, so `host_work_dir` is openable; `workspace_dir` and `allowed_paths` deleted and both rejected by name; container names carry a digest of the work dir |

## References

- `knowledge` `docs/ja/mcp-server-design.md` §ファイルで返すなら、出力先は起動フラグではなく呼び出しごとの引数 — the principle this record spells
- `knowledge` `docs/ja/mcp-server-design.md` §大きなデータをツール引数で渡さない — why file mediation exists at all
- [ADR-015](015-knowledge-repository.md) — consult-and-feed loop
- [ADR-017](017-adr-authoring-conventions.md) — record template and the `Binds` field
- [ADR-003](003-mcp-tactics-skill.md) — `mcp-tactics` owns selection and ordering, `get_usage` owns parameters: each server's own copy of this rule belongs there
