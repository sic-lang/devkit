{
  imports = [ ../checks ];

  perSystem =
    { pkgs, ... }:
    let
      indentSize = toString (import ../../lib.nix).indentSize;
      # A check that runs a command on the shell scripts.
      onScripts =
        command: package:
        import ../checks/tracked-files.nix pkgs {
          pathspecs = [
            ".envrc"
            "*.sh"
          ];
          inherit command;
          packages = [ package ];
        };
    in
    {
      devkit.checks = {
        shellcheck = onScripts "shellcheck" pkgs.shellcheck;
        shfmt = onScripts "shfmt --indent ${indentSize} --diff" pkgs.shfmt;
      };
    };
}
