#!/usr/bin/env bash
# Make Herdr's native worktree dialog project-local, then restore selected
# ignored files. Herdr v1 emits this hook after it has created the checkout,
# so relocation necessarily happens immediately after the dialog completes.
set -euo pipefail

plugin_root=${HERDR_PLUGIN_ROOT:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}
target=$(node "$plugin_root/scripts/event-worktree-path.mjs")
[[ -n "$target" ]] || { echo "Could not find worktree path in Herdr event payload." >&2; exit 0; }

# The primary worktree provides the shared repository's local ignored files.
source=$(git -C "$target" worktree list --porcelain | awk '/^worktree / { print substr($0, 10); exit }')
[[ -n "$source" ]] || exit 0
branch=$(git -C "$target" branch --show-current)
[[ -n "$branch" ]] || { echo "Skipping detached worktree: $target" >&2; exit 0; }
slug=$(printf '%s' "$branch" | tr '[:space:]/' '--' | tr -cd '[:alnum:]._-')
[[ -n "$slug" ]] || { echo "Could not make a safe path from branch: $branch" >&2; exit 1; }
destination="$source/.herdr/worktrees/$slug"

# A plugin-created project-local worktree already has the right path.
if [[ "$target" != "$destination" ]]; then
  if [[ -e "$destination" ]]; then
    echo "Project-local worktree path already exists; leaving Herdr worktree at $target" >&2
    exit 1
  fi

  herdr_bin=${HERDR_BIN_PATH:-herdr}
  # Capture the workspace while Herdr still recognizes the original path.
  workspace_id=$("$herdr_bin" worktree list --cwd "$source" --json \
    | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const r=JSON.parse(s).result;const w=(r.worktrees||[]).find(x=>x.path===process.argv[1]);if(w?.open_workspace_id)process.stdout.write(w.open_workspace_id)})' "$target")
  "$plugin_root/scripts/copy-worktreeinclude.sh" "$source" "$target"
  mkdir -p "$(dirname "$destination")"
  git -C "$source" worktree move "$target" "$destination"

  # Herdr's workspace is still attached to the old path. Close it, then open
  # the relocated checkout as the replacement workspace.
  [[ -z "$workspace_id" ]] || "$herdr_bin" workspace close "$workspace_id"
  "$herdr_bin" worktree open --cwd "$source" --path "$destination" --focus
  echo "Relocated worktree to $destination"
else
  "$plugin_root/scripts/copy-worktreeinclude.sh" "$source" "$target"
fi

# Store the final checkout path. The removal event occurs after Git has
# deleted that checkout, so this is how the cleanup pane knows its branch and
# source repository.
managed_path=${destination:-$target}
state_dir=${HERDR_PLUGIN_STATE_DIR:-"$plugin_root/.state"}
state_file="$state_dir/managed-worktrees.tsv"
mkdir -p "$state_dir"
state_tmp=$(mktemp "$state_dir/managed-worktrees.XXXXXX")
if [[ -f "$state_file" ]]; then
  awk -F '\t' -v path="$managed_path" '$1 != path' "$state_file" >"$state_tmp"
fi
printf '%s\t%s\t%s\n' "$managed_path" "$source" "$branch" >>"$state_tmp"
mv "$state_tmp" "$state_file"
