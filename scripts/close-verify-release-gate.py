#!/usr/bin/env python3
"""Convert a CLI Makefile's open-form verify-release block to the closed form.

The open form ends a chain of unzip / --version / spctl in `|| true`, so the
escape covers all of it: a zip that does not unpack, or a binary that does not
run, exits 0 and the release uploads it.

Deterministic by construction: the block must match the known shape exactly
once, and the two parameters (the zip path expression and the in-zip binary
path) are taken from that match. Anything else is left untouched and reported —
a guessed rewrite of a release gate is worse than no rewrite.

Usage:  close_gate.py --check <Makefile>...     report only
        close_gate.py --apply <Makefile>...     rewrite in place
"""
import re
import sys

# The open block, as vendored from the old template. Captures:
#   1 = zip path expression, 2 = in-zip binary path (both as Make text)
OPEN = re.compile(
    r'\t@tmp=\$\$\(mktemp -d\) && \\\n'
    r'\t\tunzip -oq "(?P<zip>[^"]+)" -d "\$\$tmp" && \\\n'
    r'\t\t"(?P<bin>\$\$tmp/[^"]+)" --version && \\\n'
    r'\t\tspctl -a -vv -t install "(?P=bin)" 2>&1 \| head -2 \|\| true; \\\n'
    r'\t\trm -rf "\$\$tmp"\n'
    r'\t@echo "verify-release: OK \(\$\(VERSION\), notarization marker present\)"\n'
)

CLOSED = '''\t@tmp=$$(mktemp -d); rc=0; \\
\t\tif ! unzip -oq "{zip}" -d "$$tmp"; then \\
\t\t\techo "verify-release: FAIL — the zip does not unpack. Do not upload it."; rc=1; \\
\t\telif ! out=$$("{bin}" --version 2>&1); then \\
\t\t\techo "verify-release: FAIL — the packaged binary does not run:"; \\
\t\t\techo "  $$out"; rc=1; \\
\t\telif ! printf '%s\\n' "$$out" | grep -qF "$(VERSION)"; then \\
\t\t\techo "verify-release: FAIL — the packaged binary reports \\"$$out\\", not $(VERSION)."; \\
\t\t\techo "  The zip holds a build from another tag (re-run make package)."; rc=1; \\
\t\telse \\
\t\t\techo "  $$out"; \\
\t\t\tspctl -a -vv -t install "{bin}" 2>&1 | head -2 || true; \\
\t\tfi; \\
\t\trm -rf "$$tmp"; \\
\t\texit $$rc
\t@echo "verify-release: OK ($(VERSION), notarized, unpacks, runs, reports its version)"
'''

# The comment above the target, when it still describes the marker gate alone.
OLD_DOC = '## verify-release: refuse to release an un-notarized zip (marker gate)\n'
NEW_DOC = ('## verify-release: refuse to release a zip that is un-notarized, stale, does\n'
           '## not unpack, does not run, or holds a build from another tag. Every step\n'
           '## fails closed; only the spctl line is informational.\n')


def recipe(text, target):
    """The recipe of TARGET as make reads it: the tab-indented lines after its
    rule line, and their continuations. Blank and comment-only lines between
    them are skipped rather than taken as the end — make ignores them there too.
    """
    out, inside, cont = [], False, False
    for line in text.split('\n'):
        if inside:
            if cont or line.startswith('\t'):
                out.append(line)
                cont = line.endswith('\\')
                continue
            if not line.strip() or line.lstrip().startswith('#'):
                continue
            inside = False
        if line.startswith(target + ':'):
            inside, cont = True, False
    return '\n'.join(out)


def convert(text):
    """Return (new_text, note). new_text is None when nothing was changed."""
    if 'verify-release:' not in text:
        return None, 'no verify-release target'
    # Read from the verify-release recipe alone: web-fetch's e2e target ends in
    # `exit $$rc`, and a whole-file test called its open gate closed.
    if 'exit $$rc' in recipe(text, 'verify-release'):
        return None, 'already closed'
    hits = list(OPEN.finditer(text))
    if len(hits) != 1:
        return None, f'open block matched {len(hits)} times — left untouched'
    m = hits[0]
    out = text[:m.start()] + CLOSED.format(zip=m.group('zip'), bin=m.group('bin')) + text[m.end():]
    if OLD_DOC in out:
        out = out.replace(OLD_DOC, NEW_DOC, 1)
    return out, f'converted (zip={m.group("zip")}, bin={m.group("bin")})'


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ('--check', '--apply'):
        print(__doc__)
        return 2
    apply = sys.argv[1] == '--apply'
    changed = 0
    for path in sys.argv[2:]:
        with open(path, encoding='utf-8') as fh:
            text = fh.read()
        new, note = convert(text)
        print(f'{"CONVERT" if new else "skip   "} {path}: {note}')
        if new and apply:
            with open(path, 'w', encoding='utf-8') as fh:
                fh.write(new)
            changed += 1
    print(f'\n{changed} file(s) rewritten' if apply else '\n(check only)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
