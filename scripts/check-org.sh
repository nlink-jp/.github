#!/usr/bin/env bash
# check-org.sh — Health check for all nlink-jp series repositories.
#
# Usage:
#   ./check-org.sh [DEST_DIR]
#
# Exit code: 0 if all checks pass, 1 if any check fails.

set -euo pipefail

SERIES=(
  cli-series
  chatops-series
  cybersecurity-series
  util-series
  lab-series
  lite-series
)

DEST="${1:-$(pwd)}"
DEST="$(cd "$DEST" && pwd)"

PASS="[OK]"
FAIL="[NG]"
WARN="[!!]"

errors=0

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

  # 6. Submodule pointers vs origin/main
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

echo "Destination: $DEST"
echo ""

for series in "${SERIES[@]}"; do
  target="$DEST/$series"
  if [ ! -d "$target/.git" ]; then
    echo "==> $series"
    echo "    $WARN not found locally (run clone-all.sh first)"
    echo ""
    continue
  fi
  check_series "$series" "$target"
  echo ""
done

if [ "$errors" -eq 0 ]; then
  echo "Result: all checks passed."
else
  echo "Result: $errors check(s) failed."
  exit 1
fi
