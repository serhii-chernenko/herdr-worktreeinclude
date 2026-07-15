#!/usr/bin/env bash
set -euo pipefail

repo=$(mktemp -d "${TMPDIR:-/tmp}/herdr-worktreeinclude-test.XXXXXX")
cleanup() {
  local status=$?
  git -C "$repo" worktree remove --force "$repo/destination" >/dev/null 2>&1 || true
  rm -rf "$repo"
  exit "$status"
}
trap cleanup EXIT
git -C "$repo" init -q -b main
git -C "$repo" config user.email test@example.com
git -C "$repo" config user.name Test
printf 'tracked\n' >"$repo/tracked.txt"
printf '.env\nconfig/*\n!config/excluded.txt\n' >"$repo/.worktreeinclude"
printf '.env\nconfig/*\n' >"$repo/.gitignore"
git -C "$repo" add .gitignore .worktreeinclude tracked.txt
git -C "$repo" commit -qm initial
printf 'secret\n' >"$repo/.env"
mkdir -p "$repo/config"
printf 'nested secret\n' >"$repo/config/secret.txt"
printf 'do not copy\n' >"$repo/config/excluded.txt"
git -C "$repo" worktree add -q -b test-copy "$repo/destination"

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
"$plugin_root/scripts/copy-worktreeinclude.sh" "$repo" "$repo/destination"

test "$(cat "$repo/destination/.env")" = secret
test "$(cat "$repo/destination/config/secret.txt")" = 'nested secret'
test ! -e "$repo/destination/config/excluded.txt"
test ! -e "$repo/destination/destination"
test ! -e "$repo/destination/tracked.txt~"
echo "copy-worktreeinclude test passed"
