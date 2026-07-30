#!/usr/bin/env bash
# install-claude-guards.sh — Install the org's Claude Code agent guards.
#
# Usage:
#   ./install-claude-guards.sh [--check]
#
# These are NOT git hooks (see install-hooks.sh for those). They are Claude
# Code PreToolUse hooks: the harness runs them before a tool call and can
# refuse it. That matters because the failure they prevent — a recursive
# in-place rewrite aimed at a relative path from the wrong directory —
# happens precisely when attention lapses, so a written rule cannot prevent
# it. Twice now, `gofmt -w .` run from the workspace root has reformatted
# every Go file in every repo. The control has to sit outside the agent.
#
# What it installs:
#   ~/.claude/hooks/guard-recursive-write.py   (copy of the canonical script)
#   ~/.claude/settings.json                    (hooks.PreToolUse entry, merged)
#
# --check verifies the installation without changing anything (used by
# check-org.sh); exit 0 = installed and current, 1 = missing or stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$(cd "$SCRIPT_DIR/../claude-code" && pwd)"
GUARD_SRC="$SRC_DIR/guard-recursive-write.py"
GUARD_TEST="$SRC_DIR/guard-recursive-write-test.py"

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
GUARD_DST="$HOOKS_DIR/guard-recursive-write.py"
SETTINGS="$CLAUDE_DIR/settings.json"
HOOK_CMD="python3 $GUARD_DST"

check_only=false
[ "${1:-}" = "--check" ] && check_only=true

fail() { echo "  [NG] $1"; exit 1; }

# --- check mode -------------------------------------------------------------
if $check_only; then
  [ -f "$GUARD_DST" ] || fail "Claude guard not installed: $GUARD_DST missing (run .github/scripts/install-claude-guards.sh)"
  if ! diff -q "$GUARD_SRC" "$GUARD_DST" >/dev/null 2>&1; then
    fail "Claude guard is stale: $GUARD_DST differs from $GUARD_SRC (re-run install-claude-guards.sh)"
  fi
  [ -f "$SETTINGS" ] || fail "no $SETTINGS — the guard is installed but never runs"
  if ! jq -e --arg cmd "$HOOK_CMD" \
      '.hooks.PreToolUse[]? | select(.matcher == "Bash") | .hooks[]? | select(.command == $cmd)' \
      "$SETTINGS" >/dev/null 2>&1; then
    fail "$SETTINGS has no PreToolUse/Bash hook running the guard (re-run install-claude-guards.sh)"
  fi
  echo "  [OK] Claude agent guard installed and current"
  exit 0
fi

# --- install ---------------------------------------------------------------
command -v jq >/dev/null 2>&1 || { echo "jq is required (brew install jq)"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required"; exit 1; }

echo "Verifying the guard behaves before installing it..."
python3 "$GUARD_TEST" || { echo "guard self-test failed — refusing to install"; exit 1; }

mkdir -p "$HOOKS_DIR"
cp "$GUARD_SRC" "$GUARD_DST"
chmod +x "$GUARD_DST"
echo "  ✓ $GUARD_DST"

# Merge the hook entry into settings.json without disturbing anything else.
# An absent file starts from {}; an existing Bash matcher gains the hook only
# if it is not already there, so re-running is a no-op.
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
tmp="$(mktemp)"
jq --arg cmd "$HOOK_CMD" '
  .hooks //= {} |
  .hooks.PreToolUse //= [] |
  if any(.hooks.PreToolUse[]; .matcher == "Bash") then
    .hooks.PreToolUse |= map(
      if .matcher == "Bash" then
        .hooks //= [] |
        if any(.hooks[]; .command == $cmd) then .
        else .hooks += [{
          type: "command",
          command: $cmd,
          timeout: 10,
          statusMessage: "Checking for recursive in-place writes"
        }] end
      else . end
    )
  else
    .hooks.PreToolUse += [{
      matcher: "Bash",
      hooks: [{
        type: "command",
        command: $cmd,
        timeout: 10,
        statusMessage: "Checking for recursive in-place writes"
      }]
    }]
  end
' "$SETTINGS" > "$tmp"

# Never leave a broken settings.json behind: a malformed file silently
# disables every setting in it.
jq -e . "$tmp" >/dev/null || { echo "refusing to write malformed settings.json"; rm -f "$tmp"; exit 1; }
mv "$tmp" "$SETTINGS"
echo "  ✓ $SETTINGS (hooks.PreToolUse merged)"

echo ""
echo "Done. Open /hooks once (or restart Claude Code) if the hook does not fire yet."
