---
name: devkit
description: Add devkit to the flake of a sic-lang repository, and find the module that provides a given check, setup or generated file. Use this when a repository should take something from devkit.
---

# Set devkit up in a repository

devkit is a flake whose [flake-parts](https://flake.parts) modules give a repository checks, setups and generated files.

## Take devkit as an input

The repository adds devkit and the `nixpkgs` that provides its tools to its flake's inputs, then imports the modules it needs from `flakeModules`, here the `reuse` module:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    devkit = {
      url = "github:sic-lang/devkit";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devkit.flakeModules.reuse ];
      systems = [ "x86_64-linux" ];
    };
}
```

All the modules' options live in `perSystem`, under `devkit`.
`nix run .#check` runs every check that the modules provide, and `nix run .#setup` every setup, asking before each one.

## Choose the modules

Each module has its own skill, which describes what it provides and how to set it up.
These modules are ready to use:

- `reuse` (`devkit-reuse` skill): checks the licenses of the files with REUSE, and writes their texts from the SPDX list.
- `yamllint` (`devkit-yamllint` skill): checks the YAML files.

These modules let a repository define its own:

- `checks` (`devkit-checks` skill): checks.
- `commands` (`devkit-commands` skill): commands, written as Bash templates.
- `files` (`devkit-files` skill): generated files, built from shared values such as the maximum line length.
- `setups` (`devkit-setups` skill): setups that write recommended files into the repository.
