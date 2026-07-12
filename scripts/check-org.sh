#!/usr/bin/env bash
# check-org.sh — Health check for all nlink-jp series repositories.
#
# Usage:
#   ./check-org.sh [DEST_DIR]
#
# Exit code: 0 if all checks pass, 1 if any check fails.

set -euo pipefail

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

  # 6. Submodule build conventions
  if [ -f "$dir/.gitmodules" ]; then
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$dir/$subpath"
      name=$(basename "$subpath")
      makefile="$subdir/Makefile"
      gitignore="$subdir/.gitignore"

      if [ -f "$makefile" ]; then
        # Check: make build must output to dist/, not root or bin/
        if grep -qE '^\s*go build .* -o \$\(BINARY\)' "$makefile" 2>/dev/null || \
           grep -qE '^\s*go build .* -o \./[a-z]' "$makefile" 2>/dev/null; then
          echo "    $FAIL $name: make build outputs to project root (must use dist/)"
          errors=$((errors + 1))
        elif grep -qE '^\s*go build .* -o bin/' "$makefile" 2>/dev/null || \
             grep -qE '-o \$\(BIN_DIR\)/' "$makefile" 2>/dev/null; then
          echo "    $FAIL $name: make build outputs to bin/ (must use dist/)"
          errors=$((errors + 1))
        fi
      fi

      if [ -f "$gitignore" ]; then
        # Check: bare binary name in .gitignore (no leading /)
        if grep -qxF "$name" "$gitignore" 2>/dev/null; then
          echo "    $FAIL $name: .gitignore has bare '$name' (may exclude cmd/$name/)"
          errors=$((errors + 1))
        fi
        # Check: dist/ must be excluded
        if [ -f "$makefile" ] && grep -q 'dist/' "$makefile" 2>/dev/null; then
          if ! grep -qE '^/?dist/?$' "$gitignore" 2>/dev/null; then
            echo "    $FAIL $name: .gitignore missing 'dist/'"
            errors=$((errors + 1))
          fi
        fi
      fi
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 7. Scan for likely secrets in tracked files
  if [ -f "$dir/.gitmodules" ]; then
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$dir/$subpath"
      name=$(basename "$subpath")

      # Scan tracked files for common secret patterns
      secret_hits=$(git -C "$subdir" grep -lE \
        '\.iam\.gserviceaccount\.com|xoxb-[0-9]|xoxp-[0-9]|sk-ant-|AKIA[A-Z0-9]{16}' \
        HEAD -- '*.yaml' '*.yml' '*.json' '*.toml' '*.env' '*.sh' 2>/dev/null \
        | grep -v 'example\|template\|test\|README\|CHANGELOG\|\.md$' || true)
      if [ -n "$secret_hits" ]; then
        echo "    $FAIL $name: possible secrets in tracked files:"
        echo "$secret_hits" | sed 's/^/            /'
        errors=$((errors + 1))
      fi
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 8. go.mod must not contain local replace directives (leaks local paths)
  if [ -f "$dir/.gitmodules" ]; then
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$dir/$subpath"
      name=$(basename "$subpath")

      replace_hits=$(git -C "$subdir" grep -n 'replace.*=>.*/' \
        HEAD -- 'go.mod' '**/go.mod' 2>/dev/null \
        | grep -v '// local-dev-only' || true)
      if [ -n "$replace_hits" ]; then
        echo "    $FAIL $name: go.mod contains local replace (leaks local paths):"
        echo "$replace_hits" | sed 's/^/            /'
        errors=$((errors + 1))
      fi
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 9. .gitmodules must use HTTPS URLs (not SSH)
  #    (was check 8 before go.mod replace check was added)
  if [ -f "$dir/.gitmodules" ]; then
    if grep -q 'git@github.com' "$dir/.gitmodules" 2>/dev/null; then
      echo "    $FAIL .gitmodules: SSH URLs found (must use https://github.com/)"
      grep 'git@' "$dir/.gitmodules" | sed 's/^/        /'
      errors=$((errors + 1))
    fi
  fi

  # 10. Vendored Homebrew tap-generation assets match canonical
  #     (.github/templates). Only the tap-generation files are checked; the
  #     signing scripts (codesign/notarize) intentionally diverge in some GUI
  #     repos, so they are not sync-checked here.
  if [ -f "$dir/.gitmodules" ] && [ -d "$DEST/.github/templates" ]; then
    tpl="$DEST/.github/templates"
    while IFS= read -r subpath; do
      subpath="${subpath#        }"
      subdir="$dir/$subpath"
      name=$(basename "$subpath")
      for f in gen-brew.sh formula.rb.tmpl cask.rb.tmpl release-brew.mk; do
        vend="$subdir/scripts/$f"
        [ -f "$vend" ] || continue
        if ! cmp -s "$vend" "$tpl/$f"; then
          echo "    $FAIL $name: vendored scripts/$f drifted from .github/templates/$f"
          errors=$((errors + 1))
        fi
      done
    done < <(git -C "$dir" submodule foreach --quiet 'echo "        $displaypath"')
  fi

  # 11. Submodule pointers vs origin/main
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
