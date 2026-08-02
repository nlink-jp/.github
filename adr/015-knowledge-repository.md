# ADR-015: Organization Knowledge Base — Compiling Agent Memory into a `knowledge` Repository

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-08-02 |
| Decision makers | nlink-jp maintainers |
| Triggered by | ~138 feedback memories (~300 KB) of cross-project engineering lessons existing only in one machine's local Claude Code project memory |

## Context

Development across the organization's series has produced a large body of
hard-won engineering lessons: the temp-zip notarization pattern for tar.gz
distributions, the absence of a cancel notification in the MCP protocol and
the kill-and-respawn pattern it forces, SwiftUI/AppKit menu-bar pitfalls,
Wails build quirks, Gemini output drift handling, prompt-injection defense
patterns, Podman-on-macOS traps, and dozens more.

Today these lessons live in exactly one place: the Claude Code project
memory on a single development machine. Each memory is a small Markdown
file with a `Why:` (the incident that taught the lesson) and a
`How to apply:` (the reusable pattern). That corpus has three problems:

1. **Single point of failure.** The memory directory is machine-local and
   outside any repository. A disk failure, machine migration, or memory
   consolidation pass can silently destroy knowledge that took months of
   incidents to accumulate.
2. **Single consumer.** Only Claude Code sessions on that one machine can
   recall it. Other agents, other machines, future maintainers, and the
   human maintainer reading GitHub directly all have no access.
3. **No review or history.** Memories are written mid-session without
   review, carry no version history, and mix durable engineering knowledge
   with agent working discipline and point-in-time project facts.

Auditing the corpus, the memories fall into three categories:

| Category | Approx. count | Nature | Example |
|---|---|---|---|
| A. Engineering knowledge | ~90–100 | Reusable across projects and agents | notarize temp-zip pattern; MCP kill-and-respawn |
| B. Agent working discipline | ~25–30 | How the agent should work | commit discipline; Read-before-Edit |
| C. Project facts | ~93 (`project_*`) | Point-in-time state of one tool | versions, release status |

Category B is already substantially encoded in `CONVENTIONS.md`; category C
is legitimately memory-shaped (it describes mutable state, not knowledge).
Category A is the untapped value.

## Decision

**Create a standalone repository, `nlink-jp/knowledge`, holding the
organization's engineering knowledge base as themed bilingual documents
compiled from category-A memories.**

Eight sub-decisions define its shape.

### 1. A dedicated repository, not a directory in `.github`

Knowledge (lessons learned, descriptive) is kept separate from conventions
(rules, prescriptive). The corpus compiles to roughly ten themed documents
in two languages and will keep growing; housing it in `.github` would bloat
the org-profile repository and blur the rule/lesson distinction. The
repository is standalone — it belongs to no series umbrella.

### 2. Thematic compilation, not 1:1 memory export

Memories are merged into themed documents rather than exported file-per-file.
Each entry keeps the proven three-part structure — **symptom → why → how to
apply** — and cites its origin (project and month) in generalized form.
Initial theme map (final grouping decided at compile time):

| Document | Contents (approx. memory count) |
|---|---|
| `release-engineering` | Signing, notarization, Homebrew tap, release zips, versioning (~15) |
| `macos-gui` | SwiftUI/AppKit traps, menu-bar apps, Wails, GUI conventions (~15) |
| `mcp-server-design` | Protocol limits, stdio hygiene, structured errors, skeleton reuse (~10) |
| `llm-integration` | Gemini/genai SDK, output validation, drift, tokens, dedup, audio (~20) |
| `security` | Prompt-injection defense, secrets hygiene, internet-facing checklist (~10) |
| `build-and-packaging` | Makefile patterns, cross-builds, CGO, CI-less operation (~8) |
| `testing` | E2E-before-release, mockability, failure injection, agent harnesses (~6) |
| `containers-and-infra` | Podman on macOS, DuckDB mounts, font ordering (~4) |
| `config-and-io` | Config conventions, OAuth patterns, terminal/CLI IO (~8) |
| `shell-scripting` | Bash trap scope, substitution pitfalls (~4) |
| `embedded` | M5Stack lessons (~3) |

### 3. Scope: category A only

Category B (working discipline) is not compiled here; where a category-B
memory contains a rule `CONVENTIONS.md` lacks, the gap is fixed in
`CONVENTIONS.md` instead. Category C (project facts) stays in memory only.

### 4. Bilingual, per the org docs convention

`README.md` / `README.ja.md` serve as the catalog; documents live in
`docs/en/<theme>.md` and `docs/ja/<theme>.md`. Japanese is the authoring
source (the memories are Japanese); English is kept in sync in the same
commit, per the existing README.md/README.ja.md rule.

### 5. Sanitization gate before anything is pushed

The repository is public. Compiled documents must contain no
environment-specific values: no GCP project IDs, service-account emails,
tokens, hostnames, internal IPs, or absolute local paths. Examples use the
org's safe placeholder conventions. A dedicated sanitization pass over the
full compiled output happens before the first push and before every
subsequent addition.

### 6. Memory remains authoritative for agent recall

The knowledge base does not replace agent memory — recall hints and
agent-specific phrasing stay memory-shaped. After compilation, each ported
memory gains a pointer to its knowledge-base document so future
consolidation passes know the public home exists. New category-A memories
are ported at each subsequent consolidation pass.

### 7. The knowledge loop becomes an organization convention

`CONVENTIONS.md` gains a Development Policy subsection, **"Consult and feed
the knowledge base"**, making the loop mandatory rather than best-effort:

- **Consult before building.** When starting design or implementation work
  in a domain the knowledge base covers (release engineering, macOS GUI,
  MCP servers, LLM integration, …), read the relevant document first —
  the same standing the ADR index already has for technical decisions.
- **Feed back what you learn.** When work surfaces new reusable
  engineering knowledge — an incident, a non-obvious workaround, a pattern
  worth repeating — it is contributed to `nlink-jp/knowledge` as part of
  completing that work, not deferred. The pre-completion / release
  checklist gains a corresponding item ("new knowledge fed back to the
  knowledge repository, if any arose").

This makes the repository self-sustaining: consultation keeps it read,
feedback keeps it current, and the consolidation-pass porting in
sub-decision 6 becomes a safety net rather than the primary channel.

### 8. Standard repository file set

`README.md` / `README.ja.md`, `LICENSE` (MIT, per org convention for new
public repositories), `CLAUDE.md` / `AGENTS.md` (minimal — this repo has no
build), and `CHANGELOG.md`. No Makefile, no tests, no releases: documents
are consumed by reading `main`. `check-org.sh` learns the repo as a
standalone (non-series) repository, as it already does for `.github` and
the tap.

## Consequences

**Positive**

- The lesson corpus survives machine loss and memory consolidation, gains
  git history, and becomes reviewable.
- Any agent, machine, or human can consume it; documents can be referenced
  from series READMEs, ADRs, and future Skills.
- Compilation itself is a quality pass: duplicates merge, stale lessons
  surface, category-B gaps flow back into `CONVENTIONS.md`.

**Negative / accepted**

- Two surfaces (memory + repository) require sync at consolidation passes;
  mitigated by pointers in ported memories.
- Bilingual maintenance doubles writing cost; accepted per existing org
  docs policy.
- Public exposure of internal lessons; mitigated by the sanitization gate,
  and the lessons are generic engineering content by construction (that is
  category A's definition).

## Alternatives considered

- **`knowledge/` directory inside `.github`** — rejected: mixes
  prescriptive rules with descriptive lessons in one repository and bloats
  the org profile repo as the corpus grows.
- **Ship as a Claude Code Skill (skills-series)** — rejected for now: this
  is reference material, not a workflow; a future Skill could load these
  documents as its reference layer, which the standalone repo makes easy.
- **Do nothing (memory only)** — rejected: single point of failure, single
  consumer, no review; the motivating problem.

## References

- Claude Code project memory corpus (local, machine-bound) — the source
  material
- `CONVENTIONS.md` — receives category-B gaps; links the knowledge catalog
- ADR-005 — umbrella standardization (`check-org.sh` repo inventory)
