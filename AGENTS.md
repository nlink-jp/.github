# AGENTS.md — nlink-jp Organization

You are working inside a repository that belongs to the **nlink-jp** organization.

**Read [`CONVENTIONS.md`](CONVENTIONS.md) before writing any code.**
It defines the mandatory rules for every project in this organization.
The sections below summarize the rules that are most commonly missed.

---

## Non-negotiable rules

### Tests are mandatory

> "Tests are not optional or deferred — write them alongside the implementation.
> A feature is not complete until it has tests."

- Write tests in the same commit as the implementation.
- Cover the happy path **and** relevant failure modes.
- Structure code so units can be tested in isolation (pure functions, injected dependencies).

### Documentation must stay in sync

- When behaviour changes, update `README.md` and `README.ja.md` in the same commit.
- Stale documentation is a bug.

### Never use `go build` directly — always use `make`

- **`go build` drops the binary in the current directory**, polluting the working tree
  and causing `untracked content` errors in the parent submodule.
- Always use `make build` (outputs to `dist/`) or `make build-all`.
- `go test ./...` is fine — it produces no stray binaries.

### Commits must be small and typed

Format: `<type>: <short imperative description>`

Common types: `feat`, `fix`, `docs`, `chore`, `test`, `refactor`, `security`

---

## Project structure

This organization uses **series** as umbrella repositories, each managing individual
tool repositories as git submodules.

| Series | Umbrella repo | Tools |
|--------|---------------|-------|
| cli-series | nlink-jp/cli-series | scli, confl-cli, splunk-cli |
| chatops-series | nlink-jp/chatops-series | scat, stail, slack-router, md-to-slack |
| cybersecurity-series | nlink-jp/cybersecurity-series | ioc-collector, product-research, ai-ir |
| lab-series | nlink-jp/lab-series | sai, slack-monitor, magi-system, mail-analyzer, llm-othello, log-analyzer |
| lite-series | nlink-jp/lite-series | lite-llm, lite-rag, lite-switch, lite-eml, lite-msg |
| util-series | nlink-jp/util-series | json-to-table, rex, sdate, csv-to-json, json-to-sqlite, lookup, pptx-to-markdown, json-filter, markdown-viewer, jstats, jviz |

**After releasing a submodule project, always update the umbrella pointer:**

```sh
cd <umbrella-repo>
git submodule update --remote <project>
git add <project>
git commit -m "chore: update <project> submodule pointer to vX.Y.Z"
git push
```

---

## Release checklist (summary)

1. Update `CHANGELOG.md`
2. Commit with `chore: release vX.Y.Z`
3. Tag: `git tag vX.Y.Z && git push origin main --tags`
4. `gh release create` (no assets yet)
5. Build all 5 platforms: `linux/amd64`, `linux/arm64`, `darwin/amd64`, `darwin/arm64`, `windows/amd64`
6. Zip each binary with `README.md`
7. Upload zip files one by one (`gh release upload`)
8. Update umbrella submodule pointer
9. Update org profile README (`nlink-jp/.github/profile/README.md`) if new tool

Full release process: see [`CONVENTIONS.md`](CONVENTIONS.md) and the
[release process memory](../memory/) if available.

---

## Communication language

Use **Japanese** when communicating with the user.
