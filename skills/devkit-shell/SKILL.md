---
name: devkit-shell
description: Check a repository's shell scripts with ShellCheck and shfmt, using devkit's `shell` module. Use this when setting up the shell checks.
---

# shell

The `shell` module checks the repository's shell scripts: `.envrc` and every `*.sh` file that Git tracks.
Its `shellcheck` check runs [ShellCheck](https://www.shellcheck.net) on them.
Its `shfmt` check runs [shfmt](https://github.com/mvdan/sh) on them.

## Set it up

1. Import `inputs.devkit.flakeModules.shell`, as the `devkit` skill shows.
2. Run `nix run .#check-shellcheck` and `nix run .#check-shfmt`.

## The rules

shfmt indents with `indentSize` spaces, from devkit's library.
