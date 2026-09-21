#!/usr/bin/env bash
# stale-running-images.sh — which resident processes are still executing a
# binary that has since been replaced.
#
# Usage:
#   ./stale-running-images.sh            # table, exit 0 whatever it finds
#   ./stale-running-images.sh --strict    # exit 1 when anything is stale
#   STALE_LIB_ONLY=1 . ./stale-running-images.sh   # load the helpers only
#
# What this is for
# ----------------
# A debugging aid for one specific confusion: a tool answers something you have
# already fixed. `brew upgrade` replaces the Cellar directory, but a resident
# process keeps the inode it started with — so an MCP server spawned before an
# upgrade goes on answering with the old behaviour while every file on disk is
# current, and nothing on disk shows it. Measured 2026-09-21 while chasing
# exactly that: a urlscan-lookup server was serving the 0.2.0 manual two
# releases after the behaviour changed.
#
# What it is NOT
# --------------
# It is not a health check, and a process holding an older build is not a
# defect. These are development repositories: an agent carrying the binary it
# started with is the normal state of a working machine, and Claude Desktop has
# no way to reload an MCP server anyway. Requiring every resident process to
# match the installed version is an operations requirement, and importing it
# here would make a permanently failing check out of ordinary development.
#
# So this is not in check-org.sh, not a step in the release checklist, and it
# exits 0 whatever it finds. It names hosts; restarting them ends running
# sessions and is the operator's call.

set -uo pipefail

CELLAR_PREFIX="${CELLAR_PREFIX:-/opt/homebrew}"
TAP_DIR="${TAP_DIR:-$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)/homebrew-tap}"

# cellar_ref PATH -> "<tool> <version>" for a Homebrew Cellar executable path,
# empty for anything else (a system binary, a build tree, a deleted temp file).
# The version must start with a digit so a Cellar layout change cannot turn a
# directory name into a version.
cellar_ref() {
  printf '%s' "${1:-}" |
    sed -n -E "s|^${CELLAR_PREFIX}/Cellar/([^/]+)/([0-9][^/]*)/.*|\1 \2|p"
}

# installed_cellar_version TOOL -> the version <prefix>/bin/<tool> resolves to,
# empty when the tool is not installed through the Cellar.
installed_cellar_version() {
  local link
  link=$(readlink "$CELLAR_PREFIX/bin/${1:-}" 2>/dev/null) || return 0
  printf '%s' "$link" | sed -n -E 's|.*/Cellar/[^/]+/([^/]+)/.*|\1|p'
}

# ours TOOL — true when the tool has a formula or cask in the local tap. Keeps
# an unrelated Homebrew daemon out of the report.
ours() {
  [ -f "$TAP_DIR/Formula/${1:-}.rb" ] || [ -f "$TAP_DIR/Casks/${1:-}.rb" ]
}

# held_images — "<tool> <version> <pid>" per running process, one lsof pass.
# -Fpn emits "p<pid>" followed by "n<path>" for each file, so the pid carries
# down to the executable line that follows it.
held_images() {
  lsof -d txt -Fpn 2>/dev/null |
    awk '/^p/{pid=substr($0,2)} /^n/{print pid, substr($0,2)}' |
    while read -r pid path; do
      ref=$(cellar_ref "$path")
      [ -n "$ref" ] && printf '%s %s\n' "$ref" "$pid"
    done
}

# stale_lines — "<tool>: running X, installed Y (pid …)" per drifting tool.
stale_lines() {
  held_images |
    sort |
    awk '{key=$1" "$2; pids[key]=pids[key]" "$3} END {for (k in pids) print k, pids[k]}' |
    while read -r tool held pids; do
      ours "$tool" || continue
      cur=$(installed_cellar_version "$tool")
      [ -n "$cur" ] || continue
      [ "$held" != "$cur" ] || continue
      printf '%s: running %s, installed %s (pid %s)\n' "$tool" "$held" "$cur" "$pids"
    done |
    sort
}

if [ "${STALE_LIB_ONLY:-}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi

strict=0
[ "${1:-}" = "--strict" ] && strict=1

if ! command -v lsof >/dev/null 2>&1; then
  echo "lsof is not available, so what a running process holds cannot be read." >&2
  exit 2
fi
if [ ! -d "$TAP_DIR" ]; then
  echo "tap not found at $TAP_DIR, so our tools cannot be told from everything else." >&2
  exit 2
fi

out=$(stale_lines)
if [ -z "$out" ]; then
  echo "Every resident process holds the installed version."
  exit 0
fi

printf '%s\n' "$out"
echo ""
# One line per (tool, held version): a tool spawned by several hosts at
# different times appears once per version it is still holding.
count=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
tools=$(printf '%s\n' "$out" | cut -d: -f1 | sort -u | wc -l | tr -d ' ')
echo "$count running image(s) across $tools tool(s) are not the installed version."
echo "If you want one of these to pick up the installed version, restart its host:"
echo "  - Claude Code: the session's MCP servers restart with the session"
echo "  - Claude Desktop: quit and reopen the app (it has no MCP reload)"
echo "  - gem-agent / lagent: restart the runtime"
[ "$strict" -eq 1 ] && exit 1
exit 0
