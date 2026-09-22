#!/usr/bin/env bash
# exercise-release-gate.test.sh — tests for scripts/exercise-release-gate.sh.
# Run: bash .github/tests/exercise-release-gate.test.sh
#
# The gate under test is the CONVENTIONS.md template itself, extracted from the
# document, so the template and the exerciser cannot drift apart unnoticed.
# What must hold:
#   1. the template passes all thirteen rows, under a UTF-8 locale, with a binary
#      name that sorts before LICENSE there (it sorts after it in C);
#   2. a Linux check that lists with a plain `tar -tzf` is caught: macOS tar
#      folds ._ members out of that listing, and the AppleDouble row is BAD;
#   3. a gate with no Linux block reads n/a on the Linux rows, not failure;
#   4. a non-empty dist/ is refused and left as it was;
#   5. the xattr check reads pax headers, not file text: a stream grep refuses
#      the keyword-in-file row, a reader that sees no headers accepts the pax
#      row, and a reader that cannot run refuses instead of passing.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
EXERCISE="$HERE/../scripts/exercise-release-gate.sh"
CONVENTIONS="$HERE/../CONVENTIONS.md"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok() { printf 'ok   - %s\n' "$1"; pass=$((pass + 1)); }
no() { printf 'FAIL - %s\n' "$1"; fail=$((fail + 1)); }

# mkrepo DIR SED_EXPR — a git repo tagged v0.0.1 whose Makefile is the
# template's makefile block (the one carrying verify-release), edited by SED_EXPR.
mkrepo() {
  mkdir -p "$1"
  {
    printf 'BINARY  := abc-tool\nVERSION := $(shell git describe --tags --always --dirty 2>/dev/null)\n\n'
    awk '/^```makefile$/{buf=""; on=1; next} on && /^```$/{if (buf ~ /verify-release:/) {printf "%s", buf; exit} on=0; next} on{buf=buf $0 "\n"}' "$CONVENTIONS"
  } | sed "$2" > "$1/Makefile"
  git -C "$1" init -q
  git -C "$1" add Makefile
  git -C "$1" -c user.name=t -c user.email=t@example.invalid commit -q -m t
  git -C "$1" tag v0.0.1
}

# ---- 1. the template passes every row -------------------------------------
mkrepo "$TMP/good" 's/^//'
grep -qF "tar --options 'tar:!mac-ext' -tzf" "$TMP/good/Makefile" \
  && ok "the extracted template carries the Linux-archive check" \
  || no "the extracted template carries the Linux-archive check"
out=$(LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bash "$EXERCISE" "$TMP/good" 2>&1); rc=$?
[ "$rc" -eq 0 ] && ok "template: exit 0" || { no "template: exit 0 (got $rc)"; printf '%s\n' "$out" >&2; }
n=$(printf '%s\n' "$out" | grep -c '^ok ')
[ "$n" -eq 13 ] && ok "template: 13 rows ok under en_US.UTF-8" || no "template: 13 rows ok (got $n)"
[ ! -e "$TMP/good/dist" ] && ok "template: the dist/ it created is gone" || no "template: dist/ left behind"

# ---- 2. a plain listing cannot see ._ members -----------------------------
mkrepo "$TMP/blind" "s/tar --options 'tar:!mac-ext' -tzf/tar -tzf/"
out=$(bash "$EXERCISE" "$TMP/blind" 2>&1); rc=$?
[ "$rc" -ne 0 ] && ok "blind listing: exit non-zero" || no "blind listing: exit non-zero"
printf '%s\n' "$out" | grep -qE '^BAD +7-appledouble +ACCEPTED' \
  && ok "blind listing: the AppleDouble row is accepted, and reported BAD" \
  || { no "blind listing: the AppleDouble row is reported BAD"; printf '%s\n' "$out" >&2; }
printf '%s\n' "$out" | grep -qE '^ok +8-xattr-pax' \
  && ok "blind listing: the pax-header row still refuses" || no "blind listing: the pax-header row still refuses"

# ---- 3. no Linux block: n/a, not failure ----------------------------------
mkrepo "$TMP/nolinux" 's/linux\/amd64 linux\/arm64 //'
out=$(bash "$EXERCISE" "$TMP/nolinux" 2>&1); rc=$?
[ "$rc" -eq 0 ] && ok "darwin only: exit 0" || { no "darwin only: exit 0 (got $rc)"; printf '%s\n' "$out" >&2; }
n=$(printf '%s\n' "$out" | grep -c '^n/a ')
[ "$n" -eq 7 ] && ok "darwin only: seven Linux rows n/a" || no "darwin only: seven Linux rows n/a (got $n)"

# ---- 4. a non-empty dist/ is refused and kept ------------------------------
mkrepo "$TMP/busy" 's/^//'
mkdir "$TMP/busy/dist"
printf 'release artifact\n' > "$TMP/busy/dist/keep.zip"
bash "$EXERCISE" "$TMP/busy" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "non-empty dist/: refused (exit 2)" || no "non-empty dist/: refused (got $rc)"
[ "$(cat "$TMP/busy/dist/keep.zip" 2>/dev/null)" = "release artifact" ] && [ "$(ls -A "$TMP/busy/dist")" = keep.zip ] \
  && ok "non-empty dist/: left exactly as it was" || no "non-empty dist/: left exactly as it was"

# ---- 5. the xattr check reads headers, not text ---------------------------
# mutate DIR PYTHON_REGEX REPLACEMENT — rewrite the template's header reader in
# a committed, re-tagged repo so the exerciser sees a clean tree.
mutate() {
  python3 - "$1/Makefile" "$2" "$3" <<'EOF'
import re, sys
p, pat, rep = sys.argv[1:]
t = open(p, encoding='utf-8').read()
t2, n = re.subn(pat, lambda m: rep, t)
assert n == 1, f'{pat!r} matched {n} times'
open(p, 'w', encoding='utf-8').write(t2)
EOF
  git -C "$1" -c user.name=t -c user.email=t@example.invalid commit -q -am mutate
  git -C "$1" tag -f v0.0.1 >/dev/null
}
reader="python3 -c '[^']*' \"\\\$\\\$f\""

mkrepo "$TMP/stream" 's/^//'
mutate "$TMP/stream" "$reader" 'gzip -dc "$$f" | grep -ao -e LIBARCHIVE.xattr -e SCHILY.xattr | head -1'
out=$(bash "$EXERCISE" "$TMP/stream" 2>&1); rc=$?
[ "$rc" -ne 0 ] && ok "stream grep: exit non-zero" || no "stream grep: exit non-zero"
printf '%s\n' "$out" | grep -qE '^BAD +13-keyword-in-file +refused although correct' \
  && ok "stream grep: the keyword-in-file row is refused, and reported BAD" \
  || { no "stream grep: the keyword-in-file row is reported BAD"; printf '%s\n' "$out" >&2; }
printf '%s\n' "$out" | grep -qE '^ok +8-xattr-pax' \
  && ok "stream grep: the pax-header row still refuses" || no "stream grep: the pax-header row still refuses"

mkrepo "$TMP/noheaders" 's/^//'
mutate "$TMP/noheaders" 'for k in m\.pax_headers' 'for k in {}'
out=$(bash "$EXERCISE" "$TMP/noheaders" 2>&1)
printf '%s\n' "$out" | grep -qE '^BAD +8-xattr-pax +ACCEPTED' \
  && ok "blind header read: the pax-header row is accepted, and reported BAD" \
  || { no "blind header read: the pax-header row is reported BAD"; printf '%s\n' "$out" >&2; }

mkrepo "$TMP/noreader" 's/^//'
mutate "$TMP/noreader" 'python3 -c' 'python3-absent -c'
out=$(bash "$EXERCISE" "$TMP/noreader" 2>&1)
printf '%s\n' "$out" | grep -qE '^BAD +2-correct +refused although correct:.*cannot be read for its pax headers' \
  && ok "reader cannot run: the correct row is refused (fails closed)" \
  || { no "reader cannot run: the correct row is refused (fails closed)"; printf '%s\n' "$out" >&2; }
printf '%s\n' "$out" | grep -qE ' ACCEPTED' \
  && no "reader cannot run: no row is accepted" || ok "reader cannot run: no row is accepted"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
