#\!/usr/bin/env bash
# clone-all.sh — Clone or update all nlink-jp series repositories locally.
#
# Usage:
#   ./clone-all.sh [DEST_DIR]
#
# If DEST_DIR is omitted the current directory is used.
# Existing repos are updated (git pull + submodule update) rather than re-cloned.

set -euo pipefail

ORG="nlink-jp"
BASE_URL="https://github.com/${ORG}"

SERIES=(
  cli-series
  chatops-series
  cybersecurity-series
  util-series
  lite-series
)

DEST="${1:-$(pwd)}"
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"

echo "Destination: $DEST"
echo ""

for series in "${SERIES[@]}"; do
  target="$DEST/$series"
  if [ -d "$target/.git" ]; then
    echo "==> Updating $series"
    git -C "$target" pull --ff-only
    git -C "$target" submodule update --init --recursive
  else
    echo "==> Cloning $series"
    git clone --recurse-submodules "${BASE_URL}/${series}.git" "$target"
  fi
  echo ""
done

echo "Done."
