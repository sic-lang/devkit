# Devkit

Development kit for the repositories of the Sic programming language.
It holds what they share to develop, check and review their content: the modules of their flakes, their workflows, and the agents that work in them.

## Usage

A repository takes devkit as an input of its flake, next to the `nixpkgs` whose packages the modules use, and imports with [flake-parts](https://flake.parts) the modules it needs, each a directory of `modules/` exported as `flakeModules.<name>`:

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

The options of the modules are under `devkit.`.
`nix run .#check` runs every check, `nix run .#check-<name>` one of them, and `nix run .#setup` every setup that the contributor confirms.

## License

Licensed under the [Apache License, Version 2.0](LICENSES/Apache-2.0.txt) with [LLVM Exceptions](LICENSES/LLVM-exception.txt) (`Apache-2.0 WITH LLVM-exception`).
