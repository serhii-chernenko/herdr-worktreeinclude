# Changelog

All notable changes are published in the [GitHub Releases](https://github.com/serhii-chernenko/herdr-worktreeinclude/releases) generated from version tags.

## 0.2.1

- Fixed the branch-cleanup popup's `[d] Delete branch` action never actually deleting the branch: it ran `git branch -d`, which refuses any branch that isn't fully merged — exactly the branches this popup exists for. It now uses `git branch -D` to honor the user's explicit confirmation.

## 0.2.0

- The branch-cleanup confirmation now opens as a small Herdr popup pane instead of a full overlay, using the `placement = "popup"` pane type added in Herdr 0.7.4. Raised `min_herdr_version` to `0.7.4` accordingly.

## 0.1.0

- Initial Herdr plugin: project-local worktrees, `.worktreeinclude` copying, and UI-first branch cleanup.
