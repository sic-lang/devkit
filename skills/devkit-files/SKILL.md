---
name: devkit-files
description: Generate a repository-specific file, such as a tool's configuration, from the repository's flake with devkit's `files` module. Use this when a repository needs a generated file that no devkit module provides.
---

# Generated files

The `files` module writes generated files into the repository.
The repository commits them, so that editors, GitHub and fresh clones all see the same files as the checks.

- `nix run .#setup-files` writes them.
  It keeps any existing file that differs from the generated one, unless given `--force`.
- `nix run .#check-files` fails if a file is missing or differs from the generated one, and shows the difference.
  To change a generated file, change the options that generate it, then run `nix run .#setup-files -- --force`.

## Generate a file

A generated file is any file in the Nix store, declared under its path in the repository:

```nix
devkit.files."example.toml" = ./example.toml;
```
