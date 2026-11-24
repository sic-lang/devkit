{
  imports = [ ../checks ];

  perSystem =
    { pkgs, ... }:
    {
      devkit.checks.nixfmt = {
        packages = [
          pkgs.findutils
          pkgs.nixfmt
        ];
        command = "git ls-files -z '*.nix' | xargs -0 nixfmt --check";
      };
    };
}
