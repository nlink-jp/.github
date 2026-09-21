#!/usr/bin/env python3
"""Refuse the shell commands that keep going wrong in the same way.

Why this exists: procedure fails exactly when attention lapses, which is the
same moment the accident happens, so the control has to live outside the
agent. This runs as a PreToolUse hook. Two families are refused.

1. In-place rewrites aimed at a relative path. `gofmt -w .` run from the wrong
   directory reformatted every Go file in the nlink-jp workspace — twice,
   months apart, despite notes telling the agent to pass absolute paths.

   Blocked: a tool that rewrites files in place whose targets are relative
   (`.`, `./x`, `src`, `*.go`) or absent (implicit cwd). Besides its own name,
   a tool is recognised behind `xcrun [options]`, and swift-format also as
   SwiftPM's two-word form `swift format`. Other launchers are not seen
   through. Allowed: absolute targets, `~`-rooted targets, a command anchored
   by a leading `cd /absolute/path &&`, and read-only invocations — no
   in-place flag, or a read-only subcommand (`swift format lint`, `swift
   format dump-configuration`).

2. Shell footguns that recurred after being written down. Each one was
   recorded in memory, then stepped on again — three times for one of them —
   and the maintainer named the pattern: the same failure, then a retry, every
   time, with the risk of damaging the environment. A note is read when it is
   remembered; this is read every time.

   - In-place sed, at any path. This machine's `sed` is GNU, so the BSD form
     `sed -i '' 's/x/y/' FILE` takes '' as the script and the substitution as
     a *file name*: the edit silently does not happen, and the named files are
     opened for rewriting. Edit with python3 or the Edit tool instead.
   - `PIPESTATUS` in a command the tool runs under zsh. It is bash-only; under
     zsh it is empty and a status read through it falls back to `$?` of the
     pipe's last stage — a failed make reported as rc=0. Allowed inside
     `bash -c '...'`, or in a script written through a heredoc.
   - A single-quoted grep pattern with a `$` in the middle, without `-F`.
     `$` is an anchor, so `grep 'exit $$rc'` (a Makefile escape pasted into a
     pattern) matched nothing and reported 59 converted files as unconverted.
     `$` at the end, before `)` or `|`, or escaped as `\\$` is left alone.

   Heredoc bodies are removed before this family is judged: writing a script
   is not running it, and a script that is run with bash is bash's business.
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
    "swift-format": ["-i", "--in-place"],
}

# Tools whose danger depends on a subcommand rather than a flag.
SUBCOMMAND_WRITERS = {
    "ruff": lambda toks: "format" in toks or "--fix" in toks,
}

# Options that consume the following token, which is therefore not a path.
# (`--option=value` needs no entry: it is one token and starts with `-`.)
VALUE_OPTIONS = {
    "swift-format": (
        "--configuration", "--offsets", "--lines", "--assume-filename",
        "--enable-experimental-feature",
    ),
}

# swift-format subcommands that never write. The default, `format`, does.
SWIFT_FORMAT_READ_ONLY = ("lint", "dump-configuration")

# `xcrun` options that consume the following token, and those that make it
# print the tool's path instead of running it.
XCRUN_VALUE_OPTIONS = ("--sdk", "-sdk", "--toolchain", "-toolchain")
XCRUN_FIND_OPTIONS = ("-f", "--find")

# Tokens that are options rather than paths.
OPTION_RE = re.compile(r"^-")

def split_segments(command):
    """The independent commands in a line: split at `&&`, `||`, `;`, `|`, `&`
    and newlines, but never inside '...' or "..." — the shell does not.

    A splitter that ignored quotes cut `sed -i 's/a/b/; s/c/d/' FILE` at the
    `;` inside the script; the piece had an unbalanced quote, shlex refused
    it, and the piece was skipped — so the one command that mattered was never
    judged. `&` separates only when it is not part of `&&`, `>&` or `&>`.
    """
    segments, cur, quote, i, n = [], [], None, 0, len(command)
    while i < n:
        c = command[i]
        if quote:
            cur.append(c)
            if c == "\\" and quote == '"' and i + 1 < n:
                cur.append(command[i + 1])
                i += 2
                continue
            if c == quote:
                quote = None
            i += 1
            continue
        if c == "\\" and i + 1 < n:
            cur.append(command[i:i + 2])
            i += 2
            continue
        if c in ("'", '"'):
            quote = c
        elif command.startswith("&&", i) or command.startswith("||", i):
            segments.append("".join(cur))
            cur = []
            i += 2
            continue
        elif c in ";|\n" or (
            c == "&" and not (i > 0 and command[i - 1] in "<>")
            and not command.startswith("&>", i)
        ):
            segments.append("".join(cur))
            cur = []
            i += 1
            continue
        cur.append(c)
        i += 1
    segments.append("".join(cur))
    return [s.strip() for s in segments if s.strip()]


def words(segment):
    """shlex's reading of a segment, or — when shlex refuses it (an unbalanced
    quote the shell would also reject) — a plain whitespace split. Never
    nothing: a segment the guard cannot read is judged on its words, not
    waved through.
    """
    try:
        return shlex.split(segment)
    except ValueError:
        return segment.split()


def is_absolute(token):
    return token.startswith("/") or token.startswith("~/") or token == "~"


def path_args(tool, tokens):
    """Return the tokens that name files/directories for this invocation."""
    takes_value = VALUE_OPTIONS.get(tool, ())
    args = []
    skip = False
    for t in tokens[1:]:
        if skip:
            skip = False
        elif t in takes_value:
            skip = True
        elif not OPTION_RE.match(t):
            args.append(t)
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


def normalise(tokens):
    """See through the spellings that hide a tool from the tables.

    Returns the tokens as if the tool had been typed directly, and the
    spelling that was typed, for the message.
    """
    typed = []
    if tokens and tokens[0].rsplit("/", 1)[-1] == "xcrun":
        # `xcrun [options] tool args...`
        i = 1
        while i < len(tokens) and OPTION_RE.match(tokens[i]):
            if tokens[i] in XCRUN_FIND_OPTIONS:
                return [], ""  # prints the tool's path; launches nothing
            i += 2 if tokens[i] in XCRUN_VALUE_OPTIONS else 1
        typed.append("xcrun")
        tokens = tokens[i:]
    if not tokens:
        return [], ""
    tool = tokens[0].rsplit("/", 1)[-1]
    typed.append(tool)
    if tool == "swift" and tokens[1:2] == ["format"]:
        # SwiftPM forwards `swift format ...` to swift-format. Every other
        # `swift` subcommand (build, test, package, run) is left alone.
        typed.append("format")
        tokens = ["swift-format"] + tokens[2:]
    return tokens, " ".join(typed)


def dangerous(tokens):
    """Report whether this single command rewrites relative paths."""
    tokens, typed = normalise(tokens)
    if not tokens:
        return False, ""
    tool = tokens[0].rsplit("/", 1)[-1]

    if tool == "swift-format" and tokens[1:2]:
        # The subcommand word is one only when it leads (measured:
        # `swift-format -r lint DIR` formats, taking `lint` as a path), so
        # both tests look at the same token — dropping `format` first would
        # promote a following `lint` from path to subcommand.
        if tokens[1] in SWIFT_FORMAT_READ_ONLY:
            return False, ""
        if tokens[1] == "format":
            # The default subcommand spelled out is not a path.
            tokens = tokens[:1] + tokens[2:]

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
        return True, f"`{typed}` was given no path, so it rewrites the current directory"
    relative = [t for t in targets if not is_absolute(t)]
    if relative:
        return True, f"`{typed}` targets the relative path(s) {' '.join(relative)}"
    return False, ""


HEREDOC_RE = re.compile(r"<<(-?)\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\2")


def strip_heredocs(command):
    """Remove heredoc bodies, keeping the line that opens each one.

    `cmd <<'EOF'` ... `EOF` (and <<"EOF", <<EOF, <<-EOF) — the body is data
    handed to the command, not commands for this shell to run.
    """
    lines = command.split("\n")
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        m = HEREDOC_RE.search(line)
        i += 1
        if not m:
            continue
        dash, tag = m.group(1), m.group(3)
        while i < len(lines):
            body = lines[i].lstrip("\t") if dash else lines[i]
            i += 1
            if body.strip() == tag:
                break
    return "\n".join(out)


def single_quoted(segment):
    """The contents of each '...' in a segment, as the shell passes them."""
    return re.findall(r"'([^']*)'", segment)


# `$` followed by something other than the end, `)` or `|`, and not escaped.
MID_DOLLAR_RE = re.compile(r"(?<!\\)\$(?=[^)|])")


def footguns(command):
    """Reasons to refuse from family 2, judged on the command minus heredocs."""
    reasons = []
    body = strip_heredocs(command)

    # The command word, read from the start of the text rather than from the
    # first segment: the segment splitter is not quote-aware, so it cuts
    # `bash -c 'false | true; ...'` inside the quotes and loses the word.
    # Leading VAR=value assignments are skipped.
    first_word = ""
    for word in body.lstrip().split():
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", word):
            continue
        first_word = word.rsplit("/", 1)[-1]
        break
    if "PIPESTATUS" in body and first_word != "bash":
        reasons.append(
            "`PIPESTATUS` is bash-only; the tool shell is zsh, where it is empty and "
            "the status falls back to `$?` of the pipe's last stage. Capture the status "
            "without a pipe: `cmd >log 2>&1; rc=$?`"
        )

    for segment in split_segments(body):
        tokens = words(segment)
        if not tokens:
            continue
        tool = tokens[0].rsplit("/", 1)[-1]

        if tool in ("sed", "gsed") and any(
            t == "--in-place" or t.startswith("--in-place=") or
            re.match(r"^-i", t) or re.match(r"^-[a-zA-Z]*i[a-zA-Z]*$", t)
            for t in tokens[1:]
        ):
            reasons.append(
                "in-place sed is refused: this machine's sed is GNU, so `sed -i '' 's/x/y/' "
                "FILE` takes '' as the script and the substitution as a file name. Edit with "
                "python3 (read, replace, assert it changed, write) or the Edit tool"
            )

        if tool in ("grep", "egrep"):
            fixed = any(
                t in ("-F", "--fixed-strings") or re.match(r"^-[a-zA-Z]*F[a-zA-Z]*$", t)
                for t in tokens[1:]
            )
            if not fixed and any(MID_DOLLAR_RE.search(p) for p in single_quoted(segment)):
                reasons.append(
                    "a single-quoted grep pattern has a `$` in the middle, and `$` is a regex "
                    "anchor, so the literal is never matched. Use `grep -F` for a literal, or "
                    "escape it as `\\$`"
                )
    return list(dict.fromkeys(reasons))  # one line per reason, however many hits


def anchored_by_cd(command):
    """True when the command starts with `cd <absolute path>`."""
    segments = split_segments(command)
    if not segments:
        return False
    try:
        toks = shlex.split(segments[0])
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

    # Family 2 is judged first and regardless of a leading absolute `cd`: that
    # anchor answers "which directory", and none of these is about directories.
    footgun_reasons = footguns(command)

    reasons = []
    if not anchored_by_cd(command):
        # Heredoc bodies are data. They are also where a stray apostrophe
        # ("don't") would open a quote that swallows the commands after it.
        for segment in split_segments(strip_heredocs(command)):
            hit, why = dangerous(words(segment))
            if hit and why not in reasons:
                reasons.append(why)

    if not reasons and not footgun_reasons:
        return 0

    parts = []
    if reasons:
        detail = "; ".join(reasons)
        parts.append(
            f"Blocked by guard-recursive-write: {detail}. "
            "A recursive in-place rewrite must name an absolute path — the shell's "
            "working directory is not reliable between tool calls, and this exact "
            "pattern reformatted the whole nlink-jp workspace twice. "
            "Re-run it as `gofmt -w /absolute/path/to/repo`, or prefix the command "
            "with `cd /absolute/path &&`. Module-scoped alternatives such as "
            "`go fmt ./...` are safer still: they fail harmlessly outside a module."
        )
    if footgun_reasons:
        parts.append(
            "Blocked by guard (recurring shell footgun): " + "; ".join(footgun_reasons) + ". "
            "Each of these was written down and then stepped on again; the guard refuses "
            "it every time so the retry never has to happen."
        )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": " ".join(parts),
        }
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
