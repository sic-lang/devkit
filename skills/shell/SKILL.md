---
name: shell
description: Check a repository's shell scripts with ShellCheck and shfmt, using devkit's `shell` module. Use this when setting up the shell checks.
---

# shell

The `shell` module checks the repository's shell scripts: every regular `.envrc` or `*.sh` file that Git tracks.
Its `shellcheck` check runs [ShellCheck](https://www.shellcheck.net) on them.
Its `shfmt` check runs [shfmt](https://github.com/mvdan/sh) on them, and shows how shfmt would format each file that it would change.

## Set it up

1. Import `inputs.devkit.flakeModules.shell`, as the `devkit:adopt` skill shows.
2. Run `nix run .#check-shellcheck` and `nix run .#check-shfmt`.

Only a repository with shell scripts imports the module.

## The rules

shfmt indents with `indentSize` spaces, from devkit's library.
