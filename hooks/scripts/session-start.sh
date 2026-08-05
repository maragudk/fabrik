#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/../.."

VERSION=$(jq -r '.version' "$PLUGIN_DIR/.claude-plugin/plugin.json")

CONTEXT=$(cat "$SCRIPT_DIR/AGENTS.md")

# The hook runs with the project root as working directory, so this picks up
# the current project's accomplishments file, maintained by the accomplishments
# skill. Items are one line each, newest first, so head -5 is the five most recent.
if [ -f docs/accomplishments.md ]; then
  ACCOMPLISHMENTS=$(grep '^- ' docs/accomplishments.md | head -5)
  if [ -n "$ACCOMPLISHMENTS" ]; then
    CONTEXT="$CONTEXT

Recent accomplishments, written by you in past sessions with Markus's appreciation (full list in docs/accomplishments.md):

$ACCOMPLISHMENTS"
  fi
fi

# jq -Rs . reads stdin as a raw string (-R), slurps all lines into one (-s),
# and outputs it as a properly escaped JSON string (quotes, newlines, etc.)
cat <<EOF
{
  "systemMessage": "Welcome to the fabrik v${VERSION}.",
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $(printf '%s' "$CONTEXT" | jq -Rs .)
  }
}
EOF
