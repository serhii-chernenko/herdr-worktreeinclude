#!/usr/bin/env bash
set -euo pipefail

repo=$(mktemp -d "${TMPDIR:-/tmp}/herdr-create-worktree-test.XXXXXX")
cleanup() {
  local status=$?
  git -C "$repo" worktree remove --force "$repo/.herdr/worktrees/feature-one" >/dev/null 2>&1 || true
  rm -rf "$repo"
  exit "$status"
}
trap cleanup EXIT

git -C "$repo" init -q -b main
git -C "$repo" config user.email test@example.com
git -C "$repo" config user.name Test
printf '.env\n' >"$repo/.worktreeinclude"
printf '.env\n' >"$repo/.gitignore"
printf 'tracked\n' >"$repo/tracked.txt"
git -C "$repo" add .gitignore .worktreeinclude tracked.txt
git -C "$repo" commit -qm initial
printf 'secret\n' >"$repo/.env"

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
(
  cd "$repo"
  printf 'feature/one\n\n' | HERDR_PLUGIN_ROOT="$plugin_root" HERDR_BIN_PATH=/usr/bin/true \
    "$plugin_root/scripts/create-worktree.sh"
)

worktree="$repo/.herdr/worktrees/feature-one"
test "$(git -C "$worktree" branch --show-current)" = feature/one
test "$(cat "$worktree/.env")" = secret
echo "create-worktree test passed"
