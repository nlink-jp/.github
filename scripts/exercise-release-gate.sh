#!/usr/bin/env bash
# exercise-release-gate.sh REPO — drive one repo's `make verify-release`
# through twelve states and print one line per state. Exits 1 if any line is BAD.
#
# No build: the packaged binary is a stand-in shell script that prints a version
# string, which is all the gate reads. Nothing is guessed: the gate's own first
# refusal names the zip it wants, and the refusals after it name each Linux
# archive and state its contents, so the fixtures are calibrated from the
# Makefile rather than from an assumption about VERSION or the archive list.
#
# darwin zip:
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
# Linux archives (the last one in the gate's order is the one broken, so a gate
# that stops looking after the first archive fails these rows):
#   7 AppleDouble        ._ members: tar without COPYFILE_DISABLE=1. macOS tar's
#                        own listing folds them away, so a gate that lists
#                        without --options 'tar:!mac-ext' accepts this row
#   8 xattr pax headers  tar without --no-xattrs (COPYFILE_DISABLE=1 alone)
#   9 neither flag       the form every Makefile had before 2026-09-23
#  10 extra entry        a file beyond the canonical contents
#  11 missing entry      LICENSE left out
#  12 no archive         the archive was never built
# A gate with no Linux block reports rows 7-12 as n/a.
#
# Each Linux fixture is read back with Python's tarfile, which does not fold
# AppleDouble members, before the gate sees it: a row cannot pass on a fixture
# that lacks the defect it names. A refusal counts only when it names the broken
# archive and the reason the row is for — a refusal for any other reason is BAD.
#
# It refuses to run over a non-empty dist/ (that may be someone's release) and
# removes only the files it created, one full path at a time.
#
# mtimes are set explicitly with touch -t, never by sleeping.
set -uo pipefail

repo="${1:?usage: exercise-release-gate.sh REPO}"
cd "$repo" || exit 2
top=$(pwd -P)

bad=0
say() { printf '%-10s %-18s %s\n' "$1" "$2" "$3"; [ "$1" = BAD ] && bad=1; return 0; }

if [ -d dist ] && [ -n "$(ls -A dist)" ]; then
  echo "exercise-release-gate: $top/dist is not empty — move or clean it first (it may hold a release)." >&2
  exit 2
fi
made_dist=
[ -d dist ] || { mkdir dist; made_dist=1; }
created=()
stage=$(mktemp -d)
track() { local f; for f; do case " ${created[*]-} " in *" $f "*) ;; *) created+=("$f") ;; esac; done; }
cleanup() {
  local f
  for f in ${created[@]+"${created[@]}"}; do rm -f "$top/$f"; done
  [ -n "$made_dist" ] && rmdir "$top/dist" 2>/dev/null
  rm -rf "$stage"
}
trap cleanup EXIT

# Ask the gate what file it wants: with an empty dist/ its first refusal names
# the zip. That is also state 1.
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
track "$zip" "$marker"
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

mkstandin() { # mkstandin VERSION_STRING MODE
  mkdir -p "$stage/$(dirname "$inzip")"
  rm -f "$stage/$inzip"   # row 5 leaves it read-only; rewriting it in place would fail
  printf '#!/bin/sh\nprintf "%%s\\n" "%s %s"\n' "$binary" "$1" > "$stage/$inzip"
  chmod "$2" "$stage/$inzip"
}
mkzip() { ( cd "$stage" && zip -q -r "$top/$zip" . ); }
fresh_marker() { # marker strictly newer than the zip
  : > "$top/$marker"
  touch -t 202601010000 "$top/$zip"
  touch -t 202601020000 "$top/$marker"
}
correct_zip() { rm -f "$top/$zip" "$top/$marker"; mkstandin "$version" 755; mkzip; fresh_marker; }

run() { # run LABEL WANT(ok|fail)
  local label="$1" want="$2" o r
  o=$(make verify-release 2>&1); r=$?
  if [ "$want" = ok ]; then
    [ "$r" -eq 0 ] && say ok "$label" "accepted" || say BAD "$label" "refused although correct: $(printf '%s' "$o" | grep -m1 FAIL)"
  else
    [ "$r" -ne 0 ] && say ok "$label" "refused: $(printf '%s' "$o" | sed -n 's/.*FAIL — //p' | head -1)" || say BAD "$label" "ACCEPTED (rc=0)"
  fi
}

# --- Linux archive fixtures ----------------------------------------------------
linux=(); want=(); under=; drop=

# fixture_shape ARCHIVE — "ad=N pax=N", read without folding AppleDouble.
fixture_shape() {
  python3 - "$1" <<'PY'
import sys, tarfile
ad = pax = False
with tarfile.open(sys.argv[1]) as t:
    for m in t.getmembers():
        ad |= m.name.rstrip('/').split('/')[-1].startswith('._')
        pax |= any('xattr' in k for k in m.pax_headers)
print(f"ad={int(ad)} pax={int(pax)}")
PY
}

# mklinux ARCHIVE MODE — clean | appledouble | pax | neither | extra | missing | absent
mklinux() {
  local path="$1" mode="$2" s name root e shape expect members=()
  track "$path"
  rm -f "$top/$path"
  [ "$mode" = absent ] && return 0
  s=$(mktemp -d)
  name=$(basename "$path" .tar.gz)
  root="$s"; [ -n "$under" ] && root="$s/$name"
  mkdir -p "$root"
  for e in "${want[@]}" EXTRA; do
    [ "$e" = EXTRA ] && [ "$mode" != extra ] && continue
    [ "$mode" = missing ] && [ "$e" = "$drop" ] && continue
    printf 'exercise fixture\n' > "$root/$e"
    xattr -w org.nlink-jp.exercise 1 "$root/$e"
    members+=("$e")
  done
  [ -n "$under" ] && members=("$name")
  case "$mode" in
    appledouble) ( cd "$s" && env -u COPYFILE_DISABLE tar --no-xattrs -czf "$top/$path" "${members[@]}" ) ;;
    pax)         ( cd "$s" && COPYFILE_DISABLE=1 tar -czf "$top/$path" "${members[@]}" ) ;;
    neither)     ( cd "$s" && env -u COPYFILE_DISABLE tar -czf "$top/$path" "${members[@]}" ) ;;
    *)           ( cd "$s" && COPYFILE_DISABLE=1 tar --no-xattrs -czf "$top/$path" "${members[@]}" ) ;;
  esac
  rm -rf "$s"
  case "$mode" in
    appledouble) expect="ad=1 pax=0" ;;
    pax)         expect="ad=0 pax=1" ;;
    neither)     expect="ad=1 pax=1" ;;
    *)           expect="ad=0 pax=0" ;;
  esac
  shape=$(fixture_shape "$top/$path")
  [ "$shape" = "$expect" ] || { say BAD "fixture" "the $mode fixture reads $shape, not $expect — its row would prove nothing"; return 1; }
}

# Calibrate: each "does not list" refusal names the next archive. The first one
# gets a stub under <name>/ — it passes a layout check and fails the contents
# check, whose refusal states the contract — and then every archive is built
# clean, so the gate moves on to the next.
calibrated=ok
correct_zip
for _ in 1 2 3 4 5 6 7 8 9 10; do
  o=$(make verify-release 2>&1) && break
  f=$(printf '%s\n' "$o" | sed -n -E 's/^verify-release: FAIL — (.+\.tar\.gz) does not list\.$/\1/p' | head -1)
  if [ -z "$f" ]; then calibrated="refused before any Linux archive: $(printf '%s\n' "$o" | grep -m1 FAIL)"; break; fi
  linux+=("$f")
  if [ ${#want[@]} -eq 0 ]; then
    s=$(mktemp -d); name=$(basename "$f" .tar.gz); mkdir -p "$s/$name"; : > "$s/$name/stub"
    track "$f"
    ( cd "$s" && COPYFILE_DISABLE=1 tar --no-xattrs -czf "$top/$f" "$name" ); rm -rf "$s"
    o=$(make verify-release 2>&1)
    line=$(printf '%s\n' "$o" | grep -m1 -F "FAIL — $f holds")
    w=${line##*; expected }
    if [ -z "$line" ] || [ "$w" = "$line" ]; then
      calibrated="cannot read the contents from: $(printf '%s\n' "$o" | grep -m1 FAIL)"; break
    fi
    case "$line" in *" under "*) under=1 ;; esac
    read -r -a want <<< "$w"
    drop=LICENSE
    case " ${want[*]} " in *" LICENSE "*) ;; *) drop=${want[${#want[@]}-1]} ;; esac
  fi
  mklinux "$f" clean || { calibrated="the clean fixture failed its own check"; break; }
done
[ "$calibrated" = ok ] || say BAD "linux-calibrate" "$calibrated"

# 2. correct — the must-pass row (with every Linux archive clean).
run "2-correct" ok

# 3. a build from another tag.
rm -f "$top/$zip" "$top/$marker"
mkstandin "v0.0.0-other" 755
mkzip
fresh_marker
run "3-other-tag" fail

# 4. does not unpack.
rm -f "$top/$zip" "$top/$marker"
: > "$top/$zip"
fresh_marker
run "4-no-unpack" fail

# 5. does not run.
rm -f "$top/$zip" "$top/$marker"
mkstandin "$version" 444   # not executable
mkzip
fresh_marker
run "5-no-run" fail

# 6. marker older than the zip.
rm -f "$top/$zip" "$top/$marker"
mkstandin "$version" 755
mkzip
: > "$top/$marker"
touch -t 202601010000 "$top/$marker"
touch -t 202601020000 "$top/$zip"
run "6-stale" fail

# 7-12. Linux archives, against a correct zip.
lrow() { # lrow LABEL MODE REASON
  local label="$1" mode="$2" reason="$3" o r line
  if [ ${#linux[@]} -eq 0 ] || [ "$calibrated" != ok ]; then
    [ ${#linux[@]} -eq 0 ] && [ "$calibrated" = ok ] && say n/a "$label" "the gate checks no Linux archive" || say BAD "$label" "not run: calibration failed"
    return
  fi
  last=${linux[${#linux[@]}-1]}
  mklinux "$last" "$mode" || return
  o=$(make verify-release 2>&1); r=$?
  line=$(printf '%s\n' "$o" | grep -m1 'FAIL — ')
  if [ "$r" -eq 0 ]; then
    say BAD "$label" "ACCEPTED (rc=0)"
  elif printf '%s' "$line" | grep -qF -- "$last" && printf '%s' "$line" | grep -qF -- "$reason"; then
    say ok "$label" "refused: ${line#*FAIL — }"
  else
    say BAD "$label" "refused for another reason: ${line#*FAIL — }"
  fi
  mklinux "$last" clean
}
correct_zip
lrow "7-appledouble"   appledouble "carries macOS metadata entries"
lrow "8-xattr-pax"     pax         "carries extended attributes as pax headers"
lrow "9-neither-flag"  neither     "carries macOS metadata entries"
lrow "10-extra-entry"  extra       "holds"
lrow "11-missing-entry" missing    "holds"
lrow "12-no-archive"   absent      "does not list"

exit "$bad"
