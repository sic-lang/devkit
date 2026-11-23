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
        sources = lib.escapeShellArgs (map toString (lib.attrValues cfg.files));
      };
    in
    {
      options.devkit = {
        files = mkOption {
          description = ''
            The files that devkit generates, each a file of the Nix store under its path in the
            repository, where they are committed, so that the editors read them too.
          '';
          default = { };
          type = types.attrsOf types.path;
        };
        lineLength = mkOption {
          description = "The length of the longest line, the default of the generated files.";
          type = types.ints.positive;
          default = 100;
        };
      };

      config.devkit = lib.mkIf (cfg.files != { }) {
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
