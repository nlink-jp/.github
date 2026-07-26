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

# ---- summary ---------------------------------------------------------------
echo "------------------------------------------------------------"
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
