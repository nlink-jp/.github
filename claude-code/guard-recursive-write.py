#!/usr/bin/env python3
"""Block in-place rewrite commands aimed at a relative path.

Why this exists: `gofmt -w .` run from the wrong directory reformatted every
Go file in the nlink-jp workspace — twice, months apart, despite notes and
procedures telling the agent to pass absolute paths. Procedure fails exactly
when attention lapses, which is the same moment the accident happens, so the
control has to live outside the agent. This runs as a PreToolUse hook.

Blocked: a tool that rewrites files in place whose targets are relative
(`.`, `./x`, `src`, `*.go`) or absent (implicit cwd).
Allowed: absolute targets, `~`-rooted targets, and a command anchored by a
leading `cd /absolute/path &&`.
"""
import json
import re
import shlex
import sys

# Tools that rewrite files in place. Value is the condition that turns
# rewriting on: a list of flags, or None when the tool always rewrites.
# (Annotations are avoided throughout: this must run on the system python,
# which is 3.9 here.)
IN_PLACE_WRITERS = {
    "gofmt": ["-w"],
    "goimports": ["-w"],
    "sed": ["-i", "--in-place"],
    "prettier": ["--write", "-w"],
    "eslint": ["--fix"],
    "clang-format": ["-i"],
    "autopep8": ["-i", "--in-place"],
    "yapf": ["-i", "--in-place"],
    "shfmt": ["-w"],
    "taplo": ["format"],
    "dart": ["format"],
    "black": None,
    "isort": None,
    "rustfmt": None,
    "swiftformat": None,
    "swift-format": ["-i"],
}

# Tools whose danger depends on a subcommand rather than a flag.
SUBCOMMAND_WRITERS = {
    "ruff": lambda toks: "format" in toks or "--fix" in toks,
}

# Tokens that are options rather than paths.
OPTION_RE = re.compile(r"^-")

# Shell operators that separate independent commands.
SEGMENT_SPLIT_RE = re.compile(r"&&|\|\||;|\||\n")


def is_absolute(token):
    return token.startswith("/") or token.startswith("~/") or token == "~"


def path_args(tool, tokens):
    """Return the tokens that name files/directories for this invocation."""
    args = [t for t in tokens[1:] if not OPTION_RE.match(t)]
    if tool == "sed":
        # BSD sed spells the in-place suffix as a separate empty argument
        # (`sed -i '' ...`); that empty token is not a path.
        args = [t for t in args if t != ""]
        # The first remaining non-option token is the script, not a path —
        # unless the script was supplied with -e/-f.
        if not any(t in ("-e", "-f", "--expression", "--file") for t in tokens):
            args = args[1:]
    if tool in ("ruff", "dart", "taplo", "cargo"):
        # Drop the subcommand token (format / check / ...).
        args = [a for a in args if a not in ("format", "check", "fix")]
    return args


def dangerous(tokens):
    """Report whether this single command rewrites relative paths."""
    if not tokens:
        return False, ""
    tool = tokens[0].rsplit("/", 1)[-1]

    if tool in SUBCOMMAND_WRITERS:
        if not SUBCOMMAND_WRITERS[tool](tokens):
            return False, ""
    elif tool in IN_PLACE_WRITERS:
        flags = IN_PLACE_WRITERS[tool]
        if flags is not None:
            # -i / -w may be bundled (e.g. `sed -i.bak`, `gofmt -lw`).
            if not any(
                t == f or (t.startswith(f) and not t.startswith("--")) or
                (f == "-i" and re.match(r"^-[a-zA-Z]*i", t)) or
                (f == "-w" and re.match(r"^-[a-zA-Z]*w", t))
                for t in tokens[1:] for f in flags
            ):
                return False, ""
    else:
        return False, ""

    targets = path_args(tool, tokens)
    if not targets:
        return True, f"`{tool}` was given no path, so it rewrites the current directory"
    relative = [t for t in targets if not is_absolute(t)]
    if relative:
        return True, f"`{tool}` targets the relative path(s) {' '.join(relative)}"
    return False, ""


def anchored_by_cd(command):
    """True when the command starts with `cd <absolute path>`."""
    first = SEGMENT_SPLIT_RE.split(command, maxsplit=1)[0].strip()
    try:
        toks = shlex.split(first)
    except ValueError:
        return False
    return len(toks) >= 2 and toks[0] == "cd" and is_absolute(toks[1])


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0  # never block on a payload we cannot read
    command = (payload.get("tool_input") or {}).get("command") or ""
    if not command.strip():
        return 0

    if anchored_by_cd(command):
        return 0

    reasons = []
    for segment in SEGMENT_SPLIT_RE.split(command):
        segment = segment.strip()
        if not segment:
            continue
        try:
            tokens = shlex.split(segment)
        except ValueError:
            continue
        hit, why = dangerous(tokens)
        if hit:
            reasons.append(why)

    if not reasons:
        return 0

    detail = "; ".join(reasons)
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                f"Blocked by guard-recursive-write: {detail}. "
                "A recursive in-place rewrite must name an absolute path — the shell's "
                "working directory is not reliable between tool calls, and this exact "
                "pattern reformatted the whole nlink-jp workspace twice. "
                "Re-run it as `gofmt -w /absolute/path/to/repo`, or prefix the command "
                "with `cd /absolute/path &&`. Module-scoped alternatives such as "
                "`go fmt ./...` are safer still: they fail harmlessly outside a module."
            ),
        }
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
