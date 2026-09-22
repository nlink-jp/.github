#!/usr/bin/env bash
# check-org.sh — Health check for all nlink-jp series repositories.
#
# Usage:
#   ./check-org.sh [DEST_DIR]
#
# Exit code: 0 only when every repository was found AND every check
# passed. 1 when any check fails — or when any repository was not found
# locally, because a repo that was not examined is not a passing repo.

set -euo pipefail

SERIES=(
  chatops-series
  cli-series
  cybersecurity-series
  lab-series
  lib-series
  lite-series
  skills-series
  util-series
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# default_dest — the org root this script belongs to: the script lives at
# <org-root>/.github/scripts/, so the root is two levels up. Deriving the
# root from $PWD was measured producing an all-green run that had checked
# nothing: invoked from the wrong cwd, every repo was "not found locally",
# the misses were warnings, and the summary still said "all checks
# passed". The caller's cwd must never decide what this script examines.
default_dest() { CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd; }

DEST="${1:-$(default_dest)}"
DEST="$(cd "$DEST" && pwd)"

PASS="[OK]"
FAIL="[NG]"
WARN="[!!]"

errors=0
skipped=0

# verdict ERRORS SKIPPED — the one summary line, and the exit status.
# A repository that was not examined is not a passing repository: skips
# make the run INCOMPLETE and the status non-zero, so a green summary
# always means "every repo examined, every check passed" — the check
# must never claim more than it verified.
verdict() {
  local errs="$1" skips="$2" msg=""
  if [ "$errs" -eq 0 ] && [ "$skips" -eq 0 ]; then
    echo "Result: all checks passed."
    return 0
  fi
  [ "$errs" -gt 0 ] && msg="$errs check(s) failed."
  if [ "$skips" -gt 0 ]; then
    [ -n "$msg" ] && msg="$msg "
    msg="${msg}INCOMPLETE — $skips repo(s) not found locally; their checks did not run."
  fi
  echo "Result: $msg"
  return 1
}

# --- archived repositories ---------------------------------------------------
# GitHub is the authority: an archived repo is read-only, so it can never take
# a template update and must not be judged against live templates. One org
# listing serves the whole run. When gh is unavailable (offline, or no auth)
# the umbrella catalog's "(archived)" marker stands in — best effort rather
# than a hard dependency, since this script is otherwise fully offline.
archived_list=""
archived_loaded=0

load_archived() {
  [ "$archived_loaded" -eq 1 ] && return 0
  archived_loaded=1
  command -v gh >/dev/null 2>&1 || return 0
  archived_list=$(gh repo list nlink-jp --limit 300 --json name,isArchived \
    --jq '.[] | select(.isArchived) | .name' 2>/dev/null) || archived_list=""
  return 0
}

# is_archived NAME UMBRELLA_DIR
is_archived() {
  local name="$1" dir="$2"
  load_archived
  if [ -n "$archived_list" ]; then
    printf '%s\n' "$archived_list" | grep -qx -- "$name"
    return $?
  fi
  grep -q "\[$name\].*(archived)" "$dir/README.md" 2>/dev/null
}

# --- released repositories ---------------------------------------------------
# Same shape as the archived listing: one org query, cached for the run, and
# absent when gh is unavailable. Used to catch a README that still calls a
# shipped tool unreleased — a claim that is true when written and only becomes
# false at the first release, which is why nothing catches it otherwise.
released_list=""
released_loaded=0

load_released() {
  [ "$released_loaded" -eq 1 ] && return 0
  released_loaded=1
  command -v gh >/dev/null 2>&1 || return 0
  released_list=$(gh repo list nlink-jp --limit 300 --json name,latestRelease \
    --jq '.[] | select(.latestRelease != null) | .name' 2>/dev/null) || released_list=""
  return 0
}

# has_release NAME — false when gh is unavailable, so the check stays quiet
# rather than accusing every repo of lying.
has_release() {
  load_released
  [ -n "$released_list" ] || return 1
  printf '%s\n' "$released_list" | grep -qx -- "$1"
}

# unreleased_claims — line filter: echoes README lines claiming nothing has
# shipped. Deliberately narrow; "pre-release smoke test" is a procedure, not a
# status, and must not trip this.
unreleased_claim_re='[Nn]ot yet released|[Nn]ot released yet|未リリース|プレリリース|[Pp]re-release[.:：]'

unreleased_claims() {
  grep -E "$unreleased_claim_re" || true
}

# --- leaked home directories -------------------------------------------------
# An absolute path like /Users/<name>/ in a tracked file publishes a username
# and a local directory layout. The hard part is telling a leak from an example:
# docs and tests are full of legitimate fake homes (/Users/you, /Users/test,
# /Users/tester, /Users/yourname, /home/u), and an allowlist of invented names
# is a losing game — flagging them all is how a check gets ignored.
#
# So this matches on the *account name* instead, supplied by the caller. In
# practice that is whoever runs this script, which is precisely the
# pasted-from-my-machine case that produces real leaks.
#
# Limitation, stated rather than papered over: a username belonging to some
# other machine is not detected. For a single-operator org that is the whole
# population; for a team, pass every account you want covered.

# home_path_leaks ACCOUNT... — line filter: echoes lines naming one of these
# accounts under /Users or /home.
home_path_leaks() {
  local re
  [ "$#" -gt 0 ] || { cat >/dev/null; return 0; }
  re=$(printf '%s|' "$@")
  grep -E "/(Users|home)/(${re%|})([^A-Za-z0-9._-]|$)" || true
}

# local_accounts — the account names this machine could leak.
local_accounts() {
  { id -un 2>/dev/null; [ -n "${HOME:-}" ] && basename "$HOME"; } | sort -u | grep -v '^$'
}

# --- cask macOS floor --------------------------------------------------------
# A cask's `depends_on macos:` is what Homebrew checks before installing. The
# shared template defaults it to :big_sur, and nothing fails when that is wrong:
# the cask installs on a Mac the app cannot launch on. Ten casks stood that way,
# two of them re-issued after the lesson had been written down. The deployment
# target in Package.swift is the fact; the cask has to say the same.

# package_macos_major PACKAGE_SWIFT -> the deployment target's major version,
# from `.macOS(.v14)` or `.macOS("26.0")`. Empty when there is none.
package_macos_major() {
  sed -n -E \
    -e 's/.*\.macOS\(\.v([0-9]+)\).*/\1/p' \
    -e 's/.*\.macOS\("([0-9]+)[^"]*"\).*/\1/p' "$1" 2>/dev/null | head -1
}

# macos_symbol_for MAJOR -> Homebrew's symbol for that release. The names are
# not the marketing names; the authority is `brew ruby -e 'puts
# MacOSVersion::SYMBOLS'`. An unknown major prints nothing, and the caller
# fails rather than skips: a new macOS every year must not quietly switch this
# check off.
macos_symbol_for() {
  case "$1" in
    11) echo ":big_sur" ;;   12) echo ":monterey" ;; 13) echo ":ventura" ;;
    14) echo ":sonoma" ;;    15) echo ":sequoia" ;;  26) echo ":tahoe" ;;
    27) echo ":golden_gate" ;;
  esac
}

# cask_macos_floor CASK_RB -> the symbol in `depends_on macos:`, whether written
# bare (`:sonoma`) or as a comparison (`">= :sonoma"`). Empty when absent.
cask_macos_floor() {
  sed -n -E 's/^[[:space:]]*depends_on[[:space:]]+macos:[[:space:]]*"?(>=[[:space:]]*)?(:[a-z_]+)"?.*/\2/p' "$1" 2>/dev/null | head -1
}

# --- language mirrors -------------------------------------------------------
# CONVENTIONS.md separates documents by language: README.md paired with
# README.ja.md, docs/en/x.md paired with docs/ja/x.ja.md, and no flat docs/
# tree. Nothing held any series member to that, and a sweep on 2026-09-21 found
# 24 documents with no counterpart, 22 Japanese files without the .ja.md
# suffix, and one repository whose Japanese records were filed under docs/en.
# A rule nobody checks is a rule that drifts.

# ja_counterpart PATH -> where the Japanese counterpart of an English document
# belongs. README.md pairs with README.ja.md at the root; docs/en/<rel>.md pairs
# with docs/ja/<rel>.ja.md.
ja_counterpart() {
  case "$1" in
    README.md) echo "README.ja.md" ;;
    docs/en/*.md) echo "docs/ja/${1#docs/en/}" | sed -E 's/\.md$/.ja.md/' ;;
  esac
}

# en_counterpart PATH -> the English counterpart of a Japanese document.
en_counterpart() {
  case "$1" in
    README.ja.md) echo "README.md" ;;
    docs/ja/*.ja.md) echo "docs/en/${1#docs/ja/}" | sed -E 's/\.ja\.md$/.md/' ;;
  esac
}

# mirror_problems REPO_DIR — one line per document whose counterpart is missing,
# whose name lacks the .ja.md suffix, or which sits in a flat docs/ tree.
# Silent when the repository is consistent.
#
# The listing is classified here rather than by pathspec on purpose: in a git
# pathspec `*` matches slashes as well, so `docs/*.md` also selects
# docs/en/adr/0001-x.md and every document looks misfiled.
mirror_problems() {
  local dir="$1" rel want
  [ -d "$dir" ] || return 0
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    case "$rel" in
      *.md) ;;
      *) continue ;;
    esac
    case "$rel" in
      README.md|docs/en/*)
        want=$(ja_counterpart "$rel")
        [ -n "$want" ] || continue
        [ -f "$dir/$want" ] || echo "$rel: no Japanese counterpart at $want"
        ;;
      README.ja.md|docs/ja/*)
        case "$rel" in
          *.ja.md)
            want=$(en_counterpart "$rel")
            [ -z "$want" ] || [ -f "$dir/$want" ] || echo "$rel: no English counterpart at $want"
            ;;
          *) echo "$rel: a Japanese document needs the .ja.md suffix" ;;
        esac
        ;;
      docs/*)
        # A layout warning, not a missing document: the text exists and reads
        # fine, it is only filed where the convention does not put it. Held
        # apart so a repository that satisfies the pairing rules can still be
        # green while the org works through the layout.
        echo "WARN $rel: documents are separated by language (docs/en, docs/ja)"
        ;;
    esac
  done < <(cd "$dir" && git ls-files README.md README.ja.md docs 2>/dev/null)
}

# --- document references -----------------------------------------------------
# The mirror check above compares a pair of documents to each other, and a pair
# can be flawless while every link *into* it is dead. The 2026-09-21 language
# split proved it: the pairs came out symmetric, and 55 markdown links across 6
# repositories still pointed at paths the split had moved — including release
# entries in CHANGELOG.md, where the link is the reader's only route to the
# record. Nothing resolved a reference, so nothing noticed.

# doc_link_targets FILE — one relative link target per line.
#
# Code is excluded: a path inside a fenced block or an inline span is shown to
# the reader as text, not offered as a link, so `docs/adr/0009` in a command
# example is not a broken reference. External schemes, protocol-relative and
# absolute paths are left alone — this check resolves what the repository owns.
doc_link_targets() {
  awk '
    /^[[:space:]]*```/ { fence = !fence; next }
    fence { next }
    {
      line = $0
      gsub(/`[^`]*`/, "", line)
      while (match(line, /\[[^]]*\]\([^)[:space:]]+\)/)) {
        m = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
        sub(/^\[[^]]*\]\(/, "", m)
        sub(/\)$/, "", m)
        sub(/#.*$/, "", m)
        if (m != "" && m !~ /^[a-zA-Z][a-zA-Z0-9+.-]*:/ && m !~ /^\// ) print m
      }
    }
  ' "$1"
}

# broken_links REPO_DIR — one line per link whose target does not exist.
# Silent when every reference resolves.
broken_links() {
  local dir="$1" rel base target
  [ -d "$dir" ] || return 0
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    # Upstream copies carry their own broken references and are not ours to fix.
    case "$rel" in
      third_party/*|vendor/*|Vendor/*|node_modules/*) continue ;;
    esac
    base=$(dirname "$rel")
    while IFS= read -r target; do
      [ -n "$target" ] || continue
      # Resolved by cd'ing to the document's own directory, so ../ and ./
      # behave exactly as they do for a reader following the link. The subshell
      # keeps the caller's working directory out of it.
      ( cd "$dir/$base" && [ -e "$target" ] ) || echo "$rel -> $target"
    done < <(doc_link_targets "$dir/$rel")
    # Here a pathspec's `*` matching slashes is what is wanted: every .md in
    # the repository, at any depth.
  done < <(cd "$dir" && git ls-files '*.md' '*.toml' 2>/dev/null)
}

# --- release-gate form ---------------------------------------------------------
# The CLI release gate's last block used to chain unzip, the packaged binary's
# --version and spctl into one statement ending in `|| true`. The escape covered
# all of it: a zip that did not unpack, or a binary that did not run, exited 0
# and the release uploaded it. Measured against both forms with a six-state
# exercise, the open form accepts three of the six (another tag, does not
# unpack, does not run).
#
# 59 repositories carried it; all were converted on 2026-09-21
# (scripts/close-verify-release-gate.py, exercised by
# scripts/exercise-release-gate.sh). This check exists so a hand-edited recipe,
# or one pasted from an old copy, cannot bring it back: the template it would
# come from is already fixed, so what is left to guard is the copy.

# open_release_gate MAKEFILE — non-empty when the file has a verify-release
# target whose recipe still ends its check chain in `|| true` instead of
# judging each step and exiting on rc. GUI (.app) gates are a different recipe
# — stapler validate, no `|| true` — and are silent here.
open_release_gate() {
  local f="$1"
  [ -f "$f" ] || return 0
  grep -q '^verify-release:' "$f" || return 0
  grep -qF 'exit $$rc' "$f" && return 0
  grep -qF 'head -2 || true' "$f" || return 0
  echo "verify-release chains its checks into one statement ending in '|| true'"
}

# --- running images (this machine) is NOT here; see scripts/stale-running-images.sh
# --- bundled CLI (GUI apps that ship a sibling CLI inside them) ----------------
# Six GUIs copy a sibling CLI into Contents/Resources, and a release build
# resolves that bundled copy first — no environment variable can redirect it. So
# a CLI release reaches those GUIs' users only when the GUI is rebuilt and
# released too. That follow-up was missed twice in one day (image-forge-gui,
# active-lens-gui), both times caught by the maintainer rather than by anything
# here. Each bundler's Makefile now pins the CLI it ships (CLI_VERSION, enforced
# by its own verify-release); this compares the pin with the CLI's latest release.
#
# Limit, stated: the pin says what the next GUI build will bundle, not what the
# published GUI contains. A pin that was bumped but never released reads green
# here; the tap-currency check and the release checklist cover that half.

# bundled_cli_pin MAKEFILE -> "<cli> <pin>" for a GUI that bundles a sibling
# CLI, "<cli> -" when it bundles one without a pin, and nothing otherwise.
bundled_cli_pin() {
  local f="$1" cli pin
  [ -f "$f" ] || return 0
  cli=$(sed -n -E 's|^CLI_BIN[[:space:]]*[?:]?=.*\.\./([a-z0-9-]+)/dist/.*|\1|p' "$f" | head -1)
  [ -n "$cli" ] || return 0
  pin=$(sed -n -E 's/^CLI_VERSION[[:space:]]*[?:]?=[[:space:]]*([^[:space:]#]+).*/\1/p' "$f" | head -1)
  printf '%s %s\n' "$cli" "${pin:--}"
}

# --- tap currency --------------------------------------------------------------
# A release is not delivered until the tap points at it: `brew upgrade` reads the
# formula, so a formula left on the previous version means the release exists and
# nobody receives it. This went unnoticed for two releases of one tool while
# every check was green — check 10 compares the *vendored tap-generation scripts*
# against the templates and never asks what the formula targets. The release
# checklist's `make brew` step is the fix; this is the check that catches a
# release where it was skipped.

# brew_version FILE -> the release a formula or cask points at, without the "v".
# A cask states `version "X.Y.Z"` and interpolates it into the url; a formula
# carries the tag in the url itself. An unreadable version is reported by the
# caller rather than treated as a match — silence here would hide the drift the
# check exists for.
brew_version() {
  local f="$1" v
  v=$( { grep -oE '^[[:space:]]*version "[0-9]+\.[0-9]+\.[0-9]+"' "$f" 2>/dev/null |
           head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'; } || true)
  if [ -z "$v" ]; then
    v=$( { grep -oE 'releases/download/v?[0-9]+\.[0-9]+\.[0-9]+' "$f" 2>/dev/null |
             head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'; } || true)
  fi
  printf '%s' "$v"
}

# --- Makefile build-output resolution ---------------------------------------
# The convention is that `make build` writes into dist/. What matters is the
# resolved *value* of the output path, not the variable name used to spell it:
# `BIN_DIR := dist` is perfectly conventional. These helpers resolve the
# directory a Makefile actually builds into, so the check can compare values.

# makefile_var MAKEFILE VAR -> value of the last assignment to VAR.
# Handles `VAR = v`, `VAR := v`, `VAR ?= v`, `VAR += v` at the start of a line,
# plus the `$(eval VAR := v)` form used inside some recipes. Trailing comments
# and whitespace are stripped.
makefile_var() {
  local mf="$1" var="$2"
  sed -nE \
    -e "s/^[[:space:]]*${var}[[:space:]]*[:?+]?=[[:space:]]*([^#]*).*\$/\1/p" \
    -e "s/.*\\\$\\(eval[[:space:]]+${var}[[:space:]]*[:?+]?=[[:space:]]*(.*)\\).*/\1/p" \
    "$mf" 2>/dev/null | tail -1 | sed -E 's/[[:space:]]+$//'
}

# makefile_expand MAKEFILE STRING -> STRING with $(VAR) references expanded
# from the Makefile's own assignments. Stops at the first reference it cannot
# resolve (an unassigned variable, or a function call such as $(word ...)),
# leaving it literal for the caller to notice.
makefile_expand() {
  local mf="$1" s="$2" var val pat i
  for i in 1 2 3 4 5 6 7 8; do
    case "$s" in *'$('*) ;; *) break ;; esac
    var="${s#*"\$("}"
    var="${var%%)*}"
    case "$var" in ''|*[^A-Za-z0-9_]*) break ;; esac
    val=$(makefile_var "$mf" "$var")
    [ -n "$val" ] || break
    # The pattern must come from a variable: an inline ${s//\$($var)/$val}
    # silently fails to substitute in bash. Do not "simplify" this.
    pat="\$($var)"
    s="${s//"$pat"/$val}"
  done
  printf '%s' "$s"
}

# makefile_build_dirs MAKEFILE -> one line per `go build ... -o TARGET` recipe,
# holding the directory that target resolves to:
#   dist       conventional
#   .          the project root
#   ?          could not be resolved — the caller must not guess
makefile_build_dirs() {
  local mf="$1" line target dir prefix had_var
  while IFS= read -r line; do
    # Cheap pre-filter, then confirm on the expanded line so that builds routed
    # through a variable (GO_BUILD := go build ...) are seen too.
    case "$line" in *-o*) ;; *) continue ;; esac
    printf '%s\n' "$(makefile_expand "$mf" "$line")" \
      | grep -qE 'go[[:space:]]+build' || continue

    # The target is taken from the raw line (so expanded flag values can never
    # be mistaken for it) and only then resolved.
    target=$(printf '%s\n' "$line" \
      | awk '{for (i=1;i<NF;i++) if ($i=="-o") {print $(i+1); exit}}')
    [ -n "$target" ] || continue
    [ "$target" = "/dev/null" ] && continue   # discard build, not an artifact

    target=$(makefile_expand "$mf" "$target")
    had_var=0
    case "$target" in *'$('*) had_var=1 ;; esac
    prefix="${target%%"\$("*}"                # text before the first $( , if any
    case "$prefix" in
      */*) dir="${prefix%/*}"
           dir="${dir#./}"
           dir="${dir%/}"
           [ -n "$dir" ] || dir="." ;;
      *)   if [ "$had_var" -eq 1 ]; then dir="?"; else dir="."; fi ;;
    esac
    # A shell variable in the path (release staging dirs use $$stagedir) is not
    # resolvable from the Makefile alone.
    case "$dir" in *'$'*) dir="?" ;; esac
    printf '%s\n' "$dir"
  done < "$mf"
}

check_series() {
  local series="$1"
  local dir="$2"

  echo "==> $series"

  # 1. Remote sync
  git -C "$dir" fetch --quiet origin 2>/dev/null
  local_sha=$(git -C "$dir" rev-parse HEAD)
  remote_sha=$(git -C "$dir" rev-parse origin/main 2>/dev/null || git -C "$dir" rev-parse origin/master 2>/dev/null)
  if [ "$local_sha" = "$remote_sha" ]; then
    echo "    $PASS remote: in sync"
  else
    echo "    $FAIL remote: local diverged from origin"
    errors=$((errors + 1))
  fi

  # 2. Clean working tree
  dirty=$(git -C "$dir" status --porcelain)
  if [ -z "$dirty" ]; then
    echo "    $PASS working tree: clean"
  else
    echo "    $FAIL working tree: dirty"
    git -C "$dir" status --short | sed 's/^/        /'
    errors=$((errors + 1))
  fi

  # 3. .gitignore excludes .claude/settings.local.json
  if grep -qE "^\.claude/settings\.local\.json$|^\.claude/$" "$dir/.gitignore" 2>/dev/null; then
    echo "    $PASS .gitignore: .claude/settings.local.json excluded"
  else
    echo "    $FAIL .gitignore: missing .claude/settings.local.json"
    errors=$((errors + 1))
  fi

  # 4. No .claude/settings.local.json tracked in git
  if git -C "$dir" ls-files --error-unmatch ".claude/settings.local.json" &>/dev/null; then
    echo "    $FAIL tracked: .claude/settings.local.json is in git index"
    errors=$((errors + 1))
  else
    echo "    $PASS tracked: no .claude/settings.local.json in git index"
  fi

  # 5. CLAUDE.md exists
  if [ -f "$dir/CLAUDE.md" ]; then
    echo "    $PASS CLAUDE.md: present"
  else
    echo "    $FAIL CLAUDE.md: missing"
    errors=$((errors + 1))
  fi

  # 5b. Umbrella standard file set (ADR-005): README.md and AGENTS.md
  local f
  for f in README.md AGENTS.md; do
    if [ -f "$dir/$f" ]; then
      echo "    $PASS $f: present"
    else
      echo "    $FAIL $f: missing (ADR-005 umbrella standard)"
      errors=$((errors + 1))
    fi
  done

  # 5c. Every submodule has a catalog row in README.md (ADR-005).
  # The README is the umbrella's only catalog surface; a submodule absent
  # from it is invisible to anyone browsing the series.
  if [ -f "$dir/.gitmodules" ] && [ -f "$dir/README.md" ]; then
    local missing=""
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      name=$(basename "$subpath")
      grep -q "github.com/nlink-jp/$name" "$dir/README.md" || missing="$missing $name"
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
    if [ -z "$missing" ]; then
      echo "    $PASS README.md: every submodule cataloged"
    else
      echo "    $FAIL README.md: no catalog row for:$missing"
      errors=$((errors + 1))
    fi
  fi

  # 5d. Submodule URLs are HTTPS (SSH fails on machines without key auth)
  if [ -f "$dir/.gitmodules" ]; then
    local non_https
    non_https=$(git config -f "$dir/.gitmodules" --get-regexp '^submodule\..*\.url$' \
      | awk '{print $2}' | grep -v '^https://' || true)
    if [ -z "$non_https" ]; then
      echo "    $PASS .gitmodules: all URLs HTTPS"
    else
      echo "    $FAIL .gitmodules: non-HTTPS URL(s): $(echo $non_https | tr '\n' ' ')"
      errors=$((errors + 1))
    fi
  fi

  # 5e. No archived repository is registered in an active series umbrella.
  # Archived repos are read-only, so every org-wide sweep that walks one does
  # work that can never be committed — and a local scan cannot tell it is dead,
  # because the only authority is GitHub. They belong in nlink-jp/archive-series,
  # whose directory layout makes "is this alive, and what was it?" answerable
  # from the filesystem. This is the inverse of the skip in check 10: name the
  # misfiling rather than work around it. Silent when gh is unavailable.
  if [ -f "$dir/.gitmodules" ]; then
    load_archived
    if [ -n "$archived_list" ]; then
      local misfiled=""
      while IFS= read -r subpath; do
        subpath="${subpath#        }"
        name=$(basename "$subpath")
        if printf '%s\n' "$archived_list" | grep -qx -- "$name"; then
          misfiled="$misfiled $name"
        fi
      done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
      if [ -z "$misfiled" ]; then
        echo "    $PASS no archived repository registered here"
      else
        echo "    $FAIL archived repo(s) still registered:$misfiled"
        echo "         move them to nlink-jp/archive-series — see its README,"
        echo "         \"Adding a newly archived project\""
        errors=$((errors + 1))
      fi
    fi
  fi

  # 6. Submodule build conventions
  if [ -f "$dir/.gitmodules" ]; then
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$dir/$subpath"
      name=$(basename "$subpath")
      makefile="$subdir/Makefile"
      gitignore="$subdir/.gitignore"

      if [ -f "$makefile" ]; then
        # Check: make build must output to dist/. Compared on the resolved
        # value, so any variable name is fine (BIN_DIR := dist passes).
        while IFS= read -r outdir; do
          case "$outdir" in
            dist|dist/*) continue ;;   # conventional
            '?')         continue ;;   # unresolvable — don't guess
            .) echo "    $FAIL $name: make build outputs to project root (must use dist/)" ;;
            *) echo "    $FAIL $name: make build outputs to $outdir/ (must use dist/)" ;;
          esac
          errors=$((errors + 1))
          break
        done < <(makefile_build_dirs "$makefile")
      fi

      if [ -f "$gitignore" ]; then
        # Check: bare binary name in .gitignore (no leading /)
        if grep -qxF "$name" "$gitignore" 2>/dev/null; then
          echo "    $FAIL $name: .gitignore has bare '$name' (may exclude cmd/$name/)"
          errors=$((errors + 1))
        fi
        # Check: dist/ must be excluded
        if [ -f "$makefile" ] && grep -q 'dist/' "$makefile" 2>/dev/null; then
          if ! grep -qE '^/?dist/?$' "$gitignore" 2>/dev/null; then
            echo "    $FAIL $name: .gitignore missing 'dist/'"
            errors=$((errors + 1))
          fi
        fi
      fi
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 7. Scan for likely secrets in tracked files
  if [ -f "$dir/.gitmodules" ]; then
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$dir/$subpath"
      name=$(basename "$subpath")

      # Scan tracked files for common secret patterns
      secret_hits=$(git -C "$subdir" grep -lE \
        '\.iam\.gserviceaccount\.com|xoxb-[0-9]|xoxp-[0-9]|sk-ant-|AKIA[A-Z0-9]{16}' \
        HEAD -- '*.yaml' '*.yml' '*.json' '*.toml' '*.env' '*.sh' 2>/dev/null \
        | grep -v 'example\|template\|test\|README\|CHANGELOG\|\.md$' || true)
      if [ -n "$secret_hits" ]; then
        echo "    $FAIL $name: possible secrets in tracked files:"
        echo "$secret_hits" | sed 's/^/            /'
        errors=$((errors + 1))
      fi
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 8. go.mod must not contain local replace directives (leaks local paths)
  if [ -f "$dir/.gitmodules" ]; then
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$dir/$subpath"
      name=$(basename "$subpath")

      replace_hits=$(git -C "$subdir" grep -n 'replace.*=>.*/' \
        HEAD -- 'go.mod' '**/go.mod' 2>/dev/null \
        | grep -v '// local-dev-only' || true)
      if [ -n "$replace_hits" ]; then
        echo "    $FAIL $name: go.mod contains local replace (leaks local paths):"
        echo "$replace_hits" | sed 's/^/            /'
        errors=$((errors + 1))
      fi
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 9. .gitmodules must use HTTPS URLs (not SSH)
  #    (was check 8 before go.mod replace check was added)
  if [ -f "$dir/.gitmodules" ]; then
    if grep -q 'git@github.com' "$dir/.gitmodules" 2>/dev/null; then
      echo "    $FAIL .gitmodules: SSH URLs found (must use https://github.com/)"
      grep 'git@' "$dir/.gitmodules" | sed 's/^/        /'
      errors=$((errors + 1))
    fi
  fi

  # 10. Vendored Homebrew tap-generation assets match canonical
  #     (.github/templates). Only the tap-generation files are checked; the
  #     signing scripts (codesign/notarize) intentionally diverge in some GUI
  #     repos, so they are not sync-checked here.
  if [ -f "$dir/.gitmodules" ] && [ -d "$DEST/.github/templates" ]; then
    tpl="$DEST/.github/templates"
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$dir/$subpath"
      name=$(basename "$subpath")
      # Archived repos are read-only and can never take a template update.
      if is_archived "$name" "$dir"; then
        continue
      fi
      for f in gen-brew.sh formula.rb.tmpl cask.rb.tmpl release-brew.mk notarize-darwin-app.sh notarize-darwin.sh; do
        vend="$subdir/scripts/$f"
        [ -f "$vend" ] || continue
        if ! cmp -s "$vend" "$tpl/$f"; then
          echo "    $FAIL $name: vendored scripts/$f drifted from .github/templates/$f"
          errors=$((errors + 1))
        fi
      done
      # slack-router keeps its release tooling in build-tools/ (its scripts/
      # directory is part of the shipped bundle); check the notarize
      # canonicals there too so that layout is not a silent drift gap.
      for f in notarize-darwin.sh notarize-darwin-app.sh; do
        vend="$subdir/build-tools/$f"
        [ -f "$vend" ] || continue
        if ! cmp -s "$vend" "$tpl/$f"; then
          echo "    $FAIL $name: vendored build-tools/$f drifted from .github/templates/$f"
          errors=$((errors + 1))
        fi
      done
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 10b. Vendored skill validator matches canonical (.github/templates).
  #      Skill repos copy-maintain tests/validate-skill.sh (ADR-006) so a
  #      standalone clone stays self-contained; this check is what makes the
  #      copies safe — drift fails the org check instead of rotting silently.
  #      Repo-specific tests hang off the Makefile check target and are not
  #      sync-checked.
  if [ -f "$dir/.gitmodules" ] && [ -f "$DEST/.github/templates/validate-skill.sh" ]; then
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$dir/$subpath"
      name=$(basename "$subpath")
      vend="$subdir/tests/validate-skill.sh"
      [ -f "$vend" ] || continue
      if ! cmp -s "$vend" "$DEST/.github/templates/validate-skill.sh"; then
        echo "    $FAIL $name: tests/validate-skill.sh drifted from .github/templates/validate-skill.sh (ADR-006)"
        errors=$((errors + 1))
      fi
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 11. Tracked files must not carry this machine's home directory
  #     accounts is built with a read loop, not mapfile: macOS ships bash 3.2
  #     and mapfile is a bash 4 builtin.
  accounts=()
  while IFS= read -r acct; do
    [ -n "$acct" ] && accounts+=("$acct")
  done < <(local_accounts)

  if [ -f "$dir/.gitmodules" ] && [ "${#accounts[@]}" -gt 0 ]; then
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$dir/$subpath"
      name=$(basename "$subpath")

      # -I skips binaries.
      home_hits=$(git -C "$subdir" grep -nI -E '/(Users|home)/' HEAD 2>/dev/null \
        | home_path_leaks "${accounts[@]}" | head -20 || true)
      if [ -n "$home_hits" ]; then
        echo "    $FAIL $name: tracked files contain this machine's home directory:"
        echo "$home_hits" | sed 's/^/            /'
        errors=$((errors + 1))
      fi
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 12. A shipped tool's README must not say it has not shipped.
  #     Nothing in the release procedure reads README prose, so a status
  #     written at scaffold time survives every release that disproves it.
  if [ -f "$dir/.gitmodules" ]; then
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$dir/$subpath"
      name=$(basename "$subpath")

      has_release "$name" || continue
      for readme in README.md README.ja.md; do
        [ -f "$subdir/$readme" ] || continue
        claim=$(unreleased_claims < "$subdir/$readme" | head -3)
        if [ -n "$claim" ]; then
          echo "    $FAIL $name: $readme calls a released tool unreleased:"
          echo "$claim" | sed 's/^/            /'
          errors=$((errors + 1))
        fi
      done
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 12b. A Swift app's cask states the macOS floor its package declares.
  #      Silent when the tap is not cloned beside the series: the casks live
  #      there, and this script is otherwise usable without it.
  if [ -f "$dir/.gitmodules" ] && [ -d "$DEST/homebrew-tap/Casks" ]; then
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$dir/$subpath"
      name=$(basename "$subpath")
      [ -f "$subdir/Package.swift" ] || continue
      cask="$DEST/homebrew-tap/Casks/$name.rb"
      [ -f "$cask" ] || continue

      major=$(package_macos_major "$subdir/Package.swift")
      [ -n "$major" ] || continue
      want=$(macos_symbol_for "$major")
      got=$(cask_macos_floor "$cask")
      if [ -z "$want" ]; then
        echo "    $FAIL $name: Package.swift targets macOS $major, which check-org.sh has no Homebrew symbol for"
        echo "         add it to macos_symbol_for (brew ruby -e 'puts MacOSVersion::SYMBOLS')"
        errors=$((errors + 1))
      elif [ "$got" != "$want" ]; then
        echo "    $FAIL $name: cask says 'depends_on macos: ${got:-<nothing>}', Package.swift says macOS $major ($want)"
        echo "         set BREW_MACOS_FLOOR := $want in its Makefile; the template default is :big_sur"
        errors=$((errors + 1))
      fi
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 13. Language mirrors (CONVENTIONS.md §Documentation structure)
  echo "    language mirrors:"
  while IFS= read -r subpath; do
    subpath="${subpath#        }"
    name=$(basename "$subpath")
    problems=$(mirror_problems "$dir/$subpath")
    if [ -z "$problems" ]; then
      continue
    fi
    missing=$(printf '%s\n' "$problems" | grep -v '^WARN ' || true)
    layout=$(printf '%s\n' "$problems" | grep '^WARN ' | sed 's/^WARN //' || true)
    if [ -n "$missing" ]; then
      echo "        $FAIL $name:"
      printf '%s\n' "$missing" | sed 's/^/            /'
      errors=$((errors + 1))
    fi
    if [ -n "$layout" ]; then
      echo "        $WARN $name: $(printf '%s\n' "$layout" | wc -l | tr -d ' ') document(s) outside docs/en and docs/ja"
      printf '%s\n' "$layout" | sed 's/^/            /'
      skipped=$((skipped + 1))
    fi
  done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')

  # 16. A GUI that bundles a CLI ships the CLI's current release.
  if command -v gh >/dev/null 2>&1; then
    echo "    bundled CLI:"
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      name=$(basename "$subpath")
      ref=$(bundled_cli_pin "$dir/$subpath/Makefile")
      [ -n "$ref" ] || continue
      bcli="${ref%% *}"; bpin="${ref#* }"
      if [ "$bpin" = "-" ]; then
        echo "        $FAIL $name: bundles $bcli but does not pin it (set CLI_VERSION; see image-forge-gui)"
        errors=$((errors + 1))
        continue
      fi
      brel=$(gh release view --repo "nlink-jp/$bcli" --json tagName --jq .tagName 2>/dev/null || true)
      [ -n "$brel" ] || continue
      if [ "$bpin" != "$brel" ]; then
        echo "        $FAIL $name: bundles $bcli $bpin, but $bcli $brel is released"
        echo "             bump CLI_VERSION, rebuild with the release CLI and release $name —"
        echo "             its users cannot get the CLI fix any other way"
        errors=$((errors + 1))
      fi
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 15. The release gate fails closed (see open_release_gate above).
  echo "    release gate:"
  while IFS= read -r subpath; do
    subpath="${subpath#        }"
    name=$(basename "$subpath")
    why=$(open_release_gate "$dir/$subpath/Makefile")
    if [ -n "$why" ]; then
      echo "        $FAIL $name: $why"
      echo "             run .github/scripts/close-verify-release-gate.py --apply on its Makefile,"
      echo "             then .github/scripts/exercise-release-gate.sh to prove it"
      errors=$((errors + 1))
    fi
  done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')

  # 14. Document references resolve (CONVENTIONS.md §Documentation structure)
  echo "    document references:"
  while IFS= read -r subpath; do
    subpath="${subpath#        }"
    name=$(basename "$subpath")
    problems=$(broken_links "$dir/$subpath")
    [ -n "$problems" ] || continue
    count=$(printf '%s\n' "$problems" | wc -l | tr -d ' ')
    echo "        $FAIL $name: $count link(s) point at a path that does not exist"
    printf '%s\n' "$problems" | head -8 | sed 's/^/            /'
    [ "$count" -le 8 ] && : || echo "            … and $((count - 8)) more"
    errors=$((errors + 1))
  done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')

  # 14. Submodule pointers vs origin/main
  #     (was check 11 before the home-path and release-status checks)
  if [ ! -f "$dir/.gitmodules" ]; then
    return
  fi

  echo "    submodules:"
  while IFS= read -r subpath; do
    subpath="${subpath#        }" # strip indent from submodule foreach
    subdir="$dir/$subpath"

    # Commit recorded in parent repo
    recorded=$(git -C "$dir" ls-tree HEAD "$subpath" 2>/dev/null | awk '{print $3}')
    # Fetch and get latest commit on origin/main of submodule
    git -C "$subdir" fetch --quiet origin 2>/dev/null
    latest=$(git -C "$subdir" rev-parse origin/main 2>/dev/null || echo "unknown")

    if [ "$recorded" = "$latest" ]; then
      name=$(basename "$subpath")
      echo "        $PASS $name: up to date ($recorded)"
    elif [ "$latest" = "unknown" ]; then
      name=$(basename "$subpath")
      echo "        $WARN $name: could not fetch origin/main"
    else
      name=$(basename "$subpath")
      echo "        $FAIL $name: out of sync with origin/main"
      echo "                recorded: $recorded"
      echo "                latest:   $latest"
      errors=$((errors + 1))
    fi
  done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
}

# tests/check-org.test.sh sources this script to exercise the helpers above
# without running the org-wide checks.
if [ "${CHECK_ORG_LIB_ONLY:-}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi

echo "Destination: $DEST"
echo ""

for series in "${SERIES[@]}"; do
  target="$DEST/$series"
  if [ ! -d "$target/.git" ]; then
    echo "==> $series"
    echo "    $WARN not found locally (run clone-all.sh first) — NOT checked"
    echo ""
    skipped=$((skipped + 1))
    continue
  fi
  check_series "$series" "$target"
  echo ""
done

# Standalone knowledge repository (ADR-015). Not part of any series umbrella,
# so the series loop never sees it. What can rot silently: the en/ja document
# sets drifting apart, and a document existing without a catalog row (or vice
# versa). Both are cheap to verify offline.
echo "==> knowledge (standalone)"
kdir="$DEST/knowledge"
if [ ! -d "$kdir/.git" ]; then
  echo "    $WARN not found locally (git clone https://github.com/nlink-jp/knowledge) — NOT checked"
  skipped=$((skipped + 1))
else
  kerr=0
  for f in README.md README.ja.md LICENSE; do
    if [ ! -f "$kdir/$f" ]; then
      echo "    $FAIL knowledge: missing $f"
      kerr=1
    fi
  done
  # en/ja mirror: identical basename sets in docs/en and docs/ja.
  mirror_diff=$(diff <(ls "$kdir/docs/en" 2>/dev/null) <(ls "$kdir/docs/ja" 2>/dev/null) || true)
  if [ -n "$mirror_diff" ]; then
    echo "    $FAIL knowledge: docs/en and docs/ja file sets differ:"
    printf '%s\n' "$mirror_diff" | sed 's/^/      /'
    kerr=1
  fi
  # Every document has a catalog row in the matching README, and no row is stale.
  for doc in "$kdir"/docs/en/*.md; do
    base=$(basename "$doc")
    grep -q "docs/en/$base" "$kdir/README.md" 2>/dev/null || {
      echo "    $FAIL knowledge: docs/en/$base has no catalog row in README.md"; kerr=1; }
    grep -q "docs/ja/$base" "$kdir/README.ja.md" 2>/dev/null || {
      echo "    $FAIL knowledge: docs/ja/$base has no catalog row in README.ja.md"; kerr=1; }
  done
  if [ "$kerr" -eq 0 ]; then
    echo "    $PASS knowledge: en/ja mirror and catalog consistent"
  else
    errors=$((errors + 1))
  fi
fi
echo ""

# Tap currency: the formula/cask a user installs from must point at the current
# release (see brew_version above).
echo "==> homebrew-tap (standalone)"
tdir="$DEST/homebrew-tap"
if [ ! -d "$tdir/.git" ]; then
  echo "    $WARN not found locally (git clone https://github.com/nlink-jp/homebrew-tap) — NOT checked"
  skipped=$((skipped + 1))
elif ! command -v gh >/dev/null 2>&1; then
  echo "    $WARN gh not available — cannot read latest releases, NOT checked"
  skipped=$((skipped + 1))
else
  terr=0 tcount=0
  for f in "$tdir"/Formula/*.rb "$tdir"/Casks/*.rb; do
    [ -f "$f" ] || continue
    tname=$(basename "$f" .rb)
    tcount=$((tcount + 1))
    tver=$(brew_version "$f")
    if [ -z "$tver" ]; then
      echo "    $FAIL homebrew-tap: cannot read the version out of $(basename "$(dirname "$f")")/$tname.rb"
      terr=1
      continue
    fi
    rver=$(gh release view --repo "nlink-jp/$tname" --json tagName --jq .tagName 2>/dev/null || true)
    if [ -z "$rver" ]; then
      # No release visible: a renamed, private or unreleased repo. Not drift.
      continue
    fi
    if [ "$tver" != "${rver#v}" ]; then
      echo "    $FAIL homebrew-tap: $tname points at $tver, latest release is $rver"
      echo "         run 'make brew' in that repo (CONVENTIONS.md §Release Checklist step 7)"
      terr=1
    fi
  done
  if [ "$terr" -eq 0 ]; then
    echo "    $PASS homebrew-tap: $tcount entr(ies) point at their latest release"
  else
    errors=$((errors + 1))
  fi
fi
echo ""

# Path judgement (organization ADR-022): nlink-jp/pathguard is the one place
# it lives. What can rot silently: a consumer left on an old pathguard, a
# consumer growing a copy of the credential list again, and the runtimes'
# list (gem-agent / lagent internal/sandbox/lane.go, which do not depend on
# pathguard yet) drifting from pathguard's copy of it.
echo "==> pathguard (lib-series/pathguard and its consumers)"
pgdir="$DEST/lib-series/pathguard"
if [ ! -e "$pgdir/.git" ]; then  # a submodule's .git is a file
  echo "    $WARN lib-series/pathguard not found locally — NOT checked"
  skipped=$((skipped + 1))
else
  pgerr=0 pgcount=0
  pglatest=$(git -C "$pgdir" describe --tags --abbrev=0 2>/dev/null || true)
  for gm in "$DEST"/*/*/go.mod; do
    [ -f "$gm" ] || continue
    pgver=$(grep -o 'github.com/nlink-jp/pathguard v[0-9][0-9.]*' "$gm" | awk '{print $2}' || true)
    [ -n "$pgver" ] || continue
    pgcount=$((pgcount + 1))
    cdir=$(dirname "$gm")
    cname="${cdir#"$DEST"/}"
    # Every consumer on the latest tag: a fix to the judgement reaches a
    # server only through its dependency.
    if [ -n "$pglatest" ] && [ "$pgver" != "$pglatest" ]; then
      echo "    $FAIL $cname requires pathguard $pgver, latest is $pglatest"
      pgerr=1
    fi
    # No copy of the list: a floor entry spelled in a consumer's own code is
    # how the nine copies this module replaced began.
    copies=$(grep -rlF -e '"Library/Keychains"' -e '".config/gcloud"' -e '".gnupg"' --include='*.go' "$cdir" 2>/dev/null | grep -v '_test\.go$' | grep -v '/vendor/' || true)
    if [ -n "$copies" ]; then
      echo "    $FAIL $cname spells a credential-floor entry in its own code (pathguard holds the list):"
      printf '%s\n' "$copies" | sed "s|^$DEST/|      |"
      pgerr=1
    fi
  done
  # The runtimes' list is pathguard's list (testdata/runtime-lists.json).
  if command -v go >/dev/null 2>&1; then
    for lane in "$DEST/cli-series/gem-agent/internal/sandbox/lane.go" "$DEST/lab-series/lagent/internal/sandbox/lane.go"; do
      if [ ! -f "$lane" ]; then
        echo "    $WARN ${lane#"$DEST"/} not found — NOT compared"
        continue
      fi
      if ! out=$(go run "$SCRIPT_DIR/runtime-lists.go" -lane "$lane" -fixture "$pgdir/testdata/runtime-lists.json" 2>&1); then
        echo "    $FAIL ${lane#"$DEST"/} differs from pathguard's runtime-lists.json:"
        printf '%s\n' "$out" | sed 's/^/      /'
        pgerr=1
      fi
    done
  else
    echo "    $WARN go not available — the runtimes' lists are NOT compared"
  fi
  if [ "$pgerr" -eq 0 ]; then
    echo "    $PASS pathguard: $pgcount consumer(s) on $pglatest, no copy of the list, runtimes' lists match"
  else
    errors=$((errors + 1))
  fi
fi
echo ""

# Machine-level agent guards. Repo conventions cannot enforce these — they
# live in ~/.claude — so audit them here instead of trusting that whoever
# set the machine up remembered.
echo "==> agent guards (this machine)"
if [ -x "$SCRIPT_DIR/install-claude-guards.sh" ]; then
  if ! "$SCRIPT_DIR/install-claude-guards.sh" --check; then
    errors=$((errors + 1))
  fi
else
  echo "    $WARN install-claude-guards.sh not found or not executable"
fi
echo ""

if ! verdict "$errors" "$skipped"; then
  exit 1
fi
