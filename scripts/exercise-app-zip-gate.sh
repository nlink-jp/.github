#!/usr/bin/env bash
# exercise-app-zip-gate.sh [ZIP...] — drive templates/verify-app-zip.sh through
# twelve built states, then over any real release zips given as arguments, and
# print one line per case. Exits 1 if any line is BAD.
#
# Built states (a stand-in .app zipped with /usr/bin/zip; the icon is only the
# four-byte magic the gate reads):
#   1 AppIcon            MUST PASS — without the passing rows the table only
#                        shows that the gate refuses, not that it still accepts
#   2 icon (no ext)      MUST PASS — CFBundleIconFile "icon", file icon.icns (nvme-lens)
#   3 AppIcon.icns key   MUST PASS — the key already carries the extension
#   4 space in name      MUST PASS — "Spice Client.app"
#   5 no key             Info.plist names no CFBundleIconFile
#   6 no file            the key is there, the file is not
#   7 AppleDouble only   only "._AppIcon.icns" — a substring match accepts this
#   8 not icns           the file exists but is not an icns (empty/other format)
#   9 two apps           two top-level .app bundles
#  10 no zip             the zip does not exist
#  11 AppleDouble        a "._Info.plist" entry beside a correct icon (ditto
#                        without --norsrc --noextattr)
#  12 __MACOSX           a __MACOSX/ tree (ditto --sequesterRsrc)
#
# Real zips: each is expected to pass unless its name is prefixed with "fail:"
# (e.g. fail:/path/old-release.zip), which expects a refusal.
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
gate="$here/../templates/verify-app-zip.sh"
[ -x "$gate" ] || { echo "not executable: $gate" >&2; exit 2; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
bad=0

# make_app DIR APPNAME KEY(or "") ICONFILE(or "") CONTENT
make_app() {
  local dir="$1" app="$2" key="$3" file="$4" content="$5"
  mkdir -p "$dir/$app/Contents/Resources" "$dir/$app/Contents/MacOS"
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    echo '<plist version="1.0"><dict>'
    echo '<key>CFBundleExecutable</key><string>Stand</string>'
    [ -n "$key" ] && echo "<key>CFBundleIconFile</key><string>$key</string>"
    echo '</dict></plist>'
  } > "$dir/$app/Contents/Info.plist"
  printf '#!/bin/sh\n' > "$dir/$app/Contents/MacOS/Stand"
  [ -n "$file" ] && printf '%s' "$content" > "$dir/$app/Contents/Resources/$file"
  return 0
}

ICNS=$'icns\x00\x00\x00\x08'

# row N LABEL EXPECT(pass|fail) — the fixture directory is $work/N; zips every
# top-level entry in it, unless the row made no zip at all.
row() {
  local n="$1" label="$2" expect="$3" dir="$work/$1" zip="$work/$1.zip" out got
  if [ -d "$dir" ]; then (cd "$dir" && /usr/bin/zip -qr "$zip" .) || { echo "BAD  $n $label: fixture zip failed"; bad=1; return; }; fi
  if out=$("$gate" "$zip" 2>&1); then got=pass; else got=fail; fi
  if [ "$got" = "$expect" ]; then
    printf 'ok   %-2s %-18s %-4s  %s\n' "$n" "$label" "$got" "$out"
  else
    printf 'BAD  %-2s %-18s %-4s (expected %s)  %s\n' "$n" "$label" "$got" "$expect" "$out"
    bad=1
  fi
}

make_app "$work/1" "Stand.app" "AppIcon" "AppIcon.icns" "$ICNS";           row 1 "AppIcon" pass
make_app "$work/2" "Stand.app" "icon" "icon.icns" "$ICNS";                  row 2 "icon (no ext)" pass
make_app "$work/3" "Stand.app" "AppIcon.icns" "AppIcon.icns" "$ICNS";       row 3 "AppIcon.icns key" pass
make_app "$work/4" "Spice Client.app" "AppIcon" "AppIcon.icns" "$ICNS";     row 4 "space in name" pass
make_app "$work/5" "Stand.app" "" "AppIcon.icns" "$ICNS";                   row 5 "no key" fail
make_app "$work/6" "Stand.app" "AppIcon" "" "";                             row 6 "no file" fail
make_app "$work/7" "Stand.app" "AppIcon" "._AppIcon.icns" "$ICNS";          row 7 "AppleDouble only" fail
make_app "$work/8" "Stand.app" "AppIcon" "AppIcon.icns" "PNG";              row 8 "not icns" fail
make_app "$work/9" "Stand.app" "AppIcon" "AppIcon.icns" "$ICNS"
make_app "$work/9" "Other.app" "AppIcon" "AppIcon.icns" "$ICNS";            row 9 "two apps" fail
row 10 "no zip" fail
make_app "$work/11" "Stand.app" "AppIcon" "AppIcon.icns" "$ICNS"
printf 'x' > "$work/11/Stand.app/Contents/._Info.plist";                    row 11 "AppleDouble" fail
make_app "$work/12" "Stand.app" "AppIcon" "AppIcon.icns" "$ICNS"
mkdir -p "$work/12/__MACOSX/Stand.app" && printf 'x' > "$work/12/__MACOSX/Stand.app/._Info.plist"; row 12 "__MACOSX" fail

for arg in "$@"; do
  expect=pass real="$arg"
  case "$arg" in fail:*) expect=fail real="${arg#fail:}" ;; esac
  if out=$("$gate" "$real" 2>&1); then got=pass; else got=fail; fi
  if [ "$got" = "$expect" ]; then
    printf 'ok   real %-4s %s  %s\n' "$got" "$(basename "$real")" "$out"
  else
    printf 'BAD  real %-4s (expected %s) %s  %s\n' "$got" "$expect" "$(basename "$real")" "$out"
    bad=1
  fi
done

exit "$bad"
