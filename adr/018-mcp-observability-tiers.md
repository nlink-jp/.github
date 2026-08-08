# ADR-018: MCP Observability Tiers — A Fourth Tier for Contact From Our Own Infrastructure

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-08-08 |
| Binds | organization |
| Decision makers | nlink-jp maintainers |
| Triggered by | `chrome-pilot-mcp` shipping a tool surface that contacts a URL from our own IP with our own browser — strictly more exposing than `urlscan-lookup scan_url`, which ADR-003 named the ceiling of the escalation ladder |

## Context

ADR-003 ranked the MCP fleet by **who can see that you asked**, in three
tiers, and made the top one `urlscan-lookup scan_url`: the party under
investigation notices a visit. That was accurate for a fleet of 15 servers
whose only target-touching capability was "urlscan sends *its* browser".

The fleet is now 19 servers plus 2 proxies. Two of the four additions since
ADR-003 change the picture:

- **`chrome-pilot-mcp`** (v0.3.1) drives the Chrome installed on this
  machine over CDP. `navigate_page` — and any tool that causes a resource
  load — contacts the site **from our own IP address, with our own browser
  fingerprint, under whatever profile is loaded**. Against a target under
  investigation that is not the same act as a urlscan scan; it is the act
  urlscan exists to avoid. The three-tier model has no row for it, so the
  ladder's stated ceiling sits below its most exposing tool. A doctrine that
  tops out too low does not merely omit a case — it teaches that nothing is
  worse than tier 3.
- **`splunk-mcp`** (v0.1.0) queries our own Splunk. No external party
  observes it, but it is not offline either: tier 1 was written as "answered
  from a local cache", which excludes it by wording rather than by risk.

A second, smaller drift surfaced in the same review. ADR-003's standing
instruction — call a server's `get_usage` before first use — was recorded in
the Skill as *"Every server ships one."* Three do not: `ask-gemini-mcp` and
`ask-llm-mcp` expose a single prompt-forwarding tool each, and
`chrome-pilot-mcp` deliberately mirrors upstream `chrome-devtools-mcp`'s tool
schemas so existing agent usage patterns transfer. A load-bearing instruction
stated as universal, with three counterexamples, sends an agent looking for a
tool that is not there.

## Decision

**1. Four tiers, ranked by who observes the query.**

| Tier | Who observes |
|---|---|
| 1 — no external observer | Nobody outside our own machine or our own infrastructure |
| 2 — third party | A registry, resolver, or reputation service |
| 3 — target contact, by proxy | The target sees a visit **from urlscan.io** |
| 4 — target contact, from us | The target sees a visit **from our own IP, our own browser** |

Tier 1 is widened from "answered from a local cache" to "no external
observer", which admits `pcap-analyzer` (local container, no network) and
`splunk-mcp` (our own telemetry) without weakening what the tier promises.
Tier 3 is unchanged in membership and gains the qualifier that makes tier 4
legible: the contact happens through someone else's infrastructure.

Exhaust tier 1 before 2, enter tier 3 only as a stated decision, and treat
tier 4 as a decision to justify in writing — for a target under
investigation, tier 3 answers the same question without attribution.

**2. `mcp-tactics` covers every in-house MCP server, not only investigative
ones.** ADR-003 scoped the Skill to MCP servers and organized it around
investigation; `chrome-pilot-mcp` is a development and automation server that
happens to carry the fleet's highest-observability capability. The selection
criterion is therefore restated: a server belongs in the doctrine when it
*can* contact a party under investigation, regardless of what it is for.

**3. The `get_usage` instruction becomes conditional and names its
exceptions.** Most servers ship `get_usage` and it stays the authoritative
source for parameters, job lifecycle, and error recovery. Where a server does
not, its `tools/list` descriptions are the reference. The three current
exceptions are named in the Skill so the absence reads as expected rather
than as a broken server.

## Consequences

- The Skill's doctrine table, server index, decision table, and standing
  cautions all change, and two reference playbooks are added
  (`log-search.md`, `browser.md`). Released as `mcp-tactics` v0.2.0.
- `chrome-pilot-mcp`'s startup-only `--allow-hosts` / `--block-hosts` become
  the enforcement counterpart of tier 4, in the same relationship
  `mcp-guardian` has to the ladder as a whole (ADR-003 §Consequences): the
  Skill selects, the operator's configuration constrains. A
  `host_not_allowed` error is the policy working, not an obstacle.
- Whether `get_usage` should be **required** of new in-house MCP servers is
  left open. This record documents the exceptions rather than outlawing them;
  `chrome-pilot-mcp`'s reason (upstream schema compatibility) is a real
  design constraint, not an oversight, and a blanket rule would have to
  answer it.
- The fourth tier has no mechanical enforcement in the Skill, same as the
  first three. An agent that ignores it is not stopped by anything in this
  repository.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Record this in `mcp-tactics`' own project log (`docs/{en,ja}/adr/`) per ADR-017's decision tree | The tree's first question is "does this constrain other projects?" — and the observability ladder is a cross-server operating policy for every agent session against the whole fleet, not one skill's internals. It is the same ground on which ADR-003 stayed in this log while the five single-skill design records (007–011) moved out. The Skill is where the policy is *published*, not what it binds |
| Leave the doctrine at three tiers and add a caution about `chrome-pilot` | The caution would sit outside the ranking that the doctrine exists to express. The failure mode ADR-003 was written against is silent escalation; an escalation path absent from the ladder is exactly the one taken silently |
| Fold `chrome-pilot` into tier 3 alongside `scan_url` | It erases the distinction that matters — whether the visit is attributable to us. Two acts with different consequences in one row is a ranking that has stopped ranking |
| Omit `chrome-pilot-mcp` from the Skill, as out of scope for an investigation tactics book | Scope by intended purpose, when the risk follows capability. An agent already holding a suspicious URL and a browser tool will not consult a document that declined to mention the browser tool |
| Drop the `get_usage` instruction, since it is not universal | It is right for 16 of 19 servers and is the mechanism that keeps parameters out of the Skill (ADR-003 §2). Naming three exceptions costs one sentence |

## References

- [ADR-003](003-mcp-tactics-skill.md) — the Skill and the original three-tier
  doctrine this record amends
- [ADR-017](017-adr-authoring-conventions.md) — placement decision tree and
  the `Binds` field applied above
- [mcp-tactics](https://github.com/nlink-jp/mcp-tactics) — implementation
- [chrome-pilot-mcp](https://github.com/nlink-jp/chrome-pilot-mcp) — host
  allow/block lists, the tier 4 enforcement counterpart
- [splunk-mcp](https://github.com/nlink-jp/splunk-mcp) — the tier 1 addition
