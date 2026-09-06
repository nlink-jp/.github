#!/usr/bin/env bash
# clone-all.sh — Clone or update all nlink-jp series repositories locally.
#
# Usage:
#   ./clone-all.sh [--with-archive] [DEST_DIR]
#
# If DEST_DIR is omitted the current directory is used.
# Existing repos are updated (git pull + submodule update) rather than re-cloned.
#
# --with-archive also takes archive-series, the umbrella holding the projects
# that are archived on GitHub. It is excluded by default: nothing in it can be
# built, released, or even committed to, so a working copy only earns its disk
# when you are deliberately reading old code.

set -euo pipefail

ORG="nlink-jp"
BASE_URL="https://github.com/${ORG}"

SERIES=(
  chatops-series
  cli-series
  cybersecurity-series
  lab-series
  lib-series
  lite-series
  skills-series
  util-series
)

with_archive=0
positional=()
for arg in "$@"; do
  case "$arg" in
    --with-archive) with_archive=1 ;;
    -h|--help)      sed -n '2,14p' "$0" | sed 's/^#\{1,\} \{0,1\}//'; exit 0 ;;
    -*)             echo "clone-all.sh: unknown option: $arg" >&2; exit 2 ;;
    *)              positional+=("$arg") ;;
  esac
done

if [ "$with_archive" -eq 1 ]; then
  SERIES+=(archive-series)
fi

DEST="${positional[0]:-$(pwd)}"
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
