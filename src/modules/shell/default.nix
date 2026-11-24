{
  imports = [ ../checks ];

  perSystem =
    { pkgs, ... }:
    let
      # Runs a command on the shell scripts.
      onScripts = command: "git ls-files -z .envrc '*.sh' | xargs -0 ${command}";
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
          command = onScripts "shfmt --diff";
        };
      };
    };
}
