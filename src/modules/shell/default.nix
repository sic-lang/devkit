{
  imports = [ ../checks ];

  perSystem =
    { pkgs, ... }:
    let
      # Runs a command on the shell scripts, after `--` so that it reads no name as an option.
      onScripts = command: "git ls-files -z .envrc '*.sh' | xargs -0 ${command} --";
    in
    {
      devkit.checks = {
        shellcheck = {
          packages = [
            pkgs.findutils
            pkgs.shellcheck
          ];
          command = onScripts "shellcheck";
        };
        shfmt = {
          packages = [
            pkgs.findutils
            pkgs.shfmt
          ];
          command = onScripts "shfmt --indent ${toString (import ../../lib.nix).indentSize} --diff";
        };
      };
    };
}
