let
  shared = import ../../lib.nix;
in
{
  imports = [ ../checks ];

  perSystem =
    { lib, pkgs, ... }:
    let
      # The one selection of the files that the check checks and the formatter formats.
      nixFiles = pkgs.writeShellApplication {
        name = "nix-files";
        runtimeInputs = [
          pkgs.gnugrep
          (import ../checks/tracked-files.nix pkgs).trackedFiles
        ];
        text = builtins.readFile ./nix-files.sh;
      };
      # nixfmt with devkit's line length and indentation, for the check, the formatter and the
      # development shell.
      nixfmt = pkgs.writeShellApplication {
        name = "nixfmt";
        text = ''
          exec ${lib.getExe pkgs.nixfmt} \
            --width ${toString shared.lineLength} \
            --indent ${toString shared.indentSize} \
            "$@"
        '';
      };
      packages = [
        nixFiles
        nixfmt
        pkgs.findutils
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
