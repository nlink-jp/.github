# ADR-003: MCP Tactics Skill — A Cross-Cutting Selection Layer for Our MCP Servers

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-07-26 |
| Decision makers | nlink-jp maintainers |
| Triggered by | 15 in-house MCP servers, each perfectly self-describing, with no document anywhere saying *which one to reach for* or *in what order* |

## Context

The organization ships **15 MCP servers** (8 in cybersecurity-series, 7 in
util-series) plus **2 MCP proxies** (`slack-mcp-extender`, `mcp-guardian`).
Documentation for them exists at two altitudes, and both are in good shape:

| Altitude | Surface | State |
|---|---|---|
| Per-tool reference | Each server's `get_usage` tool + its MCP server instructions — parameters, job lifecycle, error-recovery table | Complete |
| Per-repo catalogue | `profile/README.md` — one paragraph per repo, with "the offline sibling of asn-lookup"-style cross-references | Complete |

What does not exist anywhere is the altitude **above** both: given a situation,
*which server, in what order, and what must not be done*. An agent handed a
suspicious IP address has to rediscover from scratch that `asn-lookup`,
`tor-exit-lookup`, and `icloud-relay-lookup` answer offline while
`abuse-lookup` spends a metered daily quota, and that `urlscan-lookup`'s
`scan_url` **touches the target** whereas its `search` does not.

That last distinction is the expensive one. The failure mode is not an agent
picking a slightly suboptimal tool — it is an agent silently escalating from a
passive lookup to an active one and alerting the party under investigation.
Nothing in the current documentation set ranks the servers along that axis.

## Decision

**Add one Claude Code Skill, `mcp-tactics`, to `skills-series`: a router whose
`SKILL.md` is a set of decision tables, with per-domain playbooks under
`references/`.**

Three sub-decisions define its shape.

### 1. A Skill, not a document

A document under `.github/docs/` is read by humans who go looking for it. A
Skill is loaded by the agent *at the moment the task matches its description* —
which is the only time a tactics book is useful. The consumer here is an agent,
so the artifact must live in the agent's discovery path.

### 2. Selection and ordering only — never parameters

The Skill records **which server, in what order, under what constraint, and
what the pitfalls are**. It does **not** restate arguments, return shapes, or
error codes: those belong to `get_usage`, which is versioned with the server
that owns it and therefore cannot drift.

This is a direct application of the two-surface catalogue lesson: duplicated
descriptive prose rots. The facts the Skill is allowed to carry are the ones
that change only when a server is added or removed — server name, tool names,
offline/online, credential requirement, quota class, prerequisite setup — plus
the standing instruction to call `get_usage` before first use of any server.

### 3. Escalation doctrine as the organizing principle

The tables are ordered by observability rather than by series or by repo:

1. **Offline** — answered from a local cache; nobody observes the query
   (`asn-lookup`, `mac-lookup`, `tor-exit-lookup`, `icloud-relay-lookup`)
2. **Third-party query** — a registry, resolver, or reputation service sees it
   (`whois-lookup`, `doh-lookup`, `abuse-lookup`, `urlscan-lookup search`)
3. **Target contact** — the subject of the investigation can notice
   (`urlscan-lookup scan_url`)

Always exhaust tier 1 before tier 2, and enter tier 3 only deliberately.

### Scope

MCP servers only. In-house CLI tools (`eml-to-jsonl`, `mail-analyzer`, `gem-*`,
`nlk`, …) participate in the same investigations but are out of scope for this
Skill; a separate CLI tactics artifact can follow if the need proves real.

## Consequences

- One more surface to update when an MCP server is added, removed, or gains a
  tool — mitigated by keeping the entries to fact-shaped rows and by a
  structural validator (`make check`) that fails on a broken reference link or
  malformed frontmatter.
- `skills-series` gains its first multi-file skill, so its
  "skills are not code — no build, no tests" gotcha is amended: structure is
  now checked even though behaviour still is not.
- The Skill is a *selection* layer with no runtime authority. It cannot enforce
  the escalation doctrine; enforcement, where it is needed, remains
  `mcp-guardian`'s job (tool masking, audit receipts).

## Alternatives considered

| Alternative | Why not |
|---|---|
| `.github/docs/{en,ja}/mcp-tactics.md` only | Not in the agent's discovery path; would be read only when a human already knew to look |
| Skill **and** `docs/` copy | Two copies of the same prose at the same altitude — the exact drift this ADR is designed to avoid |
| A "when to use me" section in each server's own `README`/`get_usage` | Each server can only argue for itself; no single surface can compare siblings or express a cross-server chain |
| One Skill per domain (osint / media / data) | Three descriptions competing to trigger, and the cross-domain chains (pcap → IP lookups) have no home |

## References

- **Amended by [ADR-018](018-mcp-observability-tiers.md)** (2026-08-08) — the
  three tiers below become four, tier 1 is widened from "local cache" to "no
  external observer", and the "every server ships `get_usage`" instruction
  becomes conditional
- [CONVENTIONS.md](../CONVENTIONS.md) — documentation structure, ADR process
- [skills-series](https://github.com/nlink-jp/skills-series) — implementation
- [mcp-guardian](https://github.com/nlink-jp/mcp-guardian) — runtime governance, the enforcement counterpart
