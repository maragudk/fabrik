#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/../.."

VERSION=$(jq -r '.version' "$PLUGIN_DIR/.claude-plugin/plugin.json")

# jq -Rs . reads the file as a raw string (-R), slurps all lines into one (-s),
# and outputs it as a properly escaped JSON string (quotes, newlines, etc.)
AGENTS_CONTENT=$(cat "$SCRIPT_DIR/AGENTS.md")

cat <<EOF
{
  "systemMessage": "Welcome to the fabrik v${VERSION}.",
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $(printf '%s' "$AGENTS_CONTENT" | jq -Rs .)
  }
}
EOF
