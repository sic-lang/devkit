---
name: devkit
description: Set devkit up in a repository of sic-lang, or add one of its modules to a repository that uses it. Use when a repository should take its checks, setups or generated files from devkit.
---

# Set devkit up in a repository

devkit is a flake whose flake-parts modules give a repository its checks, its setups and its generated files.

## Take devkit as an input

The repository adds devkit and the `nixpkgs` of its tools to the inputs of its flake, and imports the modules it needs from `flakeModules` with [flake-parts](https://flake.parts):

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

A module imports the modules it builds on, so the repository imports only those it uses directly.
Each module is configured by its options in `perSystem`, all under `devkit`, such as `devkit.lineLength`, whose descriptions are in the module.

## Choose the modules

These modules exist, each with its own skill:

- `checks` (skill `devkit-checks`): the checks, run by `nix run .#check` and `nix run .#check-<name>`.
- `commands` (skill `devkit-commands`): the frame of every command, app and flake check, and the development shell.
- `files` (skill `devkit-files`): the files that devkit generates and that the repository commits.
- `reuse` (skill `devkit-reuse`): the licenses, checked with REUSE and written from the SPDX list.
- `setups` (skill `devkit-setups`): the setups, run by `nix run .#setup` and `nix run .#setup-<name>`.
- `yamllint` (skill `devkit-yamllint`): the check of the YAML files and its generated configuration.

## Check the result

After a change, run `nix run .#setup` to write what the setups write, then `nix flake check` and `nix run .#check`, which must pass.
