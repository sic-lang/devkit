# Devkit

Development kit for the repositories of the Sic programming language.
It holds what they share to develop, check and review their content: the modules of their flakes, their workflows, and the agents that work in them.

## Usage

A repository adds devkit and the `nixpkgs` of its tools to the inputs of its flake, and imports the modules it needs from `flakeModules` with [flake-parts](https://flake.parts):

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

Each module is configured by its options in `perSystem`, all under `devkit`, such as `devkit.lineLength`.
`nix run .#check` runs every check, `nix run .#check-<name>` one of them, and `nix run .#setup` every setup that the contributor confirms.

## License

Licensed under the [Apache License, Version 2.0](LICENSES/Apache-2.0.txt) with [LLVM Exceptions](LICENSES/LLVM-exception.txt) (`Apache-2.0 WITH LLVM-exception`).
