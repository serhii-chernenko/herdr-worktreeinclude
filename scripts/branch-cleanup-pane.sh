#!/usr/bin/env bash
# Herdr popup pane shown after a worktree checkout has been removed.
# Popups have no pane id and close automatically when this script exits.
set -euo pipefail

source_root=${HERDR_WORKTREEINCLUDE_SOURCE:?Missing source repository}
branch=${HERDR_WORKTREEINCLUDE_BRANCH:?Missing branch name}

clear
printf '\n  Worktree checkout removed\n\n'
printf '  Delete the local branch "%s" too?\n\n' "$branch"
printf '  [d] Delete branch    [Enter] Keep branch\n\n'
read -r -n 1 choice || true
printf '\n'

if [[ "$choice" == "d" || "$choice" == "D" ]]; then
  git -C "$source_root" branch -d -- "$branch" >&2 || true
fi
