#!/usr/bin/env bash
# close-verify-release-gate.test.sh — tests for close-verify-release-gate.py.
# Run: bash .github/tests/close-verify-release-gate.test.sh
#
# The rule under test: whether a gate is already closed is read from the
# verify-release recipe alone. web-fetch's e2e target ends in `exit $$rc`, and
# a whole-file test reported its open gate as closed and left it untouched.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONVERT="$HERE/../scripts/close-verify-release-gate.py"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok() { printf 'ok   - %s\n' "$1"; pass=$((pass + 1)); }
no() { printf 'FAIL - %s\n' "$1"; fail=$((fail + 1)); }

# says LABEL WANT-SUBSTRING MAKEFILE — the --check note for MAKEFILE contains WANT.
says() {
  _got=$(python3 "$CONVERT" --check "$3" | head -1)
  case "$_got" in *"$2"*) ok "$1" ;; *) no "$1"; printf '        want: *%s*\n        got:  %s\n' "$2" "$_got" >&2 ;; esac
}

# ---- 1. an exit $$rc in another target does not make the gate closed -------
cat > "$TMP/open-e2e.mk" <<'EOF'
e2e: build
	@go test -tags e2e ./e2e/... > dist/e2e-go.log 2>&1; rc=$$?; \
		exit $$rc

## verify-release: refuse to release an un-notarized zip (marker gate)
verify-release:
	@test -f "dist/$(BINARY)-$(VERSION)-darwin-arm64.zip.notarized" || exit 1
	@tmp=$$(mktemp -d) && \
		unzip -oq "dist/$(BINARY)-$(VERSION)-darwin-arm64.zip" -d "$$tmp" && \
		"$$tmp/$(BINARY)" --version && \
		spctl -a -vv -t install "$$tmp/$(BINARY)" 2>&1 | head -2 || true; \
		rm -rf "$$tmp"
	@echo "verify-release: OK ($(VERSION), notarization marker present)"

## clean: Remove build artifacts
clean:
	rm -rf dist/
EOF
says 'an exit $$rc in the e2e target does not read as closed' 'converted' "$TMP/open-e2e.mk"

python3 "$CONVERT" --apply "$TMP/open-e2e.mk" >/dev/null
says 'the converted file then reads as closed' 'already closed' "$TMP/open-e2e.mk"
if grep -qF -e 'head -2 || true; \' "$TMP/open-e2e.mk" \
   && ! grep -qF -e '--version && \' "$TMP/open-e2e.mk" \
   && grep -qF -e 'reports its version)"' "$TMP/open-e2e.mk"; then
  ok 'the open chain is gone and the closed block is in its place'
else
  no 'the open chain is gone and the closed block is in its place'
fi
if grep -qF 'rc=$$?; \' "$TMP/open-e2e.mk" && grep -qF 'rm -rf dist/' "$TMP/open-e2e.mk"; then
  ok 'the other targets are left as they were'
else
  no 'the other targets are left as they were'
fi

# ---- 2. a closed gate with the Linux-archive block after it ---------------
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
	done
	@echo "verify-release: OK ($(VERSION), notarized, unpacks, runs, reports its version, clean linux archives)"
EOF
says 'a closed gate with a linux block is already closed' 'already closed' "$TMP/closed-linux.mk"

# ---- 3. nothing to convert --------------------------------------------------
printf '%s\n' 'build:' '	go build ./...' > "$TMP/none.mk"
says 'a Makefile without the target is skipped' 'no verify-release target' "$TMP/none.mk"

echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
