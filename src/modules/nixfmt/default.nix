{
  imports = [ ../checks ];

  perSystem =
    { pkgs, ... }:
    let
      # The one selection of the files that the check checks and the formatter formats.
      nixFiles = pkgs.writeShellApplication {
        name = "nix-files";
        runtimeInputs = [
          pkgs.git
          pkgs.gnugrep
        ];
        text = builtins.readFile ./nix-files.sh;
      };
      packages = [
        nixFiles
        pkgs.findutils
        pkgs.nixfmt
      ];
    in
    {
      formatter = pkgs.writeShellApplication {
        name = "format-nix";
        runtimeInputs = packages;
        text = builtins.readFile ./format.sh;
      };
      devkit.checks.nixfmt = {
        inherit packages;
        command = "nix-files | xargs -0 nixfmt --check --";
      };
    };
}
