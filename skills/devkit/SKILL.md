---
name: devkit
description: Take devkit as an input of the flake of a repository of sic-lang, and find the module that gives the repository a check, a setup or a generated file. Use when a repository should take something from devkit.
---

# Set devkit up in a repository

devkit is a flake whose modules, for [flake-parts](https://flake.parts), give a repository checks, setups and generated files.

## Take devkit as an input

The repository adds devkit and the `nixpkgs` of its tools to the inputs of its flake, and imports the modules it needs from `flakeModules`, here the module `reuse`:

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

Every option of the modules is in `perSystem`, under `devkit`.
`nix run .#check` runs every check that the modules give, and `nix run .#setup` every setup, after asking for each one.

## Choose the modules

Each module has its own skill, which says what it gives and how to set it up:

- `reuse` (skill `devkit-reuse`): the licenses of the files, checked with REUSE and written from the SPDX list.
- `yamllint` (skill `devkit-yamllint`): the check of the YAML files.

These modules let the repository write its own:

- `checks` (skill `devkit-checks`): a check of the repository.
- `commands` (skill `devkit-commands`): a command of the repository, as a Bash template.
- `files` (skill `devkit-files`): a file that the repository generates from shared values, such as the length of the lines.
- `setups` (skill `devkit-setups`): a setup that writes recommended files into the repository.
