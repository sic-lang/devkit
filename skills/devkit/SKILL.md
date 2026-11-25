---
name: devkit
description: Add devkit to a sic-lang repository's flake. Use this when a repository needs something from devkit.
---

# devkit

devkit is a flake whose [flake-parts](https://flake.parts) modules give a repository checks, setups and generated files.
Its library, `lib`, holds the values that devkit shares between repositories.

## Take devkit as an input

Add devkit to the repository's flake inputs, together with the `nixpkgs` that devkit takes its packages from.
Then import the modules you need from `flakeModules`.
This example imports the `licenses` module:

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
      imports = [ inputs.devkit.flakeModules.licenses ];
      systems = [ "x86_64-linux" ];
    };
}
```

Each module has its own skill, `devkit-<module>`, which describes what it provides and how to set it up.
Set the modules' options in `perSystem`, under `devkit`, where `pkgs` gives the packages that their values need.
