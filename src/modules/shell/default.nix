{
  imports = [ ../checks ];

  perSystem =
    { pkgs, ... }:
    {
      devkit.checks = {
        shellcheck = {
          packages = [
            pkgs.findutils
            pkgs.shellcheck
          ];
          command = "git ls-files -z .envrc '*.sh' | xargs -0 shellcheck";
        };
        shfmt = {
          packages = [
            pkgs.findutils
            pkgs.shfmt
          ];
          command = "git ls-files -z .envrc '*.sh' | xargs -0 shfmt --diff";
        };
      };
    };
}
