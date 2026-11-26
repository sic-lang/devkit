{
  imports = [ ../files ];

  perSystem =
    { pkgs, ... }:
    {
      devkit.files.".envrc".source = pkgs.writeText "envrc" ''
        # shellcheck shell=bash
        use flake
      '';
    };
}
