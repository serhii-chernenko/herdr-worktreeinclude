#!/usr/bin/env bash
# Open an in-Herdr branch-cleanup popup after a plugin-managed checkout is
# removed. This hook deliberately does not use macOS dialogs.
set -euo pipefail

plugin_root=${HERDR_PLUGIN_ROOT:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}
target=$(node "$plugin_root/scripts/event-worktree-path.mjs")
[[ -n "$target" ]] || exit 0

state_dir=${HERDR_PLUGIN_STATE_DIR:-"$plugin_root/.state"}
state_file="$state_dir/managed-worktrees.tsv"
[[ -f "$state_file" ]] || exit 0
record=$(awk -F '\t' -v path="$target" '$1 == path { print; exit }' "$state_file")
[[ -n "$record" ]] || exit 0
IFS=$'\t' read -r _ source branch <<<"$record"

state_tmp=$(mktemp "$state_dir/managed-worktrees.XXXXXX")
awk -F '\t' -v path="$target" '$1 != path' "$state_file" >"$state_tmp"
mv "$state_tmp" "$state_file"

herdr_bin=${HERDR_BIN_PATH:-herdr}

# If the branch tip is already contained in the source checkout's HEAD, no
# work remains unique to the worktree. Delete it without interrupting the UI.
if git -C "$source" merge-base --is-ancestor "$branch" HEAD; then
  git -C "$source" branch -d -- "$branch" >&2 || true
  exit 0
fi

"$herdr_bin" plugin pane open \
  --plugin "${HERDR_PLUGIN_ID:-serhii-chernenko.worktreeinclude}" \
  --entrypoint branch-cleanup \
  --placement popup \
  --env "HERDR_WORKTREEINCLUDE_SOURCE=$source" \
  --env "HERDR_WORKTREEINCLUDE_BRANCH=$branch"
