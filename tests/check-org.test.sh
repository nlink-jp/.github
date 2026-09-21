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

# ---- default_dest: the org root comes from the script, not the caller -----
# Invoked from a wrong cwd, the old $(pwd) default made every repo "not
# found locally" and still summarized green. The root is the script's own
# location, two levels up, regardless of where the caller stands.
_want_root=$(CDPATH= cd -- "$HERE/../.." && pwd)
_got_root=$(cd "$TMP" && default_dest)
if [ "$_got_root" = "$_want_root" ]; then ok 'default_dest ignores cwd'; else
  no 'default_dest ignores cwd'
  printf '        want: [%s]\n        got:  [%s]\n' "$_want_root" "$_got_root" >&2
fi

# ---- verdict: skipped repos can never summarize green ----------------------
# verdict_is LABEL EXPECTED-STATUS EXPECTED-SUBSTRING ERRORS SKIPPED
verdict_is() {
  _label="$1"; _status="$2"; _substr="$3"
  _out=$(verdict "$4" "$5"); _rc=$?
  if [ "$_rc" = "$_status" ] && printf '%s' "$_out" | grep -qF "$_substr"; then
    ok "$_label"
  else
    no "$_label"
    printf '        rc=%s out=[%s]\n' "$_rc" "$_out" >&2
  fi
}

verdict_is 'all found, all passed → green'      0 'all checks passed'            0 0
verdict_is 'failures fail'                      1 '2 check(s) failed'            2 0
verdict_is 'skips alone are INCOMPLETE, rc 1'   1 'INCOMPLETE — 3 repo(s)'       0 3
verdict_is 'failures and skips both reported'   1 'INCOMPLETE'                   1 1
verdict_is 'failures shown alongside skips'     1 '1 check(s) failed'            1 1

# ---- summary ---------------------------------------------------------------
echo "------------------------------------------------------------"
# ---- cask macOS floor: the package's target, Homebrew's symbol, the cask's line
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; printf '        want: [%s]\n        got:  [%s]\n' "$3" "$2" >&2; fi; }

printf '%s\n' 'let package = Package(' '    name: "X",' '    platforms: [.macOS(.v14)],' > "$TMP/Package.swift"
is 'Package.swift .macOS(.v14) is major 14' "$(package_macos_major "$TMP/Package.swift")" '14'
printf '%s\n' '    platforms: [.macOS("26.0")],' > "$TMP/Package.swift"
is 'Package.swift .macOS("26.0") is major 26' "$(package_macos_major "$TMP/Package.swift")" '26'
printf '%s\n' '    platforms: [.iOS(.v17)],' > "$TMP/Package.swift"
is 'no macOS platform is no major' "$(package_macos_major "$TMP/Package.swift")" ''

is 'macOS 13 is :ventura' "$(macos_symbol_for 13)" ':ventura'
is 'macOS 14 is :sonoma' "$(macos_symbol_for 14)" ':sonoma'
is 'macOS 26 is :tahoe (not the marketing name)' "$(macos_symbol_for 26)" ':tahoe'
is 'macOS 27 is :golden_gate' "$(macos_symbol_for 27)" ':golden_gate'
is 'an unknown major has no symbol, so the caller fails' "$(macos_symbol_for 99)" ''

printf '%s\n' 'cask "x" do' '  depends_on arch: :arm64' '  depends_on macos: :big_sur' 'end' > "$TMP/x.rb"
is 'a bare symbol is read' "$(cask_macos_floor "$TMP/x.rb")" ':big_sur'
printf '%s\n' 'cask "x" do' '  depends_on macos: ">= :sonoma"' 'end' > "$TMP/x.rb"
is 'a comparison is read as its symbol' "$(cask_macos_floor "$TMP/x.rb")" ':sonoma'
printf '%s\n' 'cask "x" do' '  depends_on arch: :arm64' 'end' > "$TMP/x.rb"
is 'no macos line is no floor' "$(cask_macos_floor "$TMP/x.rb")" ''

# ---- language mirrors: the pairing rules fail, the layout only warns
is 'README.md pairs with README.ja.md' "$(ja_counterpart README.md)" 'README.ja.md'
is 'docs/en/x.md pairs with docs/ja/x.ja.md' \
   "$(ja_counterpart docs/en/adr/0001-x.md)" 'docs/ja/adr/0001-x.ja.md'
is 'a path outside the two shapes pairs with nothing' "$(ja_counterpart docs/notes.md)" ''
is 'docs/ja/x.ja.md pairs back to docs/en/x.md' \
   "$(en_counterpart docs/ja/adr/0001-x.ja.md)" 'docs/en/adr/0001-x.md'
is 'README.ja.md pairs back to README.md' "$(en_counterpart README.ja.md)" 'README.md'

mirror_repo() {  # builds a repo under $TMP/mirror and echoes its path
  local dir="$TMP/mirror"
  rm -rf "$dir"; mkdir -p "$dir/docs/en/adr" "$dir/docs/ja/adr"
  git -C "$dir" init -q 2>/dev/null || git init -q "$dir"
  printf 'x\n' > "$dir/README.md"
  printf 'x\n' > "$dir/README.ja.md"
  printf 'x\n' > "$dir/docs/en/adr/0001-x.md"
  printf 'x\n' > "$dir/docs/ja/adr/0001-x.ja.md"
  git -C "$dir" add -A >/dev/null 2>&1
  echo "$dir"
}

MIRROR=$(mirror_repo)
is 'a consistent repository is silent' "$(mirror_problems "$MIRROR")" ''

rm "$MIRROR/docs/ja/adr/0001-x.ja.md"; git -C "$MIRROR" add -A >/dev/null 2>&1
case "$(mirror_problems "$MIRROR")" in
  *"no Japanese counterpart at docs/ja/adr/0001-x.ja.md"*) ok 'a missing Japanese counterpart is named' ;;
  *) no 'a missing Japanese counterpart is named' ;;
esac

MIRROR=$(mirror_repo)
mv "$MIRROR/docs/ja/adr/0001-x.ja.md" "$MIRROR/docs/ja/adr/0001-x.md"
git -C "$MIRROR" add -A >/dev/null 2>&1
case "$(mirror_problems "$MIRROR")" in
  *"needs the .ja.md suffix"*) ok 'a Japanese document without the suffix is named' ;;
  *) no 'a Japanese document without the suffix is named' ;;
esac

MIRROR=$(mirror_repo)
printf 'x\n' > "$MIRROR/docs/design.md"; git -C "$MIRROR" add -A >/dev/null 2>&1
out=$(mirror_problems "$MIRROR")
case "$out" in
  WARN*"docs/design.md"*) ok 'a flat document warns rather than fails' ;;
  *) no 'a flat document warns rather than fails' ;;
esac
case "$out" in
  *"no Japanese counterpart"*|*"no English counterpart"*) no 'the layout warning is not also a pairing failure' ;;
  *) ok 'the layout warning is not also a pairing failure' ;;
esac
# A pathspec would have matched docs/en/** for docs/*.md; the classification must not.
case "$(mirror_problems "$MIRROR")" in
  *"docs/en/adr/0001-x.md: documents are separated"*) no 'a document under docs/en is not called flat' ;;
  *) ok 'a document under docs/en is not called flat' ;;
esac

# ---- document references: a link is checked by resolving it ----------------
# The pair check above can be satisfied while every reference into the pair is
# dead, which is how 55 broken links survived the language split.
link_repo() {  # builds a repo under $TMP/links and echoes its path
  local dir="$TMP/links"
  rm -rf "$dir"; mkdir -p "$dir/docs/en/adr" "$dir/docs/ja/adr"
  git -C "$dir" init -q 2>/dev/null || git init -q "$dir"
  printf 'x\n' > "$dir/docs/en/adr/0001-x.md"
  printf 'x\n' > "$dir/docs/ja/adr/0001-x.ja.md"
  printf 'see [ADR-0001](docs/en/adr/0001-x.md)\n' > "$dir/README.md"
  printf 'see [ADR-0001](docs/ja/adr/0001-x.ja.md)\n' > "$dir/README.ja.md"
  git -C "$dir" add -A >/dev/null 2>&1
  echo "$dir"
}

LINKS=$(link_repo)
is 'every reference resolving is silent' "$(broken_links "$LINKS")" ''

# The exact shape the split left behind: the record moved, the link did not.
printf 'see [ADR-0001](docs/adr/0001-x.md)\n' > "$LINKS/README.md"
git -C "$LINKS" add -A >/dev/null 2>&1
is 'a link to a moved document is named with its target' \
   "$(broken_links "$LINKS")" 'README.md -> docs/adr/0001-x.md'

# A ../ reference is resolved from the document's own directory, not the repo root.
LINKS=$(link_repo)
printf 'see [the other side](../../en/adr/0001-x.md)\n' > "$LINKS/docs/ja/adr/0002-y.ja.md"
git -C "$LINKS" add -A >/dev/null 2>&1
is 'a ../ link is resolved from the document, not the root' "$(broken_links "$LINKS")" ''

printf 'see [nothing](../../en/adr/9999-nope.md)\n' > "$LINKS/docs/ja/adr/0002-y.ja.md"
git -C "$LINKS" add -A >/dev/null 2>&1
case "$(broken_links "$LINKS")" in
  *'docs/ja/adr/0002-y.ja.md -> ../../en/adr/9999-nope.md'*) ok 'a dead ../ link is named' ;;
  *) no 'a dead ../ link is named' ;;
esac

# Text the reader is shown rather than offered: not a reference, not a failure.
LINKS=$(link_repo)
cat > "$LINKS/docs/en/adr/0003-z.md" <<'EOF'
Run it like this:

```bash
cp [template](docs/adr/0000-template.md) .
```

Inline `[x](docs/adr/0000-template.md)` too.
EOF
git -C "$LINKS" add -A >/dev/null 2>&1
is 'a path inside code is not a reference' "$(broken_links "$LINKS")" ''

# External and absolute targets belong to somebody else.
LINKS=$(link_repo)
printf '%s\n' 'a [site](https://example.com/x.md)' 'a [scheme](mailto:x@example.com)' \
  'a [root](/etc/hosts)' 'an [anchor](#section)' > "$LINKS/docs/en/adr/0004-w.md"
git -C "$LINKS" add -A >/dev/null 2>&1
is 'external, absolute and anchor targets are left alone' "$(broken_links "$LINKS")" ''

# Untracked files are not the repository's references yet.
LINKS=$(link_repo)
printf 'see [nothing](nope.md)\n' > "$LINKS/scratch.md"
is 'an untracked document is not checked' "$(broken_links "$LINKS")" ''

# Upstream copies carry their own dead links; they are not ours to fix.
LINKS=$(link_repo)
mkdir -p "$LINKS/third_party/upstream"
printf 'see [nothing](README.ijg)\n' > "$LINKS/third_party/upstream/LICENSE.md"
git -C "$LINKS" add -A >/dev/null 2>&1
is 'a vendored document is skipped' "$(broken_links "$LINKS")" ''

# ---- tap currency: the release a formula/cask points at ---------------------
# A release nobody receives is not a release: `brew upgrade` reads the formula,
# and one tool sat two releases behind with every check green, because check 10
# compares the vendored tap-generation scripts and never asks what the formula
# targets.
printf '%s\n' 'cask "x" do' '  version "0.11.1"' '  sha256 "abc"' \
  '  url "https://github.com/nlink-jp/x/releases/download/v#{version}/x-v#{version}-darwin-arm64.zip"' 'end' > "$TMP/cask.rb"
is 'a cask version stanza is read' "$(brew_version "$TMP/cask.rb")" '0.11.1'

printf '%s\n' 'class X < Formula' \
  '  url "https://github.com/nlink-jp/x/releases/download/v1.9.0/x-v1.9.0-darwin-arm64.zip"' \
  '  sha256 "abc"' 'end' > "$TMP/formula.rb"
is 'a formula tag in the url is read' "$(brew_version "$TMP/formula.rb")" '1.9.0'

# The url form must not win over an explicit stanza, or a cask whose url
# interpolates #{version} would read as whatever the url happens to spell.
printf '%s\n' 'cask "x" do' '  version "2.0.0"' \
  '  url "https://github.com/nlink-jp/x/releases/download/v1.0.0/x.zip"' 'end' > "$TMP/both.rb"
is 'the version stanza wins over the url' "$(brew_version "$TMP/both.rb")" '2.0.0'

# A commented-out version is not the version.
printf '%s\n' 'cask "x" do' '  # version "9.9.9" (was)' '  version "0.1.0"' 'end' > "$TMP/comment.rb"
is 'a commented version is not read' "$(brew_version "$TMP/comment.rb")" '0.1.0'

# Unreadable must come back empty so the caller can report it. Returning
# something plausible here would hide exactly the drift this check exists for.
printf '%s\n' 'cask "x" do' '  name "x"' 'end' > "$TMP/none.rb"
is 'an unreadable version is empty, not a guess' "$(brew_version "$TMP/none.rb")" ''

printf '%s\n' 'class X < Formula' '  version "1.2"' 'end' > "$TMP/short.rb"
is 'a two-part version is not accepted as X.Y.Z' "$(brew_version "$TMP/short.rb")" ''

echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
