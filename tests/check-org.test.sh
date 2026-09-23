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
verdict_is 'skips alone are INCOMPLETE, rc 1'   1 'INCOMPLETE — 3 item(s) not checked' 0 3
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

# ---- release-gate form: the open recipe must be recognised ------------------
# The open form accepts three of six states (another tag, does not unpack, does
# not run); 59 repos carried it. The template is fixed, so what is left to
# guard is a hand-edited or pasted copy.
cat > "$TMP/open.mk" <<'EOF'
verify-release:
	@test -f "dist/$(BINARY)-$(VERSION)-darwin-arm64.zip.notarized" || exit 1
	@tmp=$$(mktemp -d) && 		unzip -oq "dist/$(BINARY)-$(VERSION)-darwin-arm64.zip" -d "$$tmp" && 		"$$tmp/$(BINARY)" --version && 		spctl -a -vv -t install "$$tmp/$(BINARY)" 2>&1 | head -2 || true; 		rm -rf "$$tmp"
EOF
case "$(open_release_gate "$TMP/open.mk")" in
  *"|| true"*) ok 'the open release gate is recognised' ;;
  *) no 'the open release gate is recognised' ;;
esac

cat > "$TMP/closed.mk" <<'EOF'
verify-release:
	@tmp=$$(mktemp -d); rc=0; 		if ! unzip -oq "dist/x.zip" -d "$$tmp"; then rc=1; 		else spctl -a -vv -t install "$$tmp/x" 2>&1 | head -2 || true; 		fi; 		rm -rf "$$tmp"; 		exit $$rc
EOF
is 'the closed gate is silent' "$(open_release_gate "$TMP/closed.mk")" ''

# A GUI gate is a different recipe (stapler validate, no `|| true`) and must not
# be reported — the sweep deliberately left those alone.
printf '%s
' 'verify-release:' '	@xcrun stapler validate $(APP_BUNDLE)' > "$TMP/gui.mk"
is 'a GUI gate is silent' "$(open_release_gate "$TMP/gui.mk")" ''

# No verify-release target at all: nothing to say.
printf '%s
' 'build:' '	go build ./...' > "$TMP/none.mk"
is 'a Makefile without the target is silent' "$(open_release_gate "$TMP/none.mk")" ''
is 'a missing Makefile is silent' "$(open_release_gate "$TMP/absent.mk")" ''

# The markers are read from the verify-release recipe alone. web-fetch's open
# gate passed while the check read the whole file, because its e2e target keeps
# the Go suite's status with `exit $$rc`.
cat > "$TMP/open-e2e.mk" <<'EOF'
e2e: build
	@go test -tags e2e ./e2e/... > dist/e2e-go.log 2>&1; rc=$$?; \
		exit $$rc

## verify-release: refuse to release an un-notarized zip (marker gate)
verify-release:
	@test -f "dist/x.zip.notarized" || exit 1
	@tmp=$$(mktemp -d) && \
		unzip -oq "dist/x.zip" -d "$$tmp" && \
		"$$tmp/x" --version && \
		spctl -a -vv -t install "$$tmp/x" 2>&1 | head -2 || true; \
		rm -rf "$$tmp"
	@echo "verify-release: OK ($(VERSION), notarization marker present)"
EOF
case "$(open_release_gate "$TMP/open-e2e.mk")" in
  *"|| true"*) ok 'an exit $$rc in an earlier target does not close the gate' ;;
  *) no 'an exit $$rc in an earlier target does not close the gate' ;;
esac

# The recipe ends at the next rule, past blank and comment lines.
cat > "$TMP/open-later.mk" <<'EOF'
verify-release:
	@tmp=$$(mktemp -d) && \
		unzip -oq "dist/x.zip" -d "$$tmp" && \
		"$$tmp/x" --version && \
		spctl -a -vv -t install "$$tmp/x" 2>&1 | head -2 || true; \
		rm -rf "$$tmp"

## release: upload
release:
	@scripts/upload.sh; rc=$$?; exit $$rc
EOF
case "$(open_release_gate "$TMP/open-later.mk")" in
  *"|| true"*) ok 'an exit $$rc in a later target does not close the gate' ;;
  *) no 'an exit $$rc in a later target does not close the gate' ;;
esac

# Blank and comment lines inside the recipe do not end it (make skips them), and
# a continuation line counts whatever its indentation. Stopping early would
# read too little and let an open block below the gap through.
cat > "$TMP/open-gap.mk" <<'EOF'
verify-release:
	@test -f "dist/x.zip.notarized" || exit 1

# open the zip the way a user would
	@tmp=$$(mktemp -d) && \
    unzip -oq "dist/x.zip" -d "$$tmp" && \
    "$$tmp/x" --version && \
    spctl -a -vv -t install "$$tmp/x" 2>&1 | head -2 || true; \
    rm -rf "$$tmp"
EOF
case "$(open_release_gate "$TMP/open-gap.mk")" in
  *"|| true"*) ok 'a blank line, a comment and space-indented continuations are read through' ;;
  *) no 'a blank line, a comment and space-indented continuations are read through' ;;
esac

# The closed gate followed by the Linux-archive block (which exits 1, not on rc)
# and its longer OK line.
cat > "$TMP/closed-linux.mk" <<'EOF'
verify-release:
	@tmp=$$(mktemp -d); rc=0; \
		if ! unzip -oq "dist/x.zip" -d "$$tmp"; then rc=1; \
		else spctl -a -vv -t install "$$tmp/x" 2>&1 | head -2 || true; \
		fi; \
		rm -rf "$$tmp"; \
		exit $$rc
	@for p in $(PLATFORMS); do os=$${p%/*}; \
		[ "$$os" = linux ] || continue; \
		gzip -dc "dist/x-$$os.tar.gz" | grep -qa 'LIBARCHIVE.xattr' && exit 1; \
	done
	@echo "verify-release: OK ($(VERSION), notarized, unpacks, runs, reports its version, clean linux archives)"
EOF
is 'the closed gate with a linux-archive block is silent' "$(open_release_gate "$TMP/closed-linux.mk")" ''

# ---- linux archive metadata: both tar settings, and a gate that can see ._ --
# 61 repos archived with a plain `tar -czf`. COPYFILE_DISABLE=1 stops the ._
# members and --no-xattrs the pax headers, so either one alone still ships
# metadata; and a gate listing with a plain `tar -tzf` cannot see ._ members.
tarmk() { # tarmk FILE TAR-LINE GATE-LIST-LINE [GATE-XATTR-LINE]
  printf 'package:\n\t@cd dist && ( cd _pkg && %s "../x.tar.gz" * )\n\nverify-release:\n\t@names=$$(%s "dist/x.tar.gz"); \\\n\t\t%s\n' \
    "$2" "$3" "${4:-xh=\$\$(python3 -c 'import sys, tarfile; [m.pax_headers for m in tarfile.open(sys.argv[1])]' dist/x.tar.gz)}" > "$1"
}
tarmk "$TMP/tar-both.mk" 'COPYFILE_DISABLE=1 tar --no-xattrs -czf' "tar --options 'tar:!mac-ext' -tzf"
is 'both settings and a !mac-ext listing are silent' "$(linux_tar_metadata "$TMP/tar-both.mk")" ''
tarmk "$TMP/tar-plain.mk" 'tar -czf' "tar --options 'tar:!mac-ext' -tzf"
case "$(linux_tar_metadata "$TMP/tar-plain.mk")" in
  *"without COPYFILE_DISABLE=1 and --no-xattrs"*) ok 'a plain tar -czf is reported' ;;
  *) no 'a plain tar -czf is reported' ;;
esac
tarmk "$TMP/tar-copyfile.mk" 'COPYFILE_DISABLE=1 tar -czf' "tar --options 'tar:!mac-ext' -tzf"
[ -n "$(linux_tar_metadata "$TMP/tar-copyfile.mk")" ] && ok 'COPYFILE_DISABLE=1 alone is reported (pax headers)' || no 'COPYFILE_DISABLE=1 alone is reported (pax headers)'
tarmk "$TMP/tar-noxattrs.mk" 'tar --no-xattrs -czf' "tar --options 'tar:!mac-ext' -tzf"
[ -n "$(linux_tar_metadata "$TMP/tar-noxattrs.mk")" ] && ok '--no-xattrs alone is reported (._ members)' || no '--no-xattrs alone is reported (._ members)'
tarmk "$TMP/tar-blind.mk" 'COPYFILE_DISABLE=1 tar --no-xattrs -czf' 'tar -tzf'
case "$(linux_tar_metadata "$TMP/tar-blind.mk")" in
  *"tar:!mac-ext"*) ok 'a gate listing with a plain tar -tzf is reported' ;;
  *) no 'a gate listing with a plain tar -tzf is reported' ;;
esac
# The xattr check must read pax headers. Grepping the decompressed stream also
# matches file text: slack-router's bundled CHANGELOG.md names the keywords, and
# its clean v0.4.0 archives were refused.
tarmk "$TMP/tar-stream.mk" 'COPYFILE_DISABLE=1 tar --no-xattrs -czf' "tar --options 'tar:!mac-ext' -tzf" \
  "gzip -dc dist/x.tar.gz | grep -qa -e 'LIBARCHIVE.xattr' -e 'SCHILY.xattr' && exit 1"
case "$(linux_tar_metadata "$TMP/tar-stream.mk")" in
  *"pax headers"*) ok 'a gate that greps the decompressed stream is reported' ;;
  *) no 'a gate that greps the decompressed stream is reported' ;;
esac
tarmk "$TMP/tar-noxcheck.mk" 'COPYFILE_DISABLE=1 tar --no-xattrs -czf' "tar --options 'tar:!mac-ext' -tzf" 'true'
[ -n "$(linux_tar_metadata "$TMP/tar-noxcheck.mk")" ] && ok 'a gate with no xattr check at all is reported' || no 'a gate with no xattr check at all is reported'
printf 'package:\n\t@( cd _pkg && COPYFILE_DISABLE=1 tar --no-xattrs -czf ../x.tar.gz * )\n' > "$TMP/tar-nogate.mk"
is 'no verify-release target: only the tar line is judged' "$(linux_tar_metadata "$TMP/tar-nogate.mk")" ''
printf 'check:\n\t@tar -tzf dist/x.tar.gz >/dev/null\n\t@tar -xzf dist/x.tar.gz -C /tmp/x\n\t@tar -C dist -tzf x.tar.gz\n# old: tar -czf x.tar.gz *\n' > "$TMP/tar-read.mk"
is 'listing, extracting and a commented-out tar -czf are not creation' "$(linux_tar_metadata "$TMP/tar-read.mk")" ''
printf 'build:\n\tgo build -o dist/x .\n' > "$TMP/tar-none.mk"
is 'a Makefile that creates no tar archive is silent' "$(linux_tar_metadata "$TMP/tar-none.mk")" ''
# The template itself, as the document states it, must pass.
awk '/^```makefile$/{buf=""; on=1; next} on && /^```$/{if (buf ~ /verify-release:/) {printf "%s", buf; exit} on=0; next} on{buf=buf $0 "\n"}' \
  "$HERE/../CONVENTIONS.md" > "$TMP/template.mk"
grep -q 'tar --no-xattrs -czf' "$TMP/template.mk" \
  && is 'the CONVENTIONS.md template passes' "$(linux_tar_metadata "$TMP/template.mk")" '' \
  || no 'the CONVENTIONS.md template could be extracted'

# ---- bundled CLI: the pin a GUI declares for the CLI inside it --------------
printf '%s\n' 'CLI_BIN ?= ../active-lens/dist/active-lens' 'CLI_VERSION ?= v0.3.1' > "$TMP/gui1.mk"
is 'a plain CLI_BIN and a pin are read' "$(bundled_cli_pin "$TMP/gui1.mk")" 'active-lens v0.3.1'

printf '%s\n' 'CLI_BIN ?= $(firstword $(wildcard ../sensor-lens/dist/sensor-lens-darwin-arm64 ../sensor-lens/dist/sensor-lens))' \
  'CLI_VERSION ?= v0.1.0   # the release it ships' > "$TMP/gui2.mk"
is 'the fallback CLI_BIN form still names the CLI' "$(bundled_cli_pin "$TMP/gui2.mk")" 'sensor-lens v0.1.0'

printf '%s\n' 'CLI_BIN ?= ../task-clock/dist/task-clock' > "$TMP/gui3.mk"
is 'a bundler without a pin is reported as unpinned' "$(bundled_cli_pin "$TMP/gui3.mk")" 'task-clock -'

printf '%s\n' 'BINARY := tool' 'build:' '	go build -o dist/tool .' > "$TMP/cli.mk"
is 'a Makefile that bundles nothing is silent' "$(bundled_cli_pin "$TMP/cli.mk")" ''
is 'a missing Makefile is silent' "$(bundled_cli_pin "$TMP/nope.mk")" ''

# ---- the organization listing: one gh call answers archived, shipped, latest --
# gh_repo_list is the script's only call to GitHub for this; a canned listing
# stands in for it.
gh_repo_list() { printf 'alpha\tfalse\tv1.2.0\nbeta\ttrue\t\ngamma\tfalse\t\n'; }
org_repos_loaded=0
load_org_repos
is 'latest_release reads the tag' "$(latest_release alpha)" 'v1.2.0'
is 'a repository without a release has no tag' "$(latest_release gamma)" ''
is 'a repository missing from the listing has no tag' "$(latest_release delta)" ''
is 'a name is matched whole, not as a prefix' "$(latest_release alph)" ''
if is_archived beta "$TMP/none"; then ok 'archived is read from the listing'; else no 'archived is read from the listing'; fi
if is_archived alpha "$TMP/none"; then no 'a live repository is not archived'; else ok 'a live repository is not archived'; fi
if has_release alpha; then ok 'a released repository has a release'; else no 'a released repository has a release'; fi
if has_release gamma; then no 'an unreleased repository has none'; else ok 'an unreleased repository has none'; fi
is 'a complete listing is usable' "$org_repos_state" 'ok'

# An unusable listing must read as unusable — never as an organization with
# nothing released and nothing archived.
listing_state_is() {  # LABEL WANT-SUBSTRING — after reloading through the stub
  org_repos_loaded=0; load_org_repos
  case "$org_repos_state" in
    *"$2"*) if [ -z "$org_repos$archived_list$released_list" ]; then ok "$1"; else no "$1 (listing not emptied)"; fi ;;
    *) no "$1"; printf '        state: [%s]\n' "$org_repos_state" >&2 ;;
  esac
}
gh_repo_list() { return 127; }
listing_state_is 'gh absent: unusable, and says so' 'gh is not installed'
gh_repo_list() { printf 'alpha\tfalse\tv1.2.0\n'; return 1; }
listing_state_is 'gh failing: unusable, even with partial output' 'failed'
gh_repo_list() { :; }
listing_state_is 'an empty listing is unusable' 'no repositories'
gh_repo_list() { printf 'alpha\tfalse\tv1.2.0\nbeta\ttrue\t\ngamma\tfalse\t\n'; }
ORG_LIST_LIMIT=3
listing_state_is 'a listing as long as the limit may be cut short: unusable' 'limit of 3'
ORG_LIST_LIMIT=4
org_repos_loaded=0; load_org_repos
is 'a listing under the limit is usable' "$org_repos_state" 'ok'

# ---- tap currency: compared entries only, and never OK without the listing --
mkdir -p "$TMP/tap/Formula" "$TMP/tap/Casks"
printf 'url "https://github.com/nlink-jp/alpha/releases/download/v1.2.0/alpha.zip"\n' > "$TMP/tap/Formula/alpha.rb"
printf 'version "0.1.0"\n' > "$TMP/tap/Casks/gamma.rb"
tap_run() {  # LABEL WANT-ERRORS WANT-SUBSTRING — check_tap in this shell, so errors counts
  errors=0
  check_tap "$TMP/tap" > "$TMP/tap.out"
  if [ "$errors" = "$2" ] && grep -qF -- "$3" "$TMP/tap.out"; then ok "$1"; else
    no "$1"; printf '        errors=%s out=[%s]\n' "$errors" "$(cat "$TMP/tap.out")" >&2
  fi
}
org_repos_loaded=0
tap_run 'an entry on its release passes; one with no release is not counted as passing' 0 \
  '[OK] homebrew-tap: 1 entr(ies) point at their latest release (1 with no visible release, not compared)'
gh_repo_list() { printf 'alpha\tfalse\tv1.3.0\ngamma\tfalse\t\n'; }
org_repos_loaded=0
tap_run 'an entry behind its release fails' 1 'alpha points at 1.2.0, latest release is v1.3.0'
gh_repo_list() { return 1; }
org_repos_loaded=0
tap_run 'without the listing the tap is NOT checked' 0 'NOT checked'
if grep -qF '[OK]' "$TMP/tap.out"; then no 'without the listing the tap never says OK'; else ok 'without the listing the tap never says OK'; fi
errors=0

# ---- fetching: every repository up front, each fetch writing only its own ---
# Local bare repositories stand in for GitHub. protocol.file.allow=always lets a
# submodule be fetched over a file path at all: without it the umbrella's
# recursive fetch fails by itself, and the no-recursion test below could not
# fail. Set through the environment because fetch_all runs plain git.
export GIT_CONFIG_COUNT=5 \
  GIT_CONFIG_KEY_0=protocol.file.allow GIT_CONFIG_VALUE_0=always \
  GIT_CONFIG_KEY_1=user.name           GIT_CONFIG_VALUE_1=t \
  GIT_CONFIG_KEY_2=user.email          GIT_CONFIG_VALUE_2=t@t \
  GIT_CONFIG_KEY_3=init.defaultBranch  GIT_CONFIG_VALUE_3=main \
  GIT_CONFIG_KEY_4=commit.gpgsign      GIT_CONFIG_VALUE_4=false

F="$TMP/fetch"
mkdir -p "$F/dest"
commit_push() { git -C "$1" commit -q --allow-empty -m "$2" && git -C "$1" push -q origin HEAD:main; }
for r in sub umb solo; do git init -q --bare "$F/$r.git"; git clone -q "$F/$r.git" "$F/$r-w" 2>/dev/null; done
commit_push "$F/sub-w" s1
commit_push "$F/solo-w" o1
git -C "$F/umb-w" submodule -q add "$F/sub.git" sub 2>/dev/null
commit_push "$F/umb-w" u1
git clone -q --recurse-submodules "$F/umb.git" "$F/dest/a-series" 2>/dev/null
git clone -q "$F/solo.git" "$F/dest/solo" 2>/dev/null

# The origins move on: a submodule commit, the umbrella recording it, and a
# commit in the standalone repository.
commit_push "$F/sub-w" s2
git -C "$F/umb-w/sub" pull -q origin main
git -C "$F/umb-w" add sub
commit_push "$F/umb-w" u2
commit_push "$F/solo-w" o2
new_umb=$(git -C "$F/umb.git" rev-parse main)
new_sub=$(git -C "$F/sub.git" rev-parse main)
new_solo=$(git -C "$F/solo.git" rev-parse main)
old_sub=$(git -C "$F/dest/a-series/sub" rev-parse origin/main)

is 'series_repos lists a cloned umbrella, then its submodules; an absent series is skipped' \
   "$(series_repos "$F/dest" a-series b-series | paste -sd' ' -)" "$F/dest/a-series $F/dest/a-series/sub"

# By default a fetch in an umbrella also fetches every submodule whose recorded
# commit moved. Run beside that submodule's own fetch, that is two processes
# writing one repository.
failed=$(printf '%s\n' "$F/dest/a-series" | fetch_all 2)
is 'a fetch that works is not named as failed' "$failed" ''
is 'fetch_all fetches the umbrella' "$(git -C "$F/dest/a-series" rev-parse origin/main)" "$new_umb"
is 'the umbrella fetch leaves its submodule to its own fetch' \
   "$(git -C "$F/dest/a-series/sub" rev-parse origin/main)" "$old_sub"

failed=$(printf '%s\n' "$F/dest/a-series/sub" "$F/no-such-repo" "$F/dest/solo" | fetch_all 2); rc=$?
is 'a repository that cannot be fetched does not fail fetch_all' "$rc" 0
is 'fetch_all names the repository it could not fetch, and only that one' "$failed" "$F/no-such-repo"
is 'the submodule is fetched by its own entry' "$(git -C "$F/dest/a-series/sub" rev-parse origin/main)" "$new_sub"
is 'the entries after a failed fetch are fetched' "$(git -C "$F/dest/solo" rev-parse origin/main)" "$new_solo"

# fetch_one is what xargs runs per entry. Handed an empty argument, or none (GNU
# xargs runs it once with none on empty input; macOS xargs never does, so this
# is exercised here directly), it must not become `git -C ""`, which fetches
# wherever the caller is.
commit_push "$F/solo-w" o3
before=$(git -C "$F/dest/solo" rev-parse origin/main)
( cd "$F/dest/solo" && sh -c "$fetch_one" _ "" )
is 'an empty argument fetches nothing' "$(git -C "$F/dest/solo" rev-parse origin/main)" "$before"
( cd "$F/dest/solo" && sh -c "$fetch_one" _ )
is 'no argument fetches nothing' "$(git -C "$F/dest/solo" rev-parse origin/main)" "$before"
( cd "$F/dest/solo" && sh -c "$fetch_one" _ "$F/dest/solo" )
is 'the same repository named explicitly is fetched' \
   "$(git -C "$F/dest/solo" rev-parse origin/main)" "$(git -C "$F/solo.git" rev-parse main)"

# ---- a stale or missing remote ref is not compared ---------------------------
fetch_failed_list="$F/dest/a-series/sub"
if fetch_failed "$F/dest/a-series/sub"; then ok 'fetch_failed knows a listed repository'; else no 'fetch_failed knows a listed repository'; fi
if fetch_failed "$F/dest/a-series"; then no 'a prefix of a failed path is not failed'; else ok 'a prefix of a failed path is not failed'; fi
fetch_failed_list=""
if fetch_failed "$F/dest/solo"; then no 'nothing failed: nothing is failed'; else ok 'nothing failed: nothing is failed'; fi

is 'origin_ref reads an existing ref' "$(origin_ref "$F/dest/solo" origin/main)" "$(git -C "$F/solo.git" rev-parse main)"
is 'origin_ref prints nothing for a missing ref (not its name)' "$(origin_ref "$F/dest/solo" origin/nope)" ''
is 'origin_ref falls back to the next ref' "$(origin_ref "$F/dest/solo" origin/nope origin/main)" "$(git -C "$F/solo.git" rev-parse main)"

# Through check_series itself: the umbrella's origin/main is ahead of its HEAD
# and the submodule's ahead of the recorded commit, so both would fail if
# compared — a NOT checked line is the only way to pass these.
series_run() {  # LABEL WANT-SKIPPED WANT-LINE REFUSED-LINE — check_series in this shell
  errors=0; skipped=0
  check_series a-series "$F/dest/a-series" > "$TMP/series.out" 2>&1
  if [ "$skipped" = "$2" ] && grep -qF -- "$3" "$TMP/series.out" && ! grep -qF -- "$4" "$TMP/series.out"; then ok "$1"; else
    no "$1"; printf '        skipped=%s\n' "$skipped" >&2; grep -E 'remote|sub:' "$TMP/series.out" >&2
  fi
}
fetch_failed_list="$F/dest/a-series/sub"
series_run 'a submodule whose fetch failed is NOT checked, not compared' 1 \
  'sub: could not fetch origin — NOT checked' 'sub: out of sync'
fetch_failed_list="$F/dest/a-series"
series_run 'an umbrella whose fetch failed is NOT checked, not compared' 1 \
  'remote: could not fetch origin — NOT checked' 'remote: local diverged'
fetch_failed_list=""
git -C "$F/dest/a-series/sub" update-ref -d refs/remotes/origin/main
series_run 'a submodule without origin/main is NOT checked, not "out of sync"' 1 \
  'sub: no origin/main — NOT checked' 'sub: out of sync'
git -C "$F/dest/a-series" update-ref -d refs/remotes/origin/main
( set -euo pipefail; check_series a-series "$F/dest/a-series"; echo 'REACHED THE END' ) > "$TMP/series.out" 2>&1
if grep -qF 'remote: no origin/main or origin/master — NOT checked' "$TMP/series.out" \
   && grep -qF 'REACHED THE END' "$TMP/series.out"; then
  ok 'an umbrella without a remote branch is NOT checked, and the run goes on under set -e'
else
  no 'an umbrella without a remote branch is NOT checked, and the run goes on under set -e'
  tail -5 "$TMP/series.out" >&2
fi
errors=0; skipped=0

# ---- each_submodule: one listing per series, replayed to every loop ----------
series_submodules=$'        a\n        b/c'
is 'each_submodule replays the listing line by line' "$(each_submodule | wc -l | tr -d ' ')" 2
series_submodules=""
_n=0; while IFS= read -r _l; do _n=$((_n + 1)); done < <(each_submodule)
is 'a series without submodules runs no loop iteration (not one empty one)' "$_n" 0

unset GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0 GIT_CONFIG_KEY_1 GIT_CONFIG_VALUE_1 \
  GIT_CONFIG_KEY_2 GIT_CONFIG_VALUE_2 GIT_CONFIG_KEY_3 GIT_CONFIG_VALUE_3 GIT_CONFIG_KEY_4 GIT_CONFIG_VALUE_4

echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
