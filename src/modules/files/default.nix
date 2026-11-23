{ flake-parts-lib, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [
    ../checks
    ../setups
  ];

  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      cfg = config.devkit;
      replacements = {
        targets = lib.escapeShellArgs (lib.attrNames cfg.files);
        # Interpolation copies a local file into the Nix store, which toString does not.
        sources = lib.escapeShellArgs (map (file: "${file}") (lib.attrValues cfg.files));
      };
    in
    {
      options.devkit.files = mkOption {
        description = ''
          The files that devkit generates, each a file of the flake or of the Nix store keyed by
          its path in the repository. The repository commits them, so that editors read them too.
        '';
        default = { };
        type = types.attrsOf types.path;
      };

      config.devkit = {
        setups.files = {
          description = "Write the files that devkit generates";
          command = cfg.mkSetup {
            name = "setup-files";
            mode = "644";
            inherit (cfg) files;
          };
        };
        checks.files.command = cfg.mkCommand {
          name = "check-files";
          template = ./check.sh.in;
          tools = [ pkgs.diffutils ];
          inherit replacements;
        };
      };
    }
  );
}
