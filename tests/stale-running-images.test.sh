#!/usr/bin/env bash
# stale-running-images.test.sh — tests for the path reading behind the
# stale-image report. Run: bash .github/tests/stale-running-images.test.sh
#
# The lsof pass itself is not testable here (it reads this machine's processes),
# so the parsing is factored out and tested: a Cellar path yields a tool and a
# version, anything else yields nothing, and a tool that is not ours or not
# installed through the Cellar is left alone. Getting either of those wrong
# turns the report into noise, and a noisy report is one nobody reads.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
STALE_LIB_ONLY=1 . "$HERE/../scripts/stale-running-images.sh" >/dev/null
set +e +u +o pipefail

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok() { printf 'ok   - %s\n' "$1"; pass=$((pass + 1)); }
no() { printf 'FAIL - %s\n' "$1"; fail=$((fail + 1)); }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; printf '        want: [%s]\n        got:  [%s]\n' "$3" "$2" >&2; fi; }

# ---- cellar_ref: a held executable path -> tool and version ----------------
is 'a Cellar executable yields tool and version' \
   "$(cellar_ref /opt/homebrew/Cellar/urlscan-lookup/0.2.0/bin/urlscan-lookup)" \
   'urlscan-lookup 0.2.0'
is 'a version with a suffix is kept whole' \
   "$(cellar_ref /opt/homebrew/Cellar/tool/1.2.3_1/bin/tool)" \
   'tool 1.2.3_1'
is 'a libexec path still yields the tool' \
   "$(cellar_ref /opt/homebrew/Cellar/tool/0.1.0/libexec/helper)" \
   'tool 0.1.0'

# Everything that is not a Cellar executable must yield nothing: the report is
# about our tools, and a system binary or a build tree is not one.
is 'a system binary yields nothing'  "$(cellar_ref /usr/bin/ssh)" ''
is 'dyld yields nothing'             "$(cellar_ref /usr/lib/dyld)" ''
is 'a dev build yields nothing'      "$(cellar_ref /Users/x/works/tool/dist/tool)" ''
is 'the bin symlink yields nothing'  "$(cellar_ref /opt/homebrew/bin/tool)" ''
is 'an empty path yields nothing'    "$(cellar_ref '')" ''
# A Cellar directory whose name is not a version must not be read as one.
is 'a non-version directory yields nothing' \
   "$(cellar_ref /opt/homebrew/Cellar/tool/HEAD/bin/tool)" ''

# ---- installed_cellar_version: what an install would give you now ----------
mkdir -p "$TMP/prefix/bin" "$TMP/prefix/Cellar/tool/9.9.9/bin"
: > "$TMP/prefix/Cellar/tool/9.9.9/bin/tool"
ln -s ../Cellar/tool/9.9.9/bin/tool "$TMP/prefix/bin/tool"
CELLAR_PREFIX="$TMP/prefix"
is 'the bin symlink resolves to the installed version' "$(installed_cellar_version tool)" '9.9.9'
is 'a tool that is not installed has no version'       "$(installed_cellar_version absent)" ''
# A real file rather than a symlink (a hand-installed binary) is not a Cellar
# install, and claiming a version for it would invent drift.
: > "$TMP/prefix/bin/handmade"
is 'a non-symlink is not a Cellar install' "$(installed_cellar_version handmade)" ''

# ---- ours: only tools in the tap are reported ------------------------------
mkdir -p "$TMP/tap/Formula" "$TMP/tap/Casks"
: > "$TMP/tap/Formula/mine.rb"
: > "$TMP/tap/Casks/mine-gui.rb"
TAP_DIR="$TMP/tap"
if ours mine; then ok 'a formula in the tap is ours'; else no 'a formula in the tap is ours'; fi
if ours mine-gui; then ok 'a cask in the tap is ours'; else no 'a cask in the tap is ours'; fi
if ours node; then no 'a tool outside the tap is not ours'; else ok 'a tool outside the tap is not ours'; fi

echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
