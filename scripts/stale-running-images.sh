#!/usr/bin/env bash
# stale-running-images.sh — which resident processes are still executing a
# binary that has since been replaced.
#
# Usage:
#   ./stale-running-images.sh            # table, exit 0 whatever it finds
#   ./stale-running-images.sh --strict    # exit 1 when anything is stale
#   STALE_LIB_ONLY=1 . ./stale-running-images.sh   # load the helpers only
#
# Why this exists, and why it is NOT part of check-org.sh
# ------------------------------------------------------
# A release reaches a user in three stages, and each has a different check:
#
#   1. the tap points at the release   — a file; check-org.sh verifies it
#   2. the install matches the tap     — `<tool> --version`
#   3. the running process is that install — only visible from the process
#
# `brew upgrade` replaces the Cellar directory, but a running process keeps the
# inode it started with. So an MCP server spawned before an upgrade answers with
# the old behaviour while every file on disk is current. Measured 2026-09-21: an
# urlscan-lookup server was serving the 0.2.0 manual two releases after the
# behaviour changed, and an image-forge server was reporting a model licence as
# "commercial OK" that its publisher forbids.
#
# Stage 3 drift is the normal state of this machine, not a defect: Claude
# Desktop has no way to reload an MCP server, so its servers keep whatever they
# started with until the app itself restarts. A gate that can never be green
# teaches everyone to ignore the gate, so this is a tool you run when the answer
# matters — after a release, or when a tool answers something you just fixed —
# rather than a check that fails every day.
#
# The answer it gives is a list of hosts to restart. Restarting them is the
# operator's decision: it ends running sessions.

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
echo "$count stale image(s) across $tools tool(s) — answering from a binary that is no longer installed."
echo "Restart the host that spawned them to pick up the installed version:"
echo "  - Claude Code: the session's MCP servers restart with the session"
echo "  - Claude Desktop: quit and reopen the app (it has no MCP reload)"
echo "  - gem-agent / lagent: restart the runtime"
[ "$strict" -eq 1 ] && exit 1
exit 0
