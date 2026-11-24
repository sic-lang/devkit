---
name: devkit-shell
description: Check a repository's shell scripts with ShellCheck and shfmt, using devkit's `shell` module. Use this when setting up the shell checks, or when one of them fails.
---

# shell

The `shell` module checks the repository's shell scripts: `.envrc` and every `*.sh` file that Git tracks.
Its `shellcheck` check runs [ShellCheck](https://www.shellcheck.net) on them.
Its `shfmt` check runs [shfmt](https://github.com/mvdan/sh) on them, and shows how shfmt would format each file that it would change.

## Set it up

1. Import `inputs.devkit.flakeModules.shell`, as the `devkit` skill shows.
2. Run `nix run .#check-shellcheck` and `nix run .#check-shfmt`.

Both checks fail in a repository without such a script, so only a repository with shell scripts imports the module.

## The rules

ShellCheck needs to know each script's shell.
A script that has no shebang, such as `.envrc`, names it in a directive on its first line:

```bash
# shellcheck shell=bash
```

shfmt indents with `indentSize` spaces, from devkit's library, and reads no `.editorconfig`.
