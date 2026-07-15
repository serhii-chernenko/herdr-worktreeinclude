#!/usr/bin/env bash
# Copy source files which are both Git-ignored and selected by .worktreeinclude.
set -euo pipefail

usage() {
  echo "usage: $0 SOURCE_WORKTREE DESTINATION_WORKTREE" >&2
  exit 64
}

[[ $# -eq 2 ]] || usage
source_root=$(git -C "$1" rev-parse --show-toplevel)
destination_root=$(git -C "$2" rev-parse --show-toplevel)
include_file="$source_root/.worktreeinclude"

if [[ ! -f "$include_file" ]]; then
  echo "No .worktreeinclude in $source_root; nothing to copy."
  exit 0
fi

# A project-local worktree is physically nested below the primary checkout.
# Do not treat another checkout's ignored files as source files to copy.
linked_worktrees=$(git -C "$source_root" worktree list --porcelain | awk '/^worktree / { print substr($0, 10) }')

is_other_worktree_path() {
  local candidate=$1 worktree
  while IFS= read -r worktree; do
    [[ -n "$worktree" && "$worktree" != "$source_root" ]] || continue
    case "$candidate" in
      "$worktree"|"$worktree"/*) return 0 ;;
    esac
  done <<<"$linked_worktrees"
  return 1
}

matches=$(mktemp "${TMPDIR:-/tmp}/herdr-worktreeinclude.XXXXXX")
pattern_root=$(mktemp -d "${TMPDIR:-/tmp}/herdr-worktreeinclude-patterns.XXXXXX")
trap 'rm -f "$matches"; rm -rf "$pattern_root"' EXIT

# Evaluate selection patterns in an otherwise empty Git repository. Evaluating
# them inside the source repository would also apply its .gitignore, whose
# higher precedence could defeat a .worktreeinclude negation (for example
# `config/` followed by `!config/example.json`).
git -C "$pattern_root" init -q
cp "$include_file" "$pattern_root/.gitignore"

# git ls-files supplies only ignored, untracked paths. check-ignore then applies
# .worktreeinclude with Git's own .gitignore-compatible pattern engine.
git -C "$source_root" ls-files --others --ignored --exclude-standard -z \
  | git -C "$pattern_root" check-ignore --no-index --stdin -z >"$matches" || true

copied=0
skipped=0
while IFS= read -r -d '' relative_path; do
  # Reject paths which could escape either worktree. Git normally cannot emit
  # these, but the guard makes copying safe even with unusual filenames.
  [[ "$relative_path" != /* && "$relative_path" != ../* && "$relative_path" != */../* ]] || continue

  source_path="$source_root/$relative_path"
  destination_path="$destination_root/$relative_path"
  [[ -e "$source_path" || -L "$source_path" ]] || continue
  is_other_worktree_path "$source_path" && continue

  # Never overwrite a file Git checked out in the destination.
  if git -C "$destination_root" ls-files --error-unmatch -- "$relative_path" >/dev/null 2>&1; then
    echo "Skipping tracked destination path: $relative_path" >&2
    ((skipped += 1))
    continue
  fi
  if [[ -e "$destination_path" || -L "$destination_path" ]]; then
    echo "Skipping existing destination path: $relative_path" >&2
    ((skipped += 1))
    continue
  fi

  mkdir -p "$(dirname "$destination_path")"
  # -P preserves symlinks, -R copies recursively if Git reports a directory,
  # and -p retains the source mode and timestamps.
  cp -pPR "$source_path" "$destination_path"
  ((copied += 1))
done <"$matches"

echo "Copied $copied .worktreeinclude file(s); skipped $skipped."
