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
    # Changed from allowed: in-place sed is refused at any path now (family 2).
    # This exact spelling, aimed at an absolute path, is the one that went wrong
    # — GNU sed took '' as the script and the substitution as a file name.
    ("sed -i '' 's/a/b/' /tmp/x.go", True),
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

    # ---- family 2: recurring shell footguns --------------------------------
    # In-place sed, at any path and under any spelling.
    ("sed -i 's/a/b/' /abs/file", True),
    ("gsed -i 's/a/b/' /abs/file", True),
    ("/usr/bin/sed -i.bak 's/a/b/' /abs/file", True),
    ("sed --in-place 's/a/b/' /abs/file", True),
    ("sed -ni 's/a/b/p' /abs/file", True),
    ("cd /abs/repo && sed -i 's/a/b/' Makefile", True),   # the cd anchor answers a different question
    # ... and every sed that does not write in place is left alone.
    ("sed -n '1,5p' /abs/file", False),
    ("sed -E 's/(a)/\\1/' /abs/file > /abs/out", False),
    ("sed -e 's/i/I/' /abs/file", False),                  # an `i` in the script is not the flag
    ("cat /abs/f | sed 's/x/y/'", False),
    # A heredoc body is data: writing a note that mentions sed -i is not running it.
    ("cat > /abs/notes.md <<'EOF'\nnever use sed -i here\nEOF", False),

    # PIPESTATUS under the tool's zsh.
    ("make test | tail -3; echo ${PIPESTATUS[0]}", True),
    ('echo "rc=${PIPESTATUS[0]}"', True),
    ("cd /abs && make check 2>&1 | tail -1; echo rc=${PIPESTATUS[0]}", True),
    # Inside bash, or inside a script written through a heredoc: bash's business.
    ("bash -c 'false | true; echo ${PIPESTATUS[0]}'", False),
    ("cat > /abs/s.sh <<'EOF'\nfalse | true\necho ${PIPESTATUS[0]}\nEOF", False),
    ("make test >/dev/null 2>&1; echo rc=$?", False),

    # A single-quoted grep pattern with a mid-pattern `$`, without -F.
    ("grep -q 'exit $$rc' /abs/Makefile", True),
    ("grep -c '$(VERSION)-darwin' /abs/Makefile", True),
    ("grep -rn 'a$b' /abs/dir", True),
    # -F in any spelling, an anchor at the end, before ) or |, or escaped: fine.
    ("grep -qF 'exit $$rc' /abs/Makefile", False),
    ("grep -F -q 'exit $$rc' /abs/Makefile", False),
    ("grep --fixed-strings 'a$b' /abs/f", False),
    ("grep -E '^v[0-9]+$' /abs/f", False),
    ("grep -E '(foo$|bar$)' /abs/f", False),
    ("grep '\\$1' /abs/f", False),
    # Double-quoted: the shell expands it first, so the guard cannot know the pattern.
    ('grep "$pattern" /abs/f', False),
    # The existing read-only case must stay allowed.
    ("grep -rn 'foo' .", False),
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
