# Changelog

All notable changes are published in the [GitHub Releases](https://github.com/serhii-chernenko/herdr-worktreeinclude/releases) generated from version tags.

## 0.2.2

**Fixed: the branch-cleanup popup could silently fail to appear or fail to delete the branch.**

After merging a pull request and removing its worktree, the popup that asks whether to delete the local branch sometimes never showed up, and the branch was left behind with no error or warning. Two separate causes were at fault:

- When the branch's commits were already merged into the main checkout, the plugin deleted it automatically without asking — but it used `git branch -d`, which refuses to delete a branch whose remote tracking ref has moved (for example, an extra commit pushed to the pull request branch after merging). That refusal was silently swallowed. The plugin now uses `git branch -D` for this case, which is safe here because the merge has already been proven.
- When the branch still had commits not yet in the main checkout, Herdr could momentarily reject opening the popup (`ui_busy`) right after the worktree's workspace closed. The plugin now retries a few times before giving up, and if it still can't open the popup, it logs a clear message with a ready-to-run command to delete the branch by hand (visible via `herdr plugin log list`).

**Fixed: creating a worktree for a project with many ignored files (build caches, `node_modules`, etc.) could take several seconds to settle into the right directory.**

Copying files listed in `.worktreeinclude` used to check and copy each matched file one at a time, spawning a separate process for every single file. For a project with hundreds of such files, this added up to many seconds of visible delay before the terminal pane landed in the correct, relocated worktree directory. The copy step has been rewritten to do this work in bulk instead of file-by-file — in testing, an 800-file case dropped from about 11 seconds to about 1 second, with no change in what gets copied or how symlinks and permissions are preserved.

## 0.2.1

- Fixed the branch-cleanup popup's `[d] Delete branch` action never actually deleting the branch: it ran `git branch -d`, which refuses any branch that isn't fully merged — exactly the branches this popup exists for. It now uses `git branch -D` to honor the user's explicit confirmation.

## 0.2.0

- The branch-cleanup confirmation now opens as a small Herdr popup pane instead of a full overlay, using the `placement = "popup"` pane type added in Herdr 0.7.4. Raised `min_herdr_version` to `0.7.4` accordingly.

## 0.1.0

- Initial Herdr plugin: project-local worktrees, `.worktreeinclude` copying, and UI-first branch cleanup.
