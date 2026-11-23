---
name: devkit-files
description: Generate a repository-specific file, such as a tool's configuration, from the repository's flake with devkit's `files` module. Use this when a repository needs a generated file that no devkit module provides.
---

# files

The `files` module writes generated files into the repository.
The repository commits them, so that editors, GitHub and fresh clones all see the same files as the checks.

- `nix run .#setup-files` writes them.
  It keeps any existing file that differs from the generated one, unless given `--force`.
- `nix run .#check-files` fails if a file is missing or differs from the generated one, and shows the difference.
  To change a generated file, change the options that generate it, then run `nix run .#setup-files -- --force`.
- Neither touches a file that is no longer generated: delete it by hand.

## Generate a file

`devkit.files.<path>` takes a file from the flake or the Nix store, and generates `<path>` from it:

```nix
devkit.files."example.toml" = ./example.toml;
```
