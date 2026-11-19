#!/bin/bash
# Tests for fabrik's global git hooks (hooks/git-hooks/), their installer
# (hooks/scripts/install-git-hooks.sh), and session-start.sh, which runs it.
#
# Run: bash hooks/test/test-git-hooks.sh
#
# Everything happens in a temporary directory. HOME, XDG_CONFIG_HOME, and
# GIT_CONFIG_GLOBAL point into it, so the real global git config and
# ~/.config are never read or changed. Test repositories use a local
# core.hooksPath pointing at the source hooks.
#
# Fake keys are built at runtime, so no key-shaped string is ever committed
# to this repository (which would trip the scanner it tests).

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
HOOKS="$ROOT/hooks/git-hooks"
HOOKS_BEFORE=$(ls -l "$HOOKS")
SCRIPTS="$ROOT/hooks/scripts"

T=$(mktemp -d "${TMPDIR:-/tmp}/fabrik-git-hooks-test.XXXXXX") || exit 1
T=$(cd "$T" && pwd -P)
trap 'rm -rf "$T"' EXIT

export HOME="$T/home"
export XDG_CONFIG_HOME="$T/xdg"
export GIT_CONFIG_GLOBAL="$T/gitconfig"
export GIT_CONFIG_NOSYSTEM=1
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_CEILING_DIRECTORIES
mkdir -p "$HOME"

git config --global user.name "Test Robot"
git config --global user.email "robot@example.com"
git config --global init.defaultBranch main
git config --global commit.gpgsign false
git config --global advice.detachedHead false

# Belt and braces: refuse to run if the global config isn't the temp file.
case "$(git config --global --show-origin --get user.name)" in
  "file:$T/gitconfig"*) ;;
  *) echo "refusing to run: global git config is not isolated" >&2; exit 1 ;;
esac

PASSED=0
FAILED=0
pass() { PASSED=$((PASSED + 1)); }
fail() {
  FAILED=$((FAILED + 1))
  echo "FAIL: $1" >&2
  [ -f "$T/err" ] && sed 's/^/    | /' "$T/err" >&2
}
check() { # description, then a command that must succeed
  local desc=$1
  shift
  if "$@"; then pass; else fail "$desc"; fi
}

# --- Fake keys -------------------------------------------------------------

UPPER=ABCDEFGHIJKLMNOPQRSTUVWXYZ
DIGITS=0123456789
ALNUM="abcdefghijklmnopqrstuvwxyz$UPPER$DIGITS"

# fake <length> [alphabet]: a deterministic, random-looking string.
fake() {
  local chars=${2:-$ALNUM} s="" i=0
  while [ $i -lt "$1" ]; do
    s="$s${chars:$(((i * 7 + i / 5 + 3) % ${#chars})):1}"
    i=$((i + 1))
  done
  printf '%s' "$s"
}

ANT_API="sk-ant-api03-$(fake 93 "$ALNUM-_")AA"
ANT_ADMIN="sk-ant-admin01-$(fake 93 "$ALNUM-_")AA"
ANT_OAUTH="sk-ant-oat01-$(fake 93 "$ALNUM-_")AA"
OAI_PROJ="sk-proj-$(fake 74 "$ALNUM-_")T3BlbkFJ$(fake 74 "$ALNUM-_")"
OAI_SVC="sk-svcacct-$(fake 58 "$ALNUM-_")T3BlbkFJ$(fake 58 "$ALNUM-_")"
OAI_ADMIN="sk-admin-$(fake 58 "$ALNUM-_")T3BlbkFJ$(fake 58 "$ALNUM-_")"
OAI_LEGACY="sk-$(fake 20)T3BlbkFJ$(fake 20)"
AWS_AKIA="AKIA$(fake 16 "$UPPER$DIGITS")"
AWS_ASIA="ASIA$(fake 16 "$UPPER$DIGITS")"
AWS_SECRET="$(fake 40 "$ALNUM/+")"
GOOGLE="AIza$(fake 35 "$ALNUM-_")"
ALL_KEYS="$ANT_API $ANT_ADMIN $ANT_OAUTH $OAI_PROJ $OAI_SVC $OAI_ADMIN $OAI_LEGACY $AWS_AKIA $AWS_ASIA $AWS_SECRET $GOOGLE"

# --- Helpers ---------------------------------------------------------------

N=0
new_repo() { # sets r to a fresh repo using the source hooks
  N=$((N + 1))
  r="$T/repo$N"
  git init -q "$r"
  git -C "$r" config core.hooksPath "$HOOKS"
}

write() { # repo, path, content (printf %b, so \n and \0 work)
  mkdir -p "$(dirname "$1/$2")"
  printf '%b' "$3" > "$1/$2"
}

commit() { # repo, extra args...; output in $T/out and $T/err
  local r=$1
  shift
  git -C "$r" commit -q -m "test commit" "$@" > "$T/out" 2> "$T/err"
}

# redacted: no fake key leaks into the hook output beyond its first 8
# characters (checked as 8-character windows after the shown prefix and at the
# end), and every printed match is at most 8 characters plus the ellipsis.
redacted() {
  local k
  for k in $ALL_KEYS; do
    grep -qF -e "${k:8:8}" -e "${k:$((${#k} - 8))}" "$T/err" "$T/out" && return 1
  done
  ! LC_ALL=C grep -E '^  .*  .*  ' "$T/err" | LC_ALL=C grep -vqE '  .{1,8}…$'
}

findings() { grep -c '^  ' "$T/err"; }

# with_timeout <command...>: fail instead of hanging if the command runs away.
with_timeout() {
  "$@" &
  local pid=$!
  (sleep 60 && kill "$pid") > /dev/null 2>&1 &
  local watchdog=$!
  wait "$pid"
  local rc=$?
  kill "$watchdog" 2> /dev/null
  wait "$watchdog" 2> /dev/null
  return $rc
}

# --- Table: one staged file per row ----------------------------------------
#
# path | content | expectation
#   pass        commit succeeds
#   block:N:S   commit fails with N findings, and stderr contains S

while IFS='|' read -r path content expect; do
  new_repo
  write "$r" "$path" "$content"
  git -C "$r" add -- "$path"
  commit "$r"
  rc=$?
  case "$expect" in
    pass)
      check "$path: commit passes" [ $rc = 0 ]
      ;;
    block:*)
      want=${expect#block:}
      count=${want%%:*}
      text=${want#*:}
      check "$path: commit blocked" [ $rc != 0 ]
      check "$path: $count finding(s)" [ "$(findings)" = "$count" ]
      check "$path: stderr contains '$text'" grep -qF -- "$text" "$T/err"
      check "$path: output redacted" redacted
      check "$path: tells agents not to use --no-verify" grep -qF -- "--no-verify" "$T/err"
      ;;
  esac
done <<EOF
clean.go|package main\n\nfunc main() {}\n|pass
anthropic.go|const key = "$ANT_API"\n|block:1:anthropic.go:1  Anthropic API key  sk-ant-a…
anthropic-admin.txt|ANTHROPIC_ADMIN_KEY=$ANT_ADMIN\n|block:1:Anthropic API key
anthropic-oauth.json|{"token": "$ANT_OAUTH"}\n|block:1:Anthropic API key
anthropic-placeholder.md|Set ANTHROPIC_API_KEY=sk-ant-api03-... first.\n|pass
openai-proj.py|client = OpenAI(api_key="$OAI_PROJ")\n|block:1:OpenAI API key  sk-proj-…
openai-svcacct.env.example|OPENAI_API_KEY=$OAI_SVC\n|block:1:OpenAI API key
openai-admin.yaml|key: $OAI_ADMIN\n|block:1:OpenAI API key
openai-legacy.sh|export OPENAI_API_KEY=$OAI_LEGACY\n|block:1:OpenAI API key
openai-legacy-too-long.txt|${OAI_LEGACY}x\n|pass
openai-placeholder.md|Keys look like sk-proj-abc123.\n|pass
aws-akia.ini|aws_access_key_id = $AWS_AKIA\n|block:1:AWS access key ID  AKIA
aws-asia.ini|id=$AWS_ASIA\n|block:1:AWS access key ID
aws-akia-in-word.txt|X${AWS_AKIA}\n${AWS_AKIA}_suffix\n|pass
aws-secret.ini|aws_secret_access_key = $AWS_SECRET\n|block:1:AWS secret access key
aws-secret.yaml|  AWS_SECRET_ACCESS_KEY: "$AWS_SECRET"\n|block:1:AWS secret access key
aws-secret.json|{"SecretAccessKey": "$AWS_SECRET"}\n|block:1:AWS secret access key
aws-secret.py|os.environ["AWS_SECRET_ACCESS_KEY"] = '$AWS_SECRET'\n|block:1:AWS secret access key
aws-secret-cli.sh|aws configure set aws_secret_access_key $AWS_SECRET\n|block:1:AWS secret access key
aws-secret-flag.sh|tool --secret-access-key $AWS_SECRET\n|block:1:AWS secret access key
aws-secret-short-name.sh|AWS_SECRET_KEY=$AWS_SECRET\n|block:1:AWS secret access key
aws-secret.xml|<SecretAccessKey>$AWS_SECRET</SecretAccessKey>\n|block:1:AWS secret access key
aws-secret-escaped.json|"{\\\\"SecretAccessKey\\\\": \\\\"$AWS_SECRET\\\\"}"\n|block:1:AWS secret access key
aws-secret.c|setenv("AWS_SECRET_ACCESS_KEY", "$AWS_SECRET", 1);\n|block:1:AWS secret access key
aws-secret-redacted.ini|aws_secret_access_key = $AWS_SECRET\n|block:1:AWS secret access key  ${AWS_SECRET:0:4}…
aws-secret-no-context.txt|checksum = $AWS_SECRET\n|pass
aws-secret-too-long.ini|aws_secret_access_key = ${AWS_SECRET}AB\n|pass
aws-both.ini|aws_access_key_id=$AWS_AKIA\naws_secret_access_key=$AWS_SECRET\n|block:2:aws-both.ini:2  AWS secret access key
google.js|const key = '$GOOGLE';\n|block:1:Google API key  AIza
google-too-short.txt|${GOOGLE%?}\n|pass
line-numbers.txt|one\ntwo\nthree $GOOGLE\n|block:1:line-numbers.txt:3
plus-plus.txt|++ b/fake-header.txt\n+++ b/fake-header.txt\n$GOOGLE\n|block:1:plus-plus.txt:3
crlf.txt|key=$GOOGLE\r\n|block:1:Google API key
two-keys.txt|$ANT_API and $GOOGLE\n|block:2:Google API key
my dir/spaced name.txt|$GOOGLE\n|block:1:my dir/spaced name.txt:1
binary.bin|\0\0\0$GOOGLE\0\n|pass
nul-late.txt|$(fake 9000)\0 $GOOGLE\n|block:1:Google API key
.env|SECRET=hunter2\n|block:1:.env  .env file
deep/nested/.env||block:1:deep/nested/.env  .env file
.env.example|SECRET=\n|pass
.env.local|SECRET=hunter2\n|pass
config.env|SECRET=hunter2\n|pass
EOF

# --- Scenarios ---------------------------------------------------------------

# Removed lines and context lines are not scanned.
new_repo
write "$r" keys.txt "a\n$GOOGLE\nb\n"
git -C "$r" add keys.txt
commit "$r" --no-verify
write "$r" keys.txt "a\n$GOOGLE\nb\nc\n"
git -C "$r" add keys.txt
commit "$r"
check "context line with key: commit passes" [ $? = 0 ]
write "$r" keys.txt "a\nb\nc\n"
git -C "$r" add keys.txt
commit "$r"
check "removed line with key: commit passes" [ $? = 0 ]
git -C "$r" rm -q keys.txt
commit "$r"
check "deleted file: commit passes" [ $? = 0 ]

# Diff settings that add context lines must not hide added lines after them.
new_repo
write "$r" f.txt "1\n\n3\n4\n5\n6\n"
git -C "$r" add f.txt
commit "$r"
write "$r" f.txt "ONE\n\n3\n$GOOGLE\n5\n6\n"
git -C "$r" add f.txt
git -C "$r" config diff.interHunkContext 3
git -C "$r" config diff.suppressBlankEmpty true
commit "$r"
check "diff.interHunkContext: blocked" [ $? != 0 ]
check "diff.interHunkContext: right line" grep -qF "f.txt:4  Google API key" "$T/err"
git -C "$r" config --unset diff.interHunkContext
GIT_DIFF_OPTS=--unified=5 commit "$r"
check "GIT_DIFF_OPTS context: blocked" [ $? != 0 ]
check "GIT_DIFF_OPTS context: right line" grep -qF "f.txt:4  Google API key" "$T/err"

# Several hunks and files in one commit: line numbers in the new files.
new_repo
seq 1 20 > "$r/f.txt"
git -C "$r" add f.txt
commit "$r"
awk -v k="$GOOGLE" 'NR == 5 || NR == 15 { print k; next } NR == 10 { next } { print }' "$r/f.txt" > "$r/f.new"
mv "$r/f.new" "$r/f.txt"
write "$r" g.txt "clean\n$AWS_AKIA\n"
git -C "$r" add f.txt g.txt
commit "$r"
check "multi-hunk: 3 findings" [ "$(findings)" = 3 ]
check "multi-hunk: first hunk line" grep -qF "f.txt:5  Google API key" "$T/err"
check "multi-hunk: line after a removed line" grep -qF "f.txt:14  Google API key" "$T/err"
check "multi-hunk: second file" grep -qF "g.txt:2  AWS access key ID" "$T/err"

# A quoted path (git quotes names containing a double quote).
new_repo
write "$r" 'we"ird.txt' "$GOOGLE\n"
git -C "$r" add -- 'we"ird.txt'
commit "$r"
check "quoted path: blocked" [ $? != 0 ]
check "quoted path: reported as git quotes it" grep -qF '"we\"ird.txt":1  Google API key' "$T/err"

# .env: renaming a file into place blocks; editing an already-tracked one doesn't.
new_repo
write "$r" env.txt "A=1\n"
git -C "$r" add env.txt
commit "$r"
git -C "$r" mv env.txt .env
commit "$r"
check "rename into .env: blocked" [ $? != 0 ]
check "rename into .env: reported" grep -qF ".env  .env file" "$T/err"
commit "$r" --no-verify
write "$r" .env "A=2\n"
git -C "$r" add .env
commit "$r"
check "modified tracked .env: passes" [ $? = 0 ]

# --amend scans the amended commit's changes.
new_repo
write "$r" a.txt "a\n"
git -C "$r" add a.txt
commit "$r"
write "$r" a.txt "a\n$GOOGLE\n"
git -C "$r" add a.txt
commit "$r" --amend
check "amend with key: blocked" [ $? != 0 ]

# git commit -a picks up an unstaged tracked change.
new_repo
write "$r" app.conf "x=1\n"
git -C "$r" add app.conf
commit "$r"
write "$r" app.conf "x=1\nkey=$ANT_API\n"
commit "$r" -a
check "commit -a with key in tracked file: blocked" [ $? != 0 ]
check "commit -a: reports the file" grep -qF "app.conf:2  Anthropic API key" "$T/err"
commit "$r" app.conf
check "commit <path> with key: blocked" [ $? != 0 ]
check "commit <path>: nothing committed" [ "$(git -C "$r" rev-list --count HEAD)" = 1 ]

# Committing from a subdirectory, without -C.
new_repo
write "$r" sub/dir/key.txt "$GOOGLE\n"
(cd "$r/sub/dir" && git add key.txt && git commit -q -m test > "$T/out" 2> "$T/err")
check "commit from a subdirectory: blocked" [ $? != 0 ]
check "commit from a subdirectory: path from repo root" grep -qF "sub/dir/key.txt:1" "$T/err"

# A linked worktree (where .git is a file) is scanned and chains to the main
# repository's hooks.
new_repo
write "$r" README "hi\n"
git -C "$r" add README
commit "$r"
git -C "$r" worktree add -q "$T/wt$N" -b wt 2> /dev/null
check "linked worktree: .git is a file" [ -f "$T/wt$N/.git" ]
write "$T/wt$N" key.txt "$GOOGLE\n"
git -C "$T/wt$N" add key.txt
commit "$T/wt$N"
check "linked worktree with key: blocked" [ $? != 0 ]
write "$r" .git/hooks/pre-commit '#!/bin/sh\necho ran > "$(git rev-parse --git-common-dir)/../local-hook-ran"\n'
chmod +x "$r/.git/hooks/pre-commit"
write "$T/wt$N" key.txt "clean\n"
git -C "$T/wt$N" add key.txt
commit "$T/wt$N"
check "linked worktree, clean: passes" [ $? = 0 ]
check "linked worktree: repo-local pre-commit ran" [ -f "$r/local-hook-ran" ]
write "$r" .git/hooks/commit-msg '#!/bin/sh\necho ran > "$(git rev-parse --git-common-dir)/../commit-msg-ran"\n'
chmod +x "$r/.git/hooks/commit-msg"
write "$T/wt$N" key.txt "still clean\n"
git -C "$T/wt$N" add key.txt
commit "$T/wt$N"
check "linked worktree: repo-local commit-msg ran" [ -f "$r/commit-msg-ran" ]

# Chaining to the repository's own pre-commit hook.
new_repo
write "$r" .git/hooks/pre-commit '#!/bin/sh\necho "local hook: $# args" > local-hook-ran\nexit "$(cat .git/local-exit 2>/dev/null || echo 0)"\n'
chmod +x "$r/.git/hooks/pre-commit"
write "$r" a.txt "a\n"
git -C "$r" add a.txt
commit "$r"
check "local pre-commit: commit passes" [ $? = 0 ]
check "local pre-commit: ran" [ -f "$r/local-hook-ran" ]
rm -f "$r/local-hook-ran"
write "$r" b0.txt "b\n"
git -C "$r" add b0.txt
CDPATH="$r" commit "$r"
check "local pre-commit with CDPATH set: ran" [ -f "$r/local-hook-ran" ]
rm -f "$r/local-hook-ran"
write "$r" .git/local-exit "3"
write "$r" b.txt "b\n"
git -C "$r" add b.txt
commit "$r"
check "local pre-commit failing: commit blocked" [ $? != 0 ]
check "local pre-commit failing: it ran" [ -f "$r/local-hook-ran" ]
(cd "$r" && "$HOOKS/pre-commit" > "$T/out" 2> "$T/err")
check "local pre-commit failing: exit code passes through" [ $? = 3 ]
rm -f "$r/local-hook-ran" "$r/.git/local-exit"
write "$r" c.txt "$GOOGLE\n"
git -C "$r" add c.txt
commit "$r"
check "key plus local pre-commit: blocked" [ $? != 0 ]
check "key plus local pre-commit: local hook not run" [ ! -f "$r/local-hook-ran" ]
chmod -x "$r/.git/hooks/pre-commit"
git -C "$r" rm -q --cached c.txt
commit "$r"
check "non-executable local pre-commit: ignored" [ ! -f "$r/local-hook-ran" ]
check "non-executable local pre-commit: hint" grep -qF "hook was ignored because it's not set as executable" "$T/err"

# A failing scanner blocks a real commit, before the repository's hook runs.
new_repo
cp -R "$HOOKS" "$T/hooks-broken"
printf '#!/bin/sh\nexit 1\n' > "$T/hooks-broken/scan-secrets"
git -C "$r" config core.hooksPath "$T/hooks-broken"
write "$r" .git/hooks/pre-commit '#!/bin/sh\ntouch local-hook-ran\n'
chmod +x "$r/.git/hooks/pre-commit"
write "$r" a.txt "a\n"
git -C "$r" add a.txt
commit "$r"
check "failing scanner: commit blocked" [ $? != 0 ]
check "failing scanner: local hook not run" [ ! -f "$r/local-hook-ran" ]

# Pass-through stubs: args (commit-msg) and exit codes.
new_repo
write "$r" .git/hooks/commit-msg '#!/bin/sh\ncp "$1" commit-msg-seen\ngrep -q forbidden "$1" && exit 1\nexit 0\n'
chmod +x "$r/.git/hooks/commit-msg"
write "$r" a.txt "a\n"
git -C "$r" add a.txt
git -C "$r" commit -q -m "a fine message" > "$T/out" 2> "$T/err"
check "commit-msg stub: commit passes" [ $? = 0 ]
check "commit-msg stub: local hook got the message file" grep -qF "a fine message" "$r/commit-msg-seen"
write "$r" b.txt "b\n"
git -C "$r" add b.txt
git -C "$r" commit -q -m "a forbidden message" > "$T/out" 2> "$T/err"
check "commit-msg stub: local failure blocks the commit" [ $? != 0 ]

# Pass-through stubs: stdin (pre-push gets the refs being pushed on stdin).
git init -q --bare "$T/remote.git"
git -C "$r" remote add origin "$T/remote.git"
write "$r" .git/hooks/pre-push '#!/bin/sh\necho "$1" > pre-push-seen\ncat >> pre-push-seen\n'
chmod +x "$r/.git/hooks/pre-push"
git -C "$r" push -q origin main > "$T/out" 2> "$T/err"
check "pre-push stub: push succeeds" [ $? = 0 ]
check "pre-push stub: local hook got args and stdin" grep -q "^refs/heads/main [0-9a-f]* refs/heads/main" "$r/pre-push-seen"
check "pre-push stub: local hook got the remote name" grep -qx "origin" "$r/pre-push-seen"

# Git LFS: with no repository hook, git-lfs's hook commands run in its place.
mkdir -p "$T/lfsbin"
printf '#!/bin/sh\necho "$1" >> "%s/lfs-called"\ncat > /dev/null\n' "$T" > "$T/lfsbin/git-lfs"
chmod +x "$T/lfsbin/git-lfs"
new_repo
write "$r" a.txt "a\n"
git -C "$r" add a.txt
PATH="$T/lfsbin:$PATH" commit "$r"
check "no LFS: git-lfs not called" [ ! -f "$T/lfs-called" ]
mkdir "$r/.git/lfs"
write "$r" b.txt "b\n"
git -C "$r" add b.txt
PATH="$T/lfsbin:$PATH" commit "$r"
check "LFS repo: git lfs post-commit runs" grep -qx "post-commit" "$T/lfs-called"
mkdir -p "$T/nolfs"
ln -s "$(command -v git)" "$T/nolfs/git"
ln -s "$(command -v dirname)" "$T/nolfs/dirname"
(cd "$r" && PATH="$T/nolfs" "$HOOKS/pre-push" origin "$T/x.git" < /dev/null > "$T/out" 2> "$T/err")
check "LFS repo without git-lfs: pre-push fails" [ $? = 2 ]
check "LFS repo without git-lfs: says why" grep -qF "git-lfs is not installed" "$T/err"

# No recursion when the repository's hooks are the global hooks themselves.
# These use a copy of the hooks, so nothing (like a re-run `git init` copying
# templates through the symlink) can ever write into the source directory.
cp -R "$HOOKS" "$T/hooks-copy"
new_repo
git -C "$r" config core.hooksPath "$T/hooks-copy"
rm -rf "$r/.git/hooks"
ln -s "$T/hooks-copy" "$r/.git/hooks"
write "$r" a.txt "a\n"
git -C "$r" add a.txt
with_timeout commit "$r"
check "hooks dir symlinked to the global hooks: commit passes" [ $? = 0 ]
new_repo
git -C "$r" config core.hooksPath "$T/hooks-copy"
rm -rf "$r/.git/hooks"
mkdir "$r/.git/hooks"
ln -s "$T/hooks-copy/pre-commit" "$r/.git/hooks/pre-commit"
write "$r" a.txt "a\n"
git -C "$r" add a.txt
with_timeout commit "$r"
check "pre-commit symlinked to the global one: commit passes" [ $? = 0 ]
new_repo
rm -rf "$r/.git/hooks"
cp -R "$HOOKS" "$r/.git/hooks"
write "$r" a.txt "a\n"
git -C "$r" add a.txt
with_timeout commit "$r"
check "copy of the global hooks in the repo: commit passes" [ $? = 0 ]

# Fail closed when the scan itself can't run.
mkdir -p "$T/not-a-repo"
(cd "$T/not-a-repo" && "$HOOKS/scan-secrets" > "$T/out" 2> "$T/err")
check "scan outside a repo: fails closed" [ $? != 0 ]
check "scan outside a repo: says why" grep -qF "could not be scanned" "$T/err"
mkdir -p "$T/fakebin"
printf '#!/bin/sh\necho "fatal: simulated failure" >&2\nexit 128\n' > "$T/fakebin/git"
chmod +x "$T/fakebin/git"
new_repo
(cd "$r" && PATH="$T/fakebin:$PATH" "$HOOKS/scan-secrets" > "$T/out" 2> "$T/err")
check "git diff failing: fails closed" [ $? != 0 ]
check "git diff failing: says why" grep -qF "could not be scanned" "$T/err"
mkdir -p "$T/fakebin2"
printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = --unified=0 ] && { echo "fatal: simulated" >&2; exit 128; }; done\nexec "%s" "$@"\n' "$(command -v git)" > "$T/fakebin2/git"
chmod +x "$T/fakebin2/git"
write "$r" a.txt "a\n"
git -C "$r" add a.txt
(cd "$r" && PATH="$T/fakebin2:$PATH" "$HOOKS/scan-secrets" > "$T/out" 2> "$T/err")
check "content diff failing: fails closed" [ $? != 0 ]
check "content diff failing: says why" grep -qF "could not read the staged diff" "$T/err"

# --- Installer ------------------------------------------------------------

install() { bash "$SCRIPTS/install-git-hooks.sh" > "$T/out" 2> "$T/err"; }
global_hooks_path() { git config --global --get-all core.hooksPath; }

unset XDG_CONFIG_HOME
install
check "installer: exits 0" [ $? = 0 ]
check "installer: silent on success" [ ! -s "$T/out" ]
check "installer: sets core.hooksPath with ~ when unset" [ "$(global_hooks_path)" = "~/.config/fabrik/git-hooks" ]
check "installer: copies the hooks" diff -rq "$HOOKS" "$HOME/.config/fabrik/git-hooks"
for f in "$HOOKS"/*; do
  check "installer: keeps executable bit on ${f##*/}" [ -x "$HOME/.config/fabrik/git-hooks/${f##*/}" ]
done
inode() { ls -i "$1" | awk '{ print $1 }'; }
before=$(inode "$HOME/.config/fabrik/git-hooks/pre-commit")
install
check "installer: idempotent, silent" [ ! -s "$T/out" ]
check "installer: idempotent, no rewrite" [ "$(inode "$HOME/.config/fabrik/git-hooks/pre-commit")" = "$before" ]
check "installer: idempotent, one value" [ "$(global_hooks_path)" = "~/.config/fabrik/git-hooks" ]

# The installed global hooks work in a repo with no local core.hooksPath.
git init -q "$T/global-repo"
write "$T/global-repo" key.txt "$GOOGLE\n"
git -C "$T/global-repo" add key.txt
commit "$T/global-repo"
check "installed global hook: blocks a key" [ $? != 0 ]
check "installed global hook: reports it" grep -qF "Google API key" "$T/err"

# Updates: changed content, lost executable bit. Other files are left alone
# and don't force a recopy.
touch "$HOME/.config/fabrik/git-hooks/other-tool-hook" "$HOME/.config/fabrik/git-hooks/.DS_Store"
before=$(inode "$HOME/.config/fabrik/git-hooks/pre-commit")
install
check "installer: extra files don't force a recopy" [ "$(inode "$HOME/.config/fabrik/git-hooks/pre-commit")" = "$before" ]
echo "# tampered" >> "$HOME/.config/fabrik/git-hooks/pre-commit"
chmod -x "$HOME/.config/fabrik/git-hooks/commit-msg"
install
check "installer: restores changed files" cmp -s "$HOOKS/pre-commit" "$HOME/.config/fabrik/git-hooks/pre-commit"
check "installer: restores executable bits" [ -x "$HOME/.config/fabrik/git-hooks/commit-msg" ]
check "installer: leaves other files alone" [ -f "$HOME/.config/fabrik/git-hooks/other-tool-hook" ]
check "installer: no temp files left" [ -z "$(ls -A "$HOME/.config/fabrik/git-hooks" | grep '\.tmp$')" ]

# XDG_CONFIG_HOME is respected; the path is absolute when not under HOME.
git config --global --unset core.hooksPath
export XDG_CONFIG_HOME="$T/xdg"
install
check "installer: respects XDG_CONFIG_HOME" [ "$(global_hooks_path)" = "$T/xdg/fabrik/git-hooks" ]
check "installer: copies to XDG_CONFIG_HOME" diff -rq "$HOOKS" "$T/xdg/fabrik/git-hooks"
git config --global core.hooksPath "$T/xdg/fabrik/git-hooks/"
install
check "installer: accepts its own path with a trailing slash" [ ! -s "$T/out" ]

# A foreign core.hooksPath is left alone, with a warning.
git config --global core.hooksPath /opt/other-hooks
install
check "installer, foreign path: exits 0" [ $? = 0 ]
check "installer, foreign path: unchanged" [ "$(global_hooks_path)" = "/opt/other-hooks" ]
check "installer, foreign path: warns" grep -qF "Secret scanning is not active" "$T/out"
check "installer, foreign path: names the path" grep -qF "/opt/other-hooks" "$T/out"
git config --global --unset core.hooksPath

# A foreign value in an [include]d file or the system config counts too.
printf '[core]\n\thooksPath = /opt/dotfiles-hooks\n' > "$T/included"
git config --global include.path "$T/included"
install
check "installer, included foreign path: warns" grep -qF "/opt/dotfiles-hooks" "$T/out"
check "installer, included foreign path: global file untouched" [ -z "$(global_hooks_path)" ]
git config --global --unset include.path
printf '[core]\n\thooksPath = /opt/system-hooks\n' > "$T/sysconfig"
(unset GIT_CONFIG_NOSYSTEM; GIT_CONFIG_SYSTEM="$T/sysconfig" install)
check "installer, system foreign path: warns" grep -qF "/opt/system-hooks" "$T/out"
check "installer, system foreign path: global not set" [ -z "$(global_hooks_path)" ]

# Concurrent first installs (several sessions starting at once) don't warn.
i=0
while [ $i -lt 8 ]; do
  XDG_CONFIG_HOME="$T/xdg-race" bash "$SCRIPTS/install-git-hooks.sh" > "$T/race$i" 2>&1 &
  i=$((i + 1))
done
wait
check "installer, concurrent: silent" [ -z "$(cat "$T"/race*)" ]
check "installer, concurrent: installed" diff -rq "$HOOKS" "$T/xdg-race/fabrik/git-hooks"
check "installer, concurrent: one value" [ "$(global_hooks_path)" = "$T/xdg-race/fabrik/git-hooks" ]
git config --global --unset core.hooksPath

# Can't install: XDG_CONFIG_HOME is a regular file.
touch "$T/xdg-file"
XDG_CONFIG_HOME="$T/xdg-file" install
check "installer, unwritable: exits 0" [ $? = 0 ]
check "installer, unwritable: warns" grep -qF "Secret scanning is not active" "$T/out"
check "installer, unwritable: core.hooksPath not set" [ -z "$(global_hooks_path)" ]

# No git: a PATH with basic tools only.
mkdir -p "$T/nogit"
for tool in bash cat jq awk uname hostname tr grep head dirname system_profiler; do
  p=$(command -v "$tool") && ln -s "$p" "$T/nogit/$tool"
done
PATH="$T/nogit" install
check "installer, no git: exits 0" [ $? = 0 ]
check "installer, no git: warns" grep -qF "git is not installed" "$T/out"

# --- session-start.sh -------------------------------------------------------

mkdir -p "$T/project"
session_start() { (cd "$T/project" && "$@" bash "$SCRIPTS/session-start.sh" < /dev/null > "$T/out" 2> "$T/err"); }
valid_json() { jq -e '.hookSpecificOutput.additionalContext | length > 0' "$T/out" > /dev/null; }
system_message() { jq -r .systemMessage "$T/out"; }

session_start env
check "session start: exits 0" [ $? = 0 ]
check "session start: valid JSON" valid_json
check "session start: plain welcome" [ "$(system_message)" = "Welcome to fabrik." ]
check "session start: installs hooks" [ "$(global_hooks_path)" = "$T/xdg/fabrik/git-hooks" ]

git config --global core.hooksPath /opt/other-hooks
session_start env
check "session start, foreign path: valid JSON" valid_json
check "session start, foreign path: warns the user" grep -qF "Secret scanning is not active" <(system_message)
check "session start, foreign path: warns the agent" grep -qF "Secret scanning is not active" <(jq -r .hookSpecificOutput.additionalContext "$T/out")
git config --global --unset core.hooksPath

session_start env PATH="$T/nogit"
check "session start, no git: exits 0" [ $? = 0 ]
check "session start, no git: valid JSON" valid_json
check "session start, no git: warns" grep -qF "git is not installed" <(system_message)

session_start env XDG_CONFIG_HOME="$T/xdg-file"
check "session start, unwritable: valid JSON" valid_json
check "session start, unwritable: warns" grep -qF "Secret scanning is not active" <(system_message)

check "tests left the source hooks directory untouched" [ "$(ls -l "$HOOKS")" = "$HOOKS_BEFORE" ]

echo "$PASSED passed, $FAILED failed"
[ $FAILED = 0 ]
