---
name: adopt
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

Each module has its own skill, `devkit:<module>`, which describes what it provides and how to set it up.
A check of a kind of files reads only the regular files that Git tracks, and fails with `No file to check` when Git tracks none of them.
Set the modules' options in `perSystem`, under `devkit`, where `pkgs` gives the packages that their values need.

## Run the checks on GitHub

devkit's [`flake-checks.yml`](https://github.com/sic-lang/devkit/blob/main/.github/workflows/flake-checks.yml) is a [reusable workflow](https://docs.github.com/en/actions/sharing-automations/reusing-workflows).
It runs every `check-*` app and builds every `test-*` check of the repository's flake, one job each.
Its job `checks` passes only when all of them pass.

The `github-actions` module generates the repository's workflow that calls it from the job `flake`, as the `devkit:github-actions` skill shows.
A [ruleset](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets) therefore requires only the check `flake / checks`.
