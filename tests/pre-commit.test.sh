#!/usr/bin/env bash
# tests/pre-commit.test.sh — exercises hooks/pre-commit against staged content.
#
# The hook is run by hand, once per commit, on input that is almost always
# clean, so a rule that never matches and a rule that matches everything look
# the same from the outside. Both have happened: `xapp-` matched its own bare
# prefix, and no Slack setup guide could be committed until 2026-09-21.
#
# Every rule gets two cases: a placeholder of the kind a setup guide carries
# (must pass) and something shaped like the real secret (must block).
set -uo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/pre-commit"
TMP=$(mktemp -d)
pass=0; fail=0
ok()  { echo "ok   - $1"; pass=$((pass + 1)); }
no()  { echo "FAIL - $1"; fail=$((fail + 1)); }

# stage CONTENT -> stages a file holding it in a throwaway repo
stage() {
  rm -rf "$TMP/repo"; mkdir -p "$TMP/repo"
  git -C "$TMP/repo" init -q
  git -C "$TMP/repo" config user.email t@example.com
  git -C "$TMP/repo" config user.name t
  printf '%s\n' "$1" > "$TMP/repo/doc.md"
  git -C "$TMP/repo" add doc.md
}

# blocks LABEL CONTENT WANT(block|pass)
blocks() {
  local label="$1" content="$2" want="$3" out rc
  stage "$content"
  out=$(cd "$TMP/repo" && bash "$HOOK" 2>&1); rc=$?
  if [ "$want" = block ]; then
    if [ "$rc" -ne 0 ]; then ok "$label"; else no "$label"; printf '        the hook allowed it\n' >&2; fi
  else
    if [ "$rc" -eq 0 ]; then ok "$label"; else no "$label"; printf '        %s\n' "$out" >&2; fi
  fi
}

# The blocked-case fixtures are assembled at run time and never written as a
# literal. A string shaped like a real token IS one as far as GitHub's push
# protection is concerned, and a test file full of them cannot be pushed — the
# organisation learned that once already, in a fixture file.
digits11=$(printf '1%010d' 0)
digits13=$(printf '1%012d' 0)
alnum24='abcdefghijklmnopqrstuvwx'
hex32='0123456789abcdef0123456789abcdef'
bot_token="xox${_b:-b}-${digits11}-${digits13}-${alnum24}"
user_token="xox${_p:-p}-${digits11}-${digits13}-${alnum24}"
refresh_token="xoxe.xox${_p:-p}-1-${alnum24}"
app_token="xapp-1-A${digits11}-${digits13}-${hex32}"

echo "== Slack tokens"
blocks 'a bot token is blocked'            "token: $bot_token" block
blocks 'a user token is blocked'           "token: $user_token" block
blocks 'a refresh token is blocked'        "token: $refresh_token" block
blocks 'an app-level token is blocked'     "token: $app_token" block
blocks 'a bot-token placeholder passes'    'SLACK_BOT_TOKEN=xoxb-YOUR-BOT-TOKEN' pass
blocks 'an app-token placeholder passes'   'SLACK_APP_TOKEN=xapp-YOUR-APP-TOKEN' pass
blocks 'an elided app token passes'        'Paste the token (xapp-...) into the field' pass
blocks 'the bare word xapp passes'         'The App-Level Token begins with xapp-' pass

echo "== other rules"
anthropic_key="sk-${_ant:-ant}-api03-${alnum24}"
aws_key="AKIA$(printf %s "${hex32:0:16}" | tr a-f A-F)"   # the rule is [A-Z0-9]
google_key="AIza${alnum24}${hex32:0:11}"
blocks 'a service account email is blocked' 'sa: robot@my-project.iam.gserviceaccount.com' block
blocks 'an Anthropic key is blocked'        "key: $anthropic_key" block
blocks 'an AWS access key is blocked'       "id: $aws_key" block
blocks 'a Google API key is blocked'        "key: $google_key" block
blocks 'ordinary prose passes'              'This guide explains how to create the tokens.' pass
blocks 'an empty change passes'             '' pass

echo "------------------------------------------------------------"
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
