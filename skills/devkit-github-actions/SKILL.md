---
name: devkit-github-actions
description: Check a repository's GitHub Actions workflows with actionlint, using devkit's `github-actions` module. Use this when setting up the workflow check.
---

# github-actions

The `github-actions` module checks the workflows, every regular `*.yaml` and `*.yml` file under `.github/workflows` that Git tracks, with [actionlint](https://github.com/rhysd/actionlint).

## Set it up

1. Import `inputs.devkit.flakeModules.github-actions`, as the `devkit` skill shows.
2. Run `nix run .#check-actionlint`.

Only a repository with workflows imports the module.
