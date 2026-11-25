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

## Run the checks on GitHub

devkit's [`flake-checks.yml`](https://github.com/sic-lang/devkit/blob/main/.github/workflows/flake-checks.yml) is a [reusable workflow](https://docs.github.com/en/actions/sharing-automations/reusing-workflows).
It runs every `check-*` app and builds every `test-*` check of the repository's flake, one job each.
[The job `checks`](https://github.com/sic-lang/devkit/blob/main/.github/workflows/flake-checks.yml#L69) passes only when all of them pass, so the repository's ruleset requires only this job.
The workflow sets its own permissions, so the calling workflow does not set any.

The repository calls it from a workflow of its own, which sets the events as [devkit's `checks.yml`](https://github.com/sic-lang/devkit/blob/main/.github/workflows/checks.yml) does.
Its jobs call the workflow with a single job:

```yaml
jobs:
  flake:
    uses: sic-lang/devkit/.github/workflows/flake-checks.yml@<commit>
```

`uses:` gives the workflow's path in devkit, followed by `@` and a full commit hash of devkit, because a branch or a tag can move.
GitHub names each job after the calling job and the called job, so the ruleset requires `flake / checks`.
