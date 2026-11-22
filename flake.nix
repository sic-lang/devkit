{
  description = "Development kit for the repositories of the Sic programming language";

  inputs = {
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./modules/checks ];
      # The popular systems whose tools are all in the binary cache of nixpkgs: Linux on x86_64 and
      # aarch64, and macOS on Apple silicon.
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      flake.flakeModules = {
        checks = ./modules/checks;
      };
    };
}
