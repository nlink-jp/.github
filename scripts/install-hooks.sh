#!/usr/bin/env bash
# install-hooks.sh — Install org-wide git hooks to all series and submodule repos.
#
# Usage:
#   ./install-hooks.sh [DEST_DIR]
#
# Installs the pre-commit hook from .github/hooks/ into:
#   - Each series repo's .git/hooks/
#   - Each submodule repo's .git/hooks/ (resolved from .git file)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_DIR="$(cd "$SCRIPT_DIR/../hooks" && pwd)"
DEST="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

SERIES=(
  cli-series
  chatops-series
  cybersecurity-series
  lab-series
  lite-series
  util-series
)

installed=0
skipped=0

install_hook() {
  local repo_dir="$1"
  local name="$2"

  # Resolve .git directory (submodules use a .git file pointing elsewhere)
  local git_dir
  if [ -f "$repo_dir/.git" ]; then
    git_dir="$(cd "$repo_dir" && git rev-parse --git-dir)"
    git_dir="$(cd "$repo_dir" && cd "$git_dir" && pwd)"
  elif [ -d "$repo_dir/.git" ]; then
    git_dir="$repo_dir/.git"
  else
    return
  fi

  local hooks_dir="$git_dir/hooks"
  mkdir -p "$hooks_dir"

  if [ -f "$hooks_dir/pre-commit" ] && diff -q "$HOOK_DIR/pre-commit" "$hooks_dir/pre-commit" > /dev/null 2>&1; then
    skipped=$((skipped + 1))
    return
  fi

  cp "$HOOK_DIR/pre-commit" "$hooks_dir/pre-commit"
  chmod +x "$hooks_dir/pre-commit"
  echo "  ✓ $name"
  installed=$((installed + 1))
}

echo "Installing pre-commit hooks from: $HOOK_DIR"
echo "Target directory: $DEST"
echo ""

for series in "${SERIES[@]}"; do
  target="$DEST/$series"
  if [ ! -d "$target" ]; then
    continue
  fi

  echo "==> $series"
  install_hook "$target" "$series"

  # Install to submodules
  if [ -f "$target/.gitmodules" ]; then
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$target/$subpath"
      if [ -d "$subdir" ]; then
        install_hook "$subdir" "  $subpath"
      fi
    done < <(git -C "$target" submodule foreach --quiet 'echo "        $displaypath"' 2>/dev/null)
  fi
  echo ""
done

echo "Done: $installed installed, $skipped already up to date."
