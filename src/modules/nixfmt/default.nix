{
  imports = [ ../checks ];

  perSystem =
    { pkgs, ... }:
    let
      # The one selection of the files that the check checks.
      nixFiles = pkgs.writeShellApplication {
        name = "nix-files";
        runtimeInputs = [
          pkgs.git
          pkgs.gnugrep
        ];
        text = builtins.readFile ./nix-files.sh;
      };
    in
    {
      devkit.checks.nixfmt = {
        packages = [
          nixFiles
          pkgs.findutils
          pkgs.nixfmt
        ];
        command = "nix-files | xargs -0 nixfmt --check";
      };
    };
}
