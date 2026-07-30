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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEST="${1:-$(pwd)}"
DEST="$(cd "$DEST" && pwd)"

PASS="[OK]"
FAIL="[NG]"
WARN="[!!]"

errors=0

# --- Makefile build-output resolution ---------------------------------------
# The convention is that `make build` writes into dist/. What matters is the
# resolved *value* of the output path, not the variable name used to spell it:
# `BIN_DIR := dist` is perfectly conventional. These helpers resolve the
# directory a Makefile actually builds into, so the check can compare values.

# makefile_var MAKEFILE VAR -> value of the last assignment to VAR.
# Handles `VAR = v`, `VAR := v`, `VAR ?= v`, `VAR += v` at the start of a line,
# plus the `$(eval VAR := v)` form used inside some recipes. Trailing comments
# and whitespace are stripped.
makefile_var() {
  local mf="$1" var="$2"
  sed -nE \
    -e "s/^[[:space:]]*${var}[[:space:]]*[:?+]?=[[:space:]]*([^#]*).*\$/\1/p" \
    -e "s/.*\\\$\\(eval[[:space:]]+${var}[[:space:]]*[:?+]?=[[:space:]]*(.*)\\).*/\1/p" \
    "$mf" 2>/dev/null | tail -1 | sed -E 's/[[:space:]]+$//'
}

# makefile_expand MAKEFILE STRING -> STRING with $(VAR) references expanded
# from the Makefile's own assignments. Stops at the first reference it cannot
# resolve (an unassigned variable, or a function call such as $(word ...)),
# leaving it literal for the caller to notice.
makefile_expand() {
  local mf="$1" s="$2" var val pat i
  for i in 1 2 3 4 5 6 7 8; do
    case "$s" in *'$('*) ;; *) break ;; esac
    var="${s#*"\$("}"
    var="${var%%)*}"
    case "$var" in ''|*[^A-Za-z0-9_]*) break ;; esac
    val=$(makefile_var "$mf" "$var")
    [ -n "$val" ] || break
    # The pattern must come from a variable: an inline ${s//\$($var)/$val}
    # silently fails to substitute in bash. Do not "simplify" this.
    pat="\$($var)"
    s="${s//"$pat"/$val}"
  done
  printf '%s' "$s"
}

# makefile_build_dirs MAKEFILE -> one line per `go build ... -o TARGET` recipe,
# holding the directory that target resolves to:
#   dist       conventional
#   .          the project root
#   ?          could not be resolved — the caller must not guess
makefile_build_dirs() {
  local mf="$1" line target dir prefix had_var
  while IFS= read -r line; do
    # Cheap pre-filter, then confirm on the expanded line so that builds routed
    # through a variable (GO_BUILD := go build ...) are seen too.
    case "$line" in *-o*) ;; *) continue ;; esac
    printf '%s\n' "$(makefile_expand "$mf" "$line")" \
      | grep -qE 'go[[:space:]]+build' || continue

    # The target is taken from the raw line (so expanded flag values can never
    # be mistaken for it) and only then resolved.
    target=$(printf '%s\n' "$line" \
      | awk '{for (i=1;i<NF;i++) if ($i=="-o") {print $(i+1); exit}}')
    [ -n "$target" ] || continue
    [ "$target" = "/dev/null" ] && continue   # discard build, not an artifact

    target=$(makefile_expand "$mf" "$target")
    had_var=0
    case "$target" in *'$('*) had_var=1 ;; esac
    prefix="${target%%"\$("*}"                # text before the first $( , if any
    case "$prefix" in
      */*) dir="${prefix%/*}"
           dir="${dir#./}"
           dir="${dir%/}"
           [ -n "$dir" ] || dir="." ;;
      *)   if [ "$had_var" -eq 1 ]; then dir="?"; else dir="."; fi ;;
    esac
    # A shell variable in the path (release staging dirs use $$stagedir) is not
    # resolvable from the Makefile alone.
    case "$dir" in *'$'*) dir="?" ;; esac
    printf '%s\n' "$dir"
  done < "$mf"
}

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
        # Check: make build must output to dist/. Compared on the resolved
        # value, so any variable name is fine (BIN_DIR := dist passes).
        while IFS= read -r outdir; do
          case "$outdir" in
            dist|dist/*) continue ;;   # conventional
            '?')         continue ;;   # unresolvable — don't guess
            .) echo "    $FAIL $name: make build outputs to project root (must use dist/)" ;;
            *) echo "    $FAIL $name: make build outputs to $outdir/ (must use dist/)" ;;
          esac
          errors=$((errors + 1))
          break
        done < <(makefile_build_dirs "$makefile")
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

# tests/check-org.test.sh sources this script to exercise the helpers above
# without running the org-wide checks.
if [ "${CHECK_ORG_LIB_ONLY:-}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi

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

# Machine-level agent guards. Repo conventions cannot enforce these — they
# live in ~/.claude — so audit them here instead of trusting that whoever
# set the machine up remembered.
echo "==> agent guards (this machine)"
if [ -x "$SCRIPT_DIR/install-claude-guards.sh" ]; then
  if ! "$SCRIPT_DIR/install-claude-guards.sh" --check; then
    errors=$((errors + 1))
  fi
else
  echo "    $WARN install-claude-guards.sh not found or not executable"
fi
echo ""

if [ "$errors" -eq 0 ]; then
  echo "Result: all checks passed."
else
  echo "Result: $errors check(s) failed."
  exit 1
fi
