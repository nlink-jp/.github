#!/usr/bin/env python3
"""Battery for the guard-recursive-write hook: real commands, expected verdict.

Run against the canonical copy in this directory:

    python3 .github/claude-code/guard-recursive-write-test.py

install-claude-guards.sh runs this before installing, so a guard that has
been edited into uselessness cannot reach a machine.
"""
import json, os, subprocess, sys

HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "guard-recursive-write.py")

# (command, should_block)
CASES = [
    # The actual accidents.
    ("gofmt -w . && go test ./... 2>&1 | tail -3", True),
    ("gofmt -w .", True),
    ("gofmt -w . && go build ./...", True),
    # Same class, other tools.
    ("sed -i '' 's/a/b/' *.go", True),
    ("sed -i.bak 's/a/b/g' src/main.go", True),
    ("prettier --write .", True),
    ("prettier --write src/", True),
    ("eslint --fix .", True),
    ("black .", True),
    ("black", True),
    ("isort .", True),
    ("ruff format", True),
    ("ruff check --fix .", True),
    ("shfmt -w scripts", True),
    ("goimports -w internal", True),
    ("clang-format -i src/x.c", True),
    # Absolute targets are the point of the guard: allowed.
    ("gofmt -w /Users/you/src/example-org/some-project", False),
    ("gofmt -w ~/src/example-org/some-project", False),
    ("sed -i '' 's/a/b/' /tmp/x.go", False),
    ("prettier --write /abs/path/file.ts", False),
    ("black /abs/pkg", False),
    # Anchored by an absolute cd: allowed.
    ("cd /Users/you/src/example-org/some-project && gofmt -w .", False),
    ("cd /abs/repo && ruff format", False),
    # Read-only or module-scoped: never blocked.
    ("gofmt -l .", False),
    ("go fmt ./...", False),
    ("go test ./...", False),
    ("go build ./...", False),
    ("cargo fmt", False),
    ("ruff check .", False),
    ("eslint .", False),
    ("git status --short", False),
    ("make build", False),
    ("grep -rn 'foo' .", False),
    ("sed 's/a/b/' file.go", False),          # no -i: prints, does not write
    ("ls -la", False),
    ("cd relative/dir && gofmt -l .", False), # relative cd but read-only cmd
    # Relative cd does NOT anchor a dangerous command.
    ("cd some/dir && gofmt -w .", True),
]

failures = []
for cmd, want_block in CASES:
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd}})
    r = subprocess.run([sys.executable, HOOK], input=payload, capture_output=True, text=True)
    if r.returncode != 0:
        failures.append((cmd, f"hook exited {r.returncode}: {r.stderr.strip()[:120]}"))
        continue
    blocked = False
    if r.stdout.strip():
        try:
            out = json.loads(r.stdout)
            blocked = out["hookSpecificOutput"]["permissionDecision"] == "deny"
        except Exception as e:
            failures.append((cmd, f"unparsable output: {r.stdout[:120]} ({e})"))
            continue
    if blocked != want_block:
        failures.append((cmd, f"blocked={blocked}, want {want_block}"))

print(f"{len(CASES) - len(failures)}/{len(CASES)} cases behaved as expected")
for cmd, why in failures:
    print(f"  FAIL  {cmd!r}: {why}")
sys.exit(1 if failures else 0)
