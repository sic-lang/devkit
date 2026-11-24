---
name: devkit-nixfmt
description: Check the formatting of a repository's Nix files with nixfmt, using devkit's `nixfmt` module. Use this when setting up the Nix formatting check, or when it fails.
---

# nixfmt

The `nixfmt` module checks that every Nix file that git tracks is formatted by [nixfmt](https://github.com/NixOS/nixfmt).
A file that git does not track is not checked.

## Set it up

1. Import `inputs.devkit.flakeModules.nixfmt`, as the `devkit` skill shows.
2. Run `nix run .#check-nixfmt`.

## When it fails

The check names each file that is not formatted.
Run `nixfmt` on these files, from the development shell, to format them.
