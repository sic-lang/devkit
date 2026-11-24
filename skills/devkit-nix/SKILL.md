---
name: devkit-nix
description: Check and format a repository's Nix files with nixfmt, using devkit's `nix` module. Use this when setting up the Nix formatting check, when it fails, or when formatting Nix files.
---

# nix

The `nix` module checks that every Nix file that git tracks is formatted by [nixfmt](https://github.com/NixOS/nixfmt).
A file that git does not track is not checked.
It also provides the flake's formatter, which `nix fmt` runs.

## Set it up

1. Import `inputs.devkit.flakeModules.nix`, as the `devkit` skill shows.
2. Run `nix run .#check-nixfmt`.

## Format the files

`nix fmt` formats every Nix file that git tracks, from any directory of the repository.
`nix fmt -- <path>...` formats only those under the given paths.
Each path must name a file or a directory that git tracks.

## When it fails

The check names each file that is not formatted.
Run `nix fmt` to format them.
