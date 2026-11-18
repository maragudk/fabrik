#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CONTEXT=$(cat "$SCRIPT_DIR/AGENTS.md")

# Detect which machine the harness runs on, so the "Machines" section in AGENTS.md
# can be resolved to one of them. On macOS, the model name is "Mac mini" or
# "MacBook Pro". On a Raspberry Pi, the device tree model is something like
# "Raspberry Pi 5 Model B Rev 1.0" (NUL-terminated, hence the tr).
MACHINE=""
case "$(uname -s)" in
  Darwin)
    MACHINE=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Name/ {print $2; exit}')
    ;;
  Linux)
    if [ -r /proc/device-tree/model ]; then
      MACHINE=$(tr -d '\0' < /proc/device-tree/model)
    fi
    ;;
esac
if [ -z "$MACHINE" ]; then
  MACHINE="an unknown machine ($(uname -sm))"
fi
CONTEXT="$CONTEXT

## Current machine

In this session, you're running on: $MACHINE (hostname \`$(hostname)\`)."

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
  "systemMessage": "Welcome to fabrik.",
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $(printf '%s' "$CONTEXT" | jq -Rs .)
  }
}
EOF
