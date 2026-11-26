#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

MODE="default"
if [ "${1:-}" = "--antigravity" ] || { [ -n "${PLUGIN_ROOT:-}" ] && [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; }; then
  MODE="antigravity"
fi

# By default, the working directory is the project root. Under --antigravity
# (or PLUGIN_ROOT without CLAUDE_PLUGIN_ROOT), stdin JSON supplies the project
# path while the working directory may be the plugin directory.
PROJECT_DIR="."
if [ "$MODE" = "antigravity" ]; then
  PROJECT_DIR=$(jq -r '([.cwd?, .workspacePaths[0]?] | map(select(type == "string" and length > 0)) | first) // empty' 2> /dev/null)
fi

CONTEXT=$(cat "$SCRIPT_DIR/AGENTS.md")

# Detect which machine the harness runs on, so the "Machines" section in AGENTS.md
# can be resolved to one of them. On macOS, the model name is "Mac mini" or
# "MacBook Pro". On a Raspberry Pi, the device tree model is something like
# "Raspberry Pi 5 Model B Rev 1.0" (NUL-terminated, hence the tr).
# Cloud sessions on claude.ai set CLAUDE_CODE_REMOTE=true, as documented at
# https://code.claude.com/docs/en/env-vars.
MACHINE=""
if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
  MACHINE="a container on claude.ai (Claude Code on the web)"
else
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
fi
if [ -z "$MACHINE" ]; then
  MACHINE="an unknown machine ($(uname -sm))"
fi
CONTEXT="$CONTEXT

## Current machine

In this session, you're running on: $MACHINE (hostname \`$(hostname)\`)."

# Items in docs/accomplishments.md are one line each, newest first, so head -5
# is the five most recent.
if [ -n "$PROJECT_DIR" ] && [ -f "$PROJECT_DIR/docs/accomplishments.md" ]; then
  ACCOMPLISHMENTS=$(grep '^- ' "$PROJECT_DIR/docs/accomplishments.md" | head -5)
  if [ -n "$ACCOMPLISHMENTS" ]; then
    CONTEXT="$CONTEXT

Recent accomplishments, written by you in past sessions with Markus's appreciation (full list in docs/accomplishments.md):

$ACCOMPLISHMENTS"
  fi
fi

# Install the global git hooks that scan commits for secrets. The installer
# always exits 0 and prints a warning only when scanning isn't active.
SYSTEM_MESSAGE="Welcome to fabrik."
GIT_HOOKS_WARNING=$(bash "$SCRIPT_DIR/install-git-hooks.sh" < /dev/null 2> /dev/null)
if [ -n "$GIT_HOOKS_WARNING" ]; then
  SYSTEM_MESSAGE="$SYSTEM_MESSAGE Warning: $GIT_HOOKS_WARNING"
  CONTEXT="$CONTEXT

## Secret scanning

Warning: $GIT_HOOKS_WARNING"
fi

# Antigravity fails to process SessionStart output when systemMessage.metadata
# is set, so prepend the welcome line into systemMessage instead.
if [ "$MODE" = "antigravity" ]; then
  jq -n \
    --arg msg "$(printf '%s\n\n%s' "$SYSTEM_MESSAGE" "$CONTEXT")" \
    '{
      injectSteps: [
        {
          systemMessage: {
            systemMessage: $msg
          }
        }
      ]
    }'
  exit 0
fi

# jq -Rs . reads stdin as a raw string (-R), slurps all lines into one (-s),
# and outputs it as a properly escaped JSON string (quotes, newlines, etc.)
cat <<EOF
{
  "systemMessage": $(printf '%s' "$SYSTEM_MESSAGE" | jq -Rs .),
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $(printf '%s' "$CONTEXT" | jq -Rs .)
  }
}
EOF
