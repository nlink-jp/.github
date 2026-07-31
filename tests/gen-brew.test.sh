#!/bin/sh
# gen-brew.test.sh — shell test harness for templates/gen-brew.sh.
# Run: sh .github/tests/gen-brew.test.sh
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GEN="$HERE/../templates/gen-brew.sh"
TPL_DIR="$HERE/../templates"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok() { printf 'ok   - %s\n' "$1"; pass=$((pass + 1)); }
no() { printf 'FAIL - %s\n' "$1"; fail=$((fail + 1)); }

contains() { # haystack needle label
  if printf '%s' "$1" | grep -qF -- "$2"; then ok "$3"; else
    no "$3"; printf '        expected to contain: %s\n' "$2" >&2
  fi
}
missing() { # haystack needle label   (asserts needle is ABSENT)
  if printf '%s' "$1" | grep -qF -- "$2"; then
    no "$3"; printf '        expected NOT to contain: %s\n' "$2" >&2
  else ok "$3"; fi
}
expect_fail() { # label ; then command via "$@" after label
  _label="$1"; shift
  if out=$("$@" 2>&1); then
    no "$_label (expected non-zero exit)"; printf '        got success:\n%s\n' "$out" >&2
  else ok "$_label"; fi
}

mkzip() { # path member-name  -> makes a zip named <path> containing a dummy file
  d=$(mktemp -d)
  echo "dummy" > "$d/$2"
  ( cd "$d" && zip -q "$1" "$2" )
  rm -rf "$d"
}

# ---- fixtures --------------------------------------------------------------
FZIP="$TMP/gem-search-v0.4.0-darwin-arm64.zip"
mkzip "$FZIP" gem-search
FSHA=$(shasum -a 256 "$FZIP" | awk '{print $1}')

LZIP="$TMP/llm-cli-v0.2.0-darwin-arm64.zip"
mkzip "$LZIP" llm-cli

CZIP="$TMP/csv-editor-v0.2.1-darwin-arm64.zip"
mkzip "$CZIP" csv-editor.app

# ---- 1. formula --print ----------------------------------------------------
out=$(BREW_KIND=formula BREW_DESC="Agentic web search CLI using Vertex AI Grounding" \
      BREW_TEMPLATES_DIR="$TPL_DIR" sh "$GEN" --print "$FZIP")
contains "$out" 'class GemSearch < Formula'                                       'formula: class name kebab->camel'
contains "$out" 'url "https://github.com/nlink-jp/gem-search/releases/download/v0.4.0/gem-search-v0.4.0-darwin-arm64.zip"' 'formula: url with parsed version'
contains "$out" 'version "0.4.0"'                                                 'formula: version parsed (no v)'
contains "$out" "sha256 \"$FSHA\""                                                'formula: sha256 of real artifact'
contains "$out" 'bin.install "gem-search"'                                        'formula: canonical bin.install'
contains "$out" 'desc "Agentic web search CLI using Vertex AI Grounding"'         'formula: desc rendered'
missing  "$out" '@'                                                               'formula: no unrendered @PLACEHOLDER@'

# ---- 2. class-name edge (llm-cli -> LlmCli) --------------------------------
out=$(BREW_KIND=formula BREW_DESC="x" BREW_TEMPLATES_DIR="$TPL_DIR" sh "$GEN" --print "$LZIP")
contains "$out" 'class LlmCli < Formula'                                          'formula: multi-seg class name'
contains "$out" 'bin.install "llm-cli"'                                           'formula: multi-seg bin.install'

# ---- 2b. BREW_REPO: repo slug differs from tool/binary name ----------------
MZIP="$TMP/mdv-v1.4.0-darwin-arm64.zip"
mkzip "$MZIP" mdv
out=$(BREW_KIND=formula BREW_DESC="Markdown viewer" BREW_REPO="markdown-viewer" \
      BREW_TEMPLATES_DIR="$TPL_DIR" sh "$GEN" --print "$MZIP")
contains "$out" 'class Mdv < Formula'                                             'brew_repo: class from asset name (mdv)'
contains "$out" 'bin.install "mdv"'                                               'brew_repo: bin.install asset name'
contains "$out" 'homepage "https://github.com/nlink-jp/markdown-viewer"'          'brew_repo: homepage uses repo slug'
contains "$out" 'url "https://github.com/nlink-jp/markdown-viewer/releases/download/v1.4.0/mdv-v1.4.0-darwin-arm64.zip"' 'brew_repo: url = repo slug + asset name'

# ---- 3. cask --print -------------------------------------------------------
out=$(BREW_KIND=cask BREW_DESC="Viewer and editor for CSV and TSV files" \
      BREW_APP="csv-editor.app" BREW_BUNDLE_ID="com.wails.csv-editor" \
      BREW_TEMPLATES_DIR="$TPL_DIR" sh "$GEN" --print "$CZIP")
contains "$out" 'cask "csv-editor" do'                                            'cask: token'
contains "$out" 'version "0.2.1"'                                                 'cask: version parsed'
contains "$out" 'app "csv-editor.app"'                                            'cask: app stanza'
contains "$out" 'url "https://github.com/nlink-jp/csv-editor/releases/download/v#{version}/csv-editor-v#{version}-darwin-arm64.zip"' 'cask: url keeps #{version}'
contains "$out" '"~/Library/Caches/com.wails.csv-editor",'                        'cask: zap uses bundle id'
contains "$out" 'depends_on macos: :big_sur'                                      'cask: default macOS floor :big_sur'
missing  "$out" '@'                                                               'cask: no unrendered @PLACEHOLDER@'

# ---- 3b. BREW_MACOS_FLOOR overrides the cask macOS floor -------------------
out=$(BREW_KIND=cask BREW_DESC="Viewer and editor for CSV and TSV files" \
      BREW_APP="csv-editor.app" BREW_BUNDLE_ID="com.wails.csv-editor" \
      BREW_MACOS_FLOOR=":tahoe" \
      BREW_TEMPLATES_DIR="$TPL_DIR" sh "$GEN" --print "$CZIP")
contains "$out" 'depends_on macos: :tahoe'                                        'macos_floor: override rendered'
missing  "$out" ':big_sur'                                                        'macos_floor: default absent when overridden'

# ---- 4. --no-push writes + commits into a tap, does not push ---------------
TAP="$TMP/homebrew-tap"
mkdir -p "$TAP/Formula" "$TAP/Casks"
git -C "$TAP" init -q
git -C "$TAP" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
BREW_KIND=formula BREW_DESC="d" BREW_TEMPLATES_DIR="$TPL_DIR" BREW_TAP_DIR="$TAP" \
  git -C "$TAP" config user.name t
BREW_KIND=formula BREW_DESC="d" BREW_TEMPLATES_DIR="$TPL_DIR" BREW_TAP_DIR="$TAP" \
  git -C "$TAP" config user.email t@t
out=$(BREW_KIND=formula BREW_DESC="d" BREW_TEMPLATES_DIR="$TPL_DIR" BREW_TAP_DIR="$TAP" \
      sh "$GEN" --no-push "$FZIP" 2>&1)
[ -f "$TAP/Formula/gem-search.rb" ] && ok "no-push: formula written" || no "no-push: formula written"
if git -C "$TAP" log --oneline | grep -q 'gem-search 0.4.0 (formula)'; then ok "no-push: committed"; else no "no-push: committed"; fi
contains "$out" 'leaving commit unpushed'                                         'no-push: push skipped'

# ---- 5. idempotence: second run reports up-to-date -------------------------
out=$(BREW_KIND=formula BREW_DESC="d" BREW_TEMPLATES_DIR="$TPL_DIR" BREW_TAP_DIR="$TAP" \
      sh "$GEN" --no-push "$FZIP" 2>&1)
contains "$out" 'already up to date'                                              'idempotent: no duplicate commit'

# ---- 6. error cases --------------------------------------------------------
expect_fail "err: bad BREW_KIND"      env BREW_KIND=bogus BREW_DESC=d BREW_TEMPLATES_DIR="$TPL_DIR" sh "$GEN" --print "$FZIP"
expect_fail "err: missing BREW_DESC"  env BREW_KIND=formula BREW_TEMPLATES_DIR="$TPL_DIR" sh "$GEN" --print "$FZIP"
expect_fail "err: bad asset name"     env BREW_KIND=formula BREW_DESC=d BREW_TEMPLATES_DIR="$TPL_DIR" sh "$GEN" --print "$TMP/notes.txt"
expect_fail "err: cask missing APP"   env BREW_KIND=cask BREW_DESC=d BREW_BUNDLE_ID=x BREW_TEMPLATES_DIR="$TPL_DIR" sh "$GEN" --print "$CZIP"
expect_fail "err: floor missing colon" env BREW_KIND=cask BREW_DESC=d BREW_APP=csv-editor.app BREW_BUNDLE_ID=x BREW_MACOS_FLOOR=tahoe BREW_TEMPLATES_DIR="$TPL_DIR" sh "$GEN" --print "$CZIP"
expect_fail "err: missing zip file"   env BREW_KIND=formula BREW_DESC=d BREW_TEMPLATES_DIR="$TPL_DIR" sh "$GEN" --print "$TMP/absent-v1.0.0-darwin-arm64.zip"
expect_fail "err: --no-push, tap absent" env BREW_KIND=formula BREW_DESC=d BREW_TEMPLATES_DIR="$TPL_DIR" BREW_TAP_DIR="$TMP/nope" sh "$GEN" --no-push "$FZIP"

# ---- summary ---------------------------------------------------------------
echo "------------------------------------------------------------"
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
