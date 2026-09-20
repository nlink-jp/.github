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
    # swift-format is one tool with three spellings: `swift-format`, SwiftPM's
    # two-word `swift format`, and either behind `xcrun`.
    ("swift-format -i -r .", True),
    ("swift-format --in-place --recursive .", True),
    ("swift format --in-place --recursive .", True),
    ("swift format -i -r Sources Tests", True),
    ("/usr/bin/swift format -i -r .", True),
    ("xcrun swift-format -i -r .", True),
    ("xcrun swift format --in-place --recursive Sources", True),
    ("xcrun --toolchain swift swift-format -i -r .", True),
    ("swift format --in-place --recursive /abs/Sources /abs/Tests", False),
    ("xcrun swift-format -i -r /abs/Sources", False),
    ("cd /abs/repo && swift format --in-place --recursive .", False),
    # `xcrun` is seen through for every tool, not only this one.
    ("xcrun clang-format -i src/x.c", True),
    ("xcrun --find swift-format", False),
    ("xcrun --find swiftformat", False),      # prints a path; launches nothing
    ("xcrun -f black", False),
    ("xcrun --sdk macosx --show-sdk-path", False),
    ("xcrun simctl list", False),
    # The subcommand word is not a path. `format` is the default and rewrites;
    # `lint` and `dump-configuration` are read-only.
    ("swift-format format -i -r /abs/Sources", False),
    ("swift-format format -i -r Sources", True),
    ("swift format format -i -r .", True),
    ("swift format lint -r .", False),
    ("swift-format lint --strict --recursive Sources", False),
    ("xcrun swift-format lint -r .", False),
    ("swift format dump-configuration", False),
    ("swift-format dump-configuration --effective", False),
    # The subcommand decides, not the flag: `lint` rejects `-i` as an unknown
    # option (measured: exit 64, nothing written).
    ("swift format lint -i -r .", False),
    # Measured: the word is a subcommand only when it leads. After an option,
    # `lint` is a path and the default `format` runs.
    ("swift format -i -r lint .", True),
    ("swift-format format lint -i /abs/Sources", True),
    # No in-place flag: prints to stdout.
    ("swift format -r .", False),
    ("swift format --configuration cfg.json -r Sources", False),
    # The value of an option is not a target.
    ("swift-format -i --configuration cfg.json /abs/Sources/a.swift", False),
    ("swift format -i --configuration cfg.json /abs/Sources/a.swift", False),
    ("swift format -i --lines 3:9 /abs/a.swift", False),
    ("swift format -i --offsets 10:20 --offsets 40:60 /abs/a.swift", False),
    ("swift format -i --assume-filename a.swift /abs/a.swift", False),
    ("swift format -i -r --enable-experimental-feature Foo /abs/Sources", False),
    ("swift format -i --configuration /abs/cfg.json -r .", True),
    ("swift format -i --configuration cfg.json -r Sources", True),
    # The rest of SwiftPM is not a formatter.
    ("swift build -c release", False),
    ("swift test --filter FooTests", False),
    ("swift package update", False),
    ("swift run tool -i .", False),
    ("xcrun swift build", False),
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
