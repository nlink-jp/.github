#!/usr/bin/env bash
# exercise_gate.sh REPO — drive one repo's `make verify-release` through six
# states and print one line per state.
#
# No build: the packaged binary is a stand-in shell script that prints a version
# string, which is all the gate reads. The zip name is not guessed — the gate's
# own first refusal names the file it wants, so the fixture is calibrated from
# the Makefile rather than from an assumption about VERSION.
#
# The states, and what each one is for:
#   1 no marker          the notarize step failed or never ran
#   2 correct            MUST PASS — without this row the table only shows that
#                        the gate refuses something, not that it still accepts
#                        what it should (the failure mode that made an earlier
#                        run of this exercise meaningless: every row failed at
#                        the freshness gate because the zip and its marker were
#                        created in the same second)
#   3 another tag        a zip left over from a previous release
#   4 does not unpack    a truncated or wrong-typed file
#   5 does not run       a binary that cannot execute here
#   6 stale marker       the zip was rebuilt after it was notarized
#
# mtimes are set explicitly with touch -t, never by sleeping.
set -uo pipefail

repo="${1:?usage: exercise_gate.sh REPO}"
cd "$repo" || exit 2

say() { printf '%-10s %-14s %s\n' "$1" "$2" "$3"; }

# Ask the gate what file it wants: with an empty dist/ its first refusal names
# the zip. That is also state 1.
make clean >/dev/null 2>&1
mkdir -p dist
out=$(make verify-release 2>&1); rc=$?
zipname=$(printf '%s\n' "$out" | sed -n -E 's/.*— ([^ ]+-darwin-arm64\.zip) has no notarization marker.*/\1/p' | head -1)
if [ -z "$zipname" ]; then
  say FAIL "1-no-marker" "cannot read the expected zip name from: $(printf '%s' "$out" | head -1)"
  exit 3
fi
[ "$rc" -ne 0 ] && say ok "1-no-marker" "refused (rc=$rc)" || say BAD "1-no-marker" "accepted with no marker"

# Everything below lives in dist/ under that exact name.
zip="dist/$zipname"
marker="$zip.notarized"
version=$(printf '%s' "$zipname" | sed -E 's/^.*-(v?[0-9][^-]*(-[0-9]+-g[0-9a-f]+)?(-dirty)?)-darwin-arm64\.zip$/\1/')
binary=$(printf '%s' "$zipname" | sed -E "s/-${version}-darwin-arm64\.zip$//")

# Where inside the zip the gate expects the binary. Taken from the Makefile's
# own expression rather than assumed to be the archive root: slack-router packs
# <binary>-<version>-darwin-arm64/<binary>, and an exerciser that guessed the
# root failed that repo's must-pass row while the gate was in fact correct.
# Anywhere on the line: after conversion the quoted path no longer starts the
# line (it sits inside `elif ! out=$$(...)`), and anchoring on the start read
# nothing and silently fell back to the flat layout.
inzip=$(sed -n -E 's/.*"\$\$tmp\/([^"]+)" --version.*/\1/p' Makefile | head -1)
[ -n "$inzip" ] || inzip='$(BINARY)'
mkvar=$(sed -n -E 's/^(BINARY_NAME|BINARY|BIN)[[:space:]]*[:?]?=[[:space:]]*([^ #]+).*/\2/p' Makefile | head -1)
[ -n "$mkvar" ] || mkvar="$binary"
inzip=${inzip//'$(BINARY_NAME)'/$mkvar}
inzip=${inzip//'$(BINARY)'/$mkvar}
inzip=${inzip//'$(VERSION)'/$version}

stage=$(mktemp -d)
mkstandin() { # mkstandin VERSION_STRING MODE
  mkdir -p "$stage/$(dirname "$inzip")"
  printf '#!/bin/sh\nprintf "%%s\\n" "%s %s"\n' "$binary" "$1" > "$stage/$inzip"
  chmod "$2" "$stage/$inzip"
}
mkzip() { ( cd "$stage" && zip -q -r "$OLDPWD/$zip" . ); }
fresh_marker() { # marker strictly newer than the zip
  : > "$marker"
  touch -t 202601010000 "$zip"
  touch -t 202601020000 "$marker"
}

run() { # run LABEL WANT(ok|fail)
  local label="$1" want="$2" o r
  o=$(make verify-release 2>&1); r=$?
  if [ "$want" = ok ]; then
    [ "$r" -eq 0 ] && say ok "$label" "accepted" || say BAD "$label" "refused although correct: $(printf '%s' "$o" | grep -m1 FAIL)"
  else
    [ "$r" -ne 0 ] && say ok "$label" "refused: $(printf '%s' "$o" | sed -n 's/.*FAIL — //p' | head -1)" || say BAD "$label" "ACCEPTED (rc=0)"
  fi
}

# 2. correct — the must-pass row.
rm -f "$zip" "$marker"
mkstandin "$version" 755
mkzip
fresh_marker
run "2-correct" ok

# 3. a build from another tag.
rm -f "$zip" "$marker"
mkstandin "v0.0.0-other" 755
mkzip
fresh_marker
run "3-other-tag" fail

# 4. does not unpack.
rm -f "$zip" "$marker"
: > "$zip"
fresh_marker
run "4-no-unpack" fail

# 5. does not run.
rm -f "$zip" "$marker"
mkstandin "$version" 444   # not executable
mkzip
fresh_marker
run "5-no-run" fail

# 6. marker older than the zip.
rm -f "$zip" "$marker"
mkstandin "$version" 755
mkzip
: > "$marker"
touch -t 202601010000 "$marker"
touch -t 202601020000 "$zip"
run "6-stale" fail

rm -rf "$stage"
make clean >/dev/null 2>&1
