---
name: devkit-github-actions
description: Check a repository's GitHub Actions workflows with actionlint, using devkit's `github-actions` module. Use this when setting up the workflow check, or when it fails.
---

# github-actions

The `github-actions` module checks the workflows in `.github/workflows` with [actionlint](https://github.com/rhysd/actionlint).
Its `actionlint` check also runs ShellCheck on the script of each `run` step, and pyflakes on its Python.

## Set it up

1. Import `inputs.devkit.flakeModules.github-actions`, as the `devkit` skill shows.
2. Run `nix run .#check-actionlint`.

The check fails in a repository without a `.github/workflows` directory, so only a repository with workflows imports the module.

## When it fails

actionlint names the file, the line and the rule of each problem.
A problem in the script of a `run` step names the ShellCheck rule, such as `SC2086`.
