# herdr-worktreeinclude

[![npm version](https://img.shields.io/npm/v/herdr-worktreeinclude?logo=npm)](https://www.npmjs.com/package/herdr-worktreeinclude)
[![npm downloads](https://img.shields.io/npm/dm/herdr-worktreeinclude?logo=npm)](https://www.npmjs.com/package/herdr-worktreeinclude)
[![CI](https://github.com/serhii-chernenko/herdr-worktreeinclude/actions/workflows/ci.yml/badge.svg)](https://github.com/serhii-chernenko/herdr-worktreeinclude/actions/workflows/ci.yml)
[![GitHub stars](https://img.shields.io/github/stars/serhii-chernenko/herdr-worktreeinclude?style=flat)](https://github.com/serhii-chernenko/herdr-worktreeinclude/stargazers)
[![Herdr Marketplace](https://img.shields.io/badge/Herdr-Marketplace-4f46e5)](https://herdr.dev/docs/marketplace/)

A [Herdr](https://herdr.dev) plugin that keeps Herdr-created Git worktrees inside the project and restores selected ignored files into them.

## What it does

Use Herdr's normal **New worktree** UI. After creation, the plugin automatically:

- moves the checkout from Herdr's global directory to `<project>/.herdr/worktrees/<branch>`;
- copies files selected by `.worktreeinclude` from the primary checkout;
- opens the relocated worktree as the active Herdr workspace.

When you remove a plugin-managed worktree through Herdr's normal UI, an unchanged branch (one already contained in the primary checkout's `HEAD`) is removed silently. For a branch with unique commits, Herdr shows an in-terminal overlay: press `d` to safely delete the local branch or Enter to keep it.

The plugin cannot change Herdr's built-in creation/removal dialogs. It uses lifecycle hooks immediately after those dialogs complete.

## Requirements

- Herdr with plugin support (currently the Preview channel)
- Git
- Node.js 20 or later
- macOS or Linux

## Install

Once the repository is public and tagged with the GitHub topic `herdr-plugin`:

```bash
herdr plugin install serhii-chernenko/herdr-worktreeinclude
```

To install a specific release:

```bash
herdr plugin install serhii-chernenko/herdr-worktreeinclude --ref v0.1.0
```

For local development, link it into the current Herdr session:

```bash
herdr plugin link /path/to/herdr-worktreeinclude
```

Plugins are registered per Herdr session. For a named session, include its name:

```bash
herdr --session my-session plugin link /path/to/herdr-worktreeinclude
```

## Configure copied files

Create `.worktreeinclude` at the project root. It uses `.gitignore` pattern syntax, but a file is copied only when it is both selected by `.worktreeinclude` and ignored by Git.

```gitignore
# .gitignore
.env
config/local/
```

```gitignore
# .worktreeinclude
.env
config/local/
```

Tracked files are never copied. Existing destination files are not overwritten. Symlinks and file modes are preserved.

## Development

```bash
npm install
npm run check
```

After changing the manifest or scripts, relink the plugin in the target Herdr session:

```bash
herdr plugin unlink serhii-chernenko.worktreeinclude
herdr plugin link "$(pwd)"
```

## Releases

The npm package and Herdr manifest share one version. Before publishing, update both `package.json` and `herdr-plugin.toml`, add release notes to `CHANGELOG.md`, then commit and push a matching tag:

```bash
git tag v0.1.1
git push origin main v0.1.1
```

The tag workflow verifies the version, publishes to npm through npm Trusted Publishing, and creates GitHub Release notes automatically. After claiming the package name with an initial manual publish, configure npm's Trusted Publisher for GitHub repository `serhii-chernenko/herdr-worktreeinclude` and workflow filename `publish.yml`. Subsequent matching version tags publish without a stored npm token.
