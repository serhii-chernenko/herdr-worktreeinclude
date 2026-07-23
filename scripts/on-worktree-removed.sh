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
log() { printf '[worktreeinclude:on-worktree-removed] %s\n' "$*" >&2; }

open_cleanup_popup() {
  local attempt output
  for attempt in 1 2 3 4 5; do
    if output=$("$herdr_bin" plugin pane open \
        --plugin "${HERDR_PLUGIN_ID:-serhii-chernenko.worktreeinclude}" \
        --entrypoint branch-cleanup \
        --placement popup \
        --env "HERDR_WORKTREEINCLUDE_SOURCE=$source" \
        --env "HERDR_WORKTREEINCLUDE_BRANCH=$branch" 2>&1); then
      log "cleanup popup opened for branch '$branch' (attempt $attempt)"
      return 0
    fi
    log "cleanup popup attempt $attempt failed: $output"
    case "$output" in
      *ui_busy*) sleep 0.4 ;;
      *) break ;;
    esac
  done
  log "could not open cleanup popup for branch '$branch'; delete it manually with: git -C '$source' branch -d '$branch'"
  return 1
}

# If the branch tip is already contained in the source checkout's HEAD, its
# work is preserved regardless of the local branch ref, so force-deletion loses
# nothing. Use -D (not -d): -d refuses when the branch's configured @{upstream}
# has diverged even though it is merged into HEAD, and that refusal was being
# swallowed silently.
if git -C "$source" merge-base --is-ancestor "$branch" HEAD; then
  log "branch '$branch' is contained in HEAD of $source; deleting without prompt"
  if git -C "$source" branch -D -- "$branch" >&2; then
    log "deleted merged branch '$branch'"
    exit 0
  fi
  log "could not delete already-merged branch '$branch' (may still be referenced by a worktree); falling back to cleanup popup"
fi

open_cleanup_popup || true
