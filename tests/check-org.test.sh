#!/usr/bin/env bash
# check-org.test.sh — tests for check-org.sh's Makefile build-output resolution.
# Run: bash .github/tests/check-org.test.sh
#
# The rule under test: `make build` must write into dist/. The check compares
# the *resolved value* of the output path, not the variable name used to spell
# it — `BIN_DIR := dist` is conventional and must pass.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

CHECK_ORG_LIB_ONLY=1 . "$HERE/../scripts/check-org.sh" >/dev/null
set +e +u +o pipefail

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok() { printf 'ok   - %s\n' "$1"; pass=$((pass + 1)); }
no() { printf 'FAIL - %s\n' "$1"; fail=$((fail + 1)); }

# dirs_are LABEL EXPECTED MAKEFILE-BODY
dirs_are() {
  _label="$1"; _want="$2"; _body="$3"
  printf '%s\n' "$_body" > "$TMP/Makefile"
  _got=$(makefile_build_dirs "$TMP/Makefile" | paste -sd' ' -)
  if [ "$_got" = "$_want" ]; then ok "$_label"; else
    no "$_label"
    printf '        want: [%s]\n        got:  [%s]\n' "$_want" "$_got" >&2
  fi
}

# ---- 1. the false positive this check was fixed for ------------------------
# BIN_DIR := dist builds into dist/ and must not be reported as bin/.
dirs_are 'BIN_DIR := dist resolves to dist' 'dist dist' '
BINARY  := data-toolbox-mcp
BIN_DIR := dist
build:
	go build $(LDFLAGS) -o $(BIN_DIR)/$(BINARY) .
build-all:
	CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch go build -o $(BIN_DIR)/$(BINARY)-$$os-$$arch$$ext .
'

# ---- 2. every variable name in org-wide use resolves the same --------------
for v in DIST_DIR BIN_DIR OUTPUT_DIR DIST OUT; do
  dirs_are "\$($v) := dist resolves to dist" 'dist' "
BINARY := tool
$v := dist
build:
	go build -o \$($v)/\$(BINARY) .
"
done

# ---- 3. a variable whose value really is bin/ still fails -------------------
dirs_are 'BIN_DIR := bin resolves to bin' 'bin' '
BINARY  := tool
BIN_DIR := bin
build:
	go build -o $(BIN_DIR)/$(BINARY) .
'
dirs_are 'DIST_DIR := build resolves to build' 'build' '
BINARY   := tool
DIST_DIR := build
build:
	go build -o $(DIST_DIR)/$(BINARY) .
'

# ---- 4. literal paths ------------------------------------------------------
dirs_are 'literal dist/ passes'      'dist' '
BINARY := tool
build:
	go build -o dist/$(BINARY) .
'
dirs_are 'literal bin/ is bin'       'bin'  '
BINARY := tool
build:
	go build -o bin/$(BINARY) .
'
dirs_are 'literal ./bin/ is bin'     'bin'  '
BINARY := tool
build:
	go build -o ./bin/$(BINARY) .
'
dirs_are 'nested dist/plugins passes as dist/plugins' 'dist/plugins' '
BINARY := tool
build:
	go build -o dist/plugins/$(BINARY) .
'

# ---- 5. project-root output (the other half of the rule) -------------------
dirs_are '-o $(BINARY) is project root' '.' '
BINARY := tool
build:
	go build -ldflags "$(LDFLAGS)" -o $(BINARY) .
'
dirs_are '-o ./tool is project root'    '.' '
build:
	go build -o ./tool .
'

# ---- 6. unresolvable targets are reported as ?, never guessed --------------
# $(OUT) with no assignment anywhere: we cannot know the directory, so the
# check must stay silent rather than mistake it for a root build.
dirs_are 'unassigned $(OUT) is unresolvable' '?' '
build:
	go build -o $(OUT) .
'
# $(eval VAR := ...) inside a recipe is resolved (llm-othello uses this form).
dirs_are '$(eval OUT := dist/...) resolves to dist' 'dist dist' '
BINARY := llm-othello
build:
	go build -o dist/$(BINARY) .
build-all:
	@$(foreach p,$(PLATFORMS), \
		$(eval OUT  := dist/$(BINARY)_$(OS)_$(ARCH)$(EXT)) \
		go build -o $(OUT) . ;)
'
# A make function call in the leading position is unresolvable, not root.
dirs_are 'leading $(shell ...) is unresolvable' '?' '
build:
	go build -o $(shell echo dist)/tool .
'

# A build routed through a variable is still a go build (slack-router does
# this); the release staging path on its build-all line is a shell variable and
# must read as unresolvable rather than as a stray output directory.
dirs_are 'GO_BUILD := go build is recognised' 'dist ?' '
BINARY   := slack-router
GO_BUILD := go build -trimpath -ldflags "$(LDFLAGS)"
build:
	$(GO_BUILD) -o dist/$(BINARY) .
build-all:
	GOOS=$$os GOARCH=$$arch $(GO_BUILD) -o "$$stagedir/$(BINARY)" . \
'
dirs_are 'GO_BUILD := go build into bin/ still fails' 'bin' '
BINARY   := tool
GO_BUILD := go build -trimpath
build:
	$(GO_BUILD) -o bin/$(BINARY) .
'

# ---- 7. non-Go Makefiles yield nothing (no verdict, no error) --------------
dirs_are 'wails build is ignored' '' '
build:
	wails build -clean -platform darwin/arm64
'
dirs_are 'no build recipe at all is ignored' '' '
test:
	uv run pytest
'
dirs_are '-o /dev/null is ignored' '' '
vet:
	go build -o /dev/null ./...
'

# ---- 8. makefile_var: assignment forms and near-miss names -----------------
cat > "$TMP/Makefile" <<'EOF'
BINARY   := tool
DIST_DIR := dist
LAZY      = lazy
OPTIONAL ?= opt
COMMENTED := dist   # trailing comment
	VOICE_STUDIO_TEST_BINARY=$(abspath $(DIST_DIR)/$(BINARY))
EOF
var_is() { # label var expected
  _got=$(makefile_var "$TMP/Makefile" "$2")
  if [ "$_got" = "$3" ]; then ok "$1"; else
    no "$1"; printf '        want: [%s]\n        got:  [%s]\n' "$3" "$_got" >&2
  fi
}
var_is 'makefile_var: := form'                DIST_DIR  'dist'
var_is 'makefile_var: = form'                 LAZY      'lazy'
var_is 'makefile_var: ?= form'                OPTIONAL  'opt'
var_is 'makefile_var: strips trailing comment' COMMENTED 'dist'
var_is 'makefile_var: unassigned is empty'    NOPE      ''
# BINARY must not pick up VOICE_STUDIO_TEST_BINARY, and DIST must not pick up
# DIST_DIR — the name has to match at a word boundary.
var_is 'makefile_var: no suffix-name match'   BINARY    'tool'
var_is 'makefile_var: no prefix-name match'   DIST      ''

# ---- 9. home_path_leaks: the account leaks, invented names do not -----------
# The line filter behind check 11. Every "leaks" case is a real line found in a
# public repo; every "clean" case is a legitimate fake home that was ALSO found
# in these repos — an allowlist of invented names is unwinnable, which is why
# the filter matches the account instead. Account under test: "realuser".

# leaks LABEL LINE
leaks() {
  if [ -n "$(printf '%s\n' "$2" | home_path_leaks realuser)" ]; then ok "$1"; else no "$1"; fi
}
# clean LABEL LINE
clean() {
  _got=$(printf '%s\n' "$2" | home_path_leaks realuser)
  if [ -z "$_got" ]; then ok "$1"; else no "$1"; printf '        flagged: [%s]\n' "$_got" >&2; fi
}

leaks 'markdown config example'  '    "/Users/realuser/works/org/_wip/tool/samples",'
leaks 'shell variable'           'SW="/Users/realuser/works/tool/dist/tool"'
leaks 'swift test fixture'       '            "/Users/realuser/works/org",'
leaks 'json tool output'         '  "host_work_dir": "/Users/realuser/.data-toolbox/samples/work/"'
leaks 'elided tail, named user'  '  => /Users/realuser/...` comment line from `app/go.mod`'
leaks 'linux home'               'CFG=/home/realuser/.config/tool.toml'

clean 'placeholder you'          '      "command": "/Users/you/path/to/tool/dist/tool",'
clean 'placeholder alice'        'A line like `replace foo => /Users/alice/src/foo` leaks the'
clean 'go test fixture'          '	t.Setenv("HOME", "/Users/test")'
clean 'swift test fixture'       '    private let home = "/Users/tester"'
clean 'docs walkthrough'         'args = ["run", "--project", "/Users/yourname/works/skeleton"]'
clean 'single-letter fixture'    '	got := Candidates("/Users/x")'
clean 'short linux fixture'      '	withXDG := DefaultDataDir(env, "/home/u")'
clean 'elided user'              'the path is /Users/.../samples/sales.csv'
clean 'no home path at all'      'make build          # -> dist/tool'
# The account has to match the whole segment, or a longer real name slips by.
clean 'account is a prefix only' 'see /Users/realuser2/src for the layout'
# Multiple accounts (id -un and the home basename can differ).
multi=$(printf '%s\n' '/Users/other/x' | home_path_leaks realuser other)
if [ -n "$multi" ]; then ok 'second account also matches'; else no 'second account also matches'; fi
# No accounts supplied: consume input, flag nothing (gh-less / odd environments).
none=$(printf '%s\n' '/Users/realuser/x' | home_path_leaks)
if [ -z "$none" ]; then ok 'no accounts given flags nothing'; else no 'no accounts given flags nothing'; fi

# ---- 10. unreleased_claims: status prose vs procedure names -----------------
# The line filter behind check 12.

# claims LABEL LINE
claims() {
  if [ -n "$(printf '%s\n' "$2" | unreleased_claims)" ]; then ok "$1"; else no "$1"; fi
}
# noclaim LABEL LINE
noclaim() {
  _got=$(printf '%s\n' "$2" | unreleased_claims)
  if [ -z "$_got" ]; then ok "$1"; else no "$1"; printf '        flagged: [%s]\n' "$_got" >&2; fi
}

claims 'en banner'        '> **Pre-release.** Everything the design calls for works.'
claims 'en status line'   '> **Status: in development, not yet released.** The shelf works.'
claims 'en install line'  'Not yet released. To build from source (Go 1.25+):'
claims 'ja banner'        '> **プレリリース。** 設計にある機能はすべて動きます。'
claims 'ja install line'  '未リリース。公開後は以下で入ります。'

# "Pre-release" also names a procedure. Those must not trip the check, or it
# fires on every repo that documents its release gates and gets ignored.
noclaim 'pre-release gates heading'  '**Pre-release gates (must pass before tagging):**'
noclaim 'pre-release smoke'          '### 6.4 Manual smoke (pre-release)'
noclaim 'ordinary install line'      'brew install nlink-jp/tap/tool'

# ---- summary ---------------------------------------------------------------
echo "------------------------------------------------------------"
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
