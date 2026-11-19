#!/bin/bash
# Installs the global git hooks from ../git-hooks (secret scanning, plus
# pass-through to repository hooks) and points the global core.hooksPath at
# them, unless it's already set to something else.
#
# The hooks are copied to a stable directory, so core.hooksPath stays valid
# when this script's own location changes:
# ${XDG_CONFIG_HOME:-~/.config}/fabrik/git-hooks
#
# Prints nothing when the hooks are active, or a one-line warning when they
# aren't. Always exits 0.

unset CDPATH
SRC=$(cd "$(dirname "$0")/../git-hooks" 2> /dev/null && pwd)

warn() {
  echo "Secret scanning is not active: $1"
  exit 0
}

command -v git > /dev/null 2>&1 || warn "git is not installed, so fabrik's secret-scanning git hooks were not installed."
[ -n "$SRC" ] || warn "fabrik's git hooks are missing from the plugin, so they were not installed."
if [ -n "$XDG_CONFIG_HOME" ]; then
  DEST="$XDG_CONFIG_HOME/fabrik/git-hooks"
elif [ -n "$HOME" ]; then
  DEST="$HOME/.config/fabrik/git-hooks"
else
  warn "neither HOME nor XDG_CONFIG_HOME is set, so fabrik's secret-scanning git hooks were not installed."
fi

# Is the installed copy current? Extra files in DEST (from other tools, or
# .DS_Store) don't count, and are left alone.
current() {
  [ -z "$(diff -rq "$SRC" "$DEST" 2>&1 | grep -vF "Only in $DEST")" ] || return 1
  for f in "$SRC"/*; do
    [ -x "$DEST/${f##*/}" ] || return 1
  done
}

# Each file is copied to a temporary name unique to this process, then renamed
# into place, so concurrent installs don't trip over each other and a running
# commit never sees a half-written hook.
if ! current; then
  mkdir -p "$DEST" 2> /dev/null || warn "could not create $DEST, so fabrik's secret-scanning git hooks were not installed."
  for f in "$SRC"/*; do
    tmp="$DEST/.${f##*/}.$$.tmp"
    { cp "$f" "$tmp" && chmod 755 "$tmp" && mv -f "$tmp" "$DEST/${f##*/}"; } 2> /dev/null
  done
  rm -f "$DEST"/.*.$$.tmp
  current || warn "could not copy fabrik's secret-scanning git hooks to $DEST."
fi

# Read the global value including [include]d files, then the system value,
# since a global setting would override a system one.
CURRENT=$(git config --global --includes --get core.hooksPath 2> /dev/null)
status=$?
if [ $status = 1 ]; then
  CURRENT=$(git config --system --includes --get core.hooksPath 2> /dev/null)
  status=$?
  [ $status = 1 ] || [ $status = 0 ] || status=1
  if [ $status = 1 ]; then
    # Unset everywhere. Write the path with ~ when it's under HOME, so a global
    # git config shared between machines with different home directories
    # stays valid.
    want=$DEST
    if [ -n "$HOME" ]; then
      case "$DEST" in
        "$HOME"/*) want="~/${DEST#"$HOME"/}" ;;
      esac
    fi
    git config --global core.hooksPath "$want" 2> /dev/null && exit 0
    # Another session may have set it at the same moment (config lock).
    [ "$(git config --global --includes --get core.hooksPath 2> /dev/null)" = "$want" ] && exit 0
    warn "could not set the global git core.hooksPath to $want."
  fi
elif [ $status != 0 ]; then
  warn "could not read the global git config, so fabrik's secret-scanning git hooks were not installed."
fi

# Already set: fine if it's our directory (in any spelling), otherwise leave it
# alone. Setting it to something else is also the documented opt-out.
expanded=$CURRENT
case "$expanded" in
  "~/"*) expanded="$HOME/${expanded#"~/"}" ;;
esac
while [ "${expanded%/}" != "$expanded" ]; do expanded=${expanded%/}; done
[ "$expanded" = "$DEST" ] && exit 0
if [ -d "$expanded" ] && [ "$(cd "$expanded" && pwd -P)" = "$(cd "$DEST" && pwd -P)" ]; then
  exit 0
fi
warn "git core.hooksPath is set to $CURRENT, so fabrik's secret-scanning git hooks (installed in $DEST) don't run. Don't change core.hooksPath without asking the user."
