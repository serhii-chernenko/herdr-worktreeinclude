#!/usr/bin/env bash
# Interactive Herdr pane entrypoint. The pane starts in the source workspace.
set -euo pipefail

plugin_root=${HERDR_PLUGIN_ROOT:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}
source_root=$(git rev-parse --show-toplevel)

read -r -p "Branch name: " branch
[[ -n "$branch" ]] || { echo "A branch name is required." >&2; exit 64; }
read -r -p "Base ref [HEAD]: " base
base=${base:-HEAD}

# Keep branches separate without allowing a branch name to traverse directories.
slug=$(printf '%s' "$branch" | tr '/[:space:]' '--' | tr -cd '[:alnum:]._-')
[[ -n "$slug" ]] || { echo "Branch name contains no usable path characters." >&2; exit 64; }
worktree_path="$source_root/.herdr/worktrees/$slug"

if [[ -e "$worktree_path" ]]; then
  echo "Destination already exists: $worktree_path" >&2
  exit 1
fi

mkdir -p "$(dirname "$worktree_path")"
if git show-ref --verify --quiet "refs/heads/$branch"; then
  git worktree add "$worktree_path" "$branch"
else
  git worktree add -b "$branch" "$worktree_path" "$base"
fi

"$plugin_root/scripts/copy-worktreeinclude.sh" "$source_root" "$worktree_path"

herdr_bin=${HERDR_BIN_PATH:-herdr}
"$herdr_bin" worktree open --cwd "$source_root" --path "$worktree_path" --focus
echo "Opened $worktree_path in Herdr."
