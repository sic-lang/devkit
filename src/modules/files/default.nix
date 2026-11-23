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
      generate = file: pkgs.replaceVars file.template file.replacements;
      generated = lib.mapAttrs (_: generate) cfg.files;
    in
    {
      options.devkit.files = mkOption {
        description = ''
          The files that devkit generates, each keyed by its path in the repository. The
          repository commits them, so that editors read them too.
        '';
        default = { };
        type = types.attrsOf (
          types.submodule {
            options = {
              template = mkOption {
                description = "The file's template, from the flake or the Nix store.";
                type = types.path;
              };
              replacements = mkOption {
                description = "The value of each @name@ placeholder of the template.";
                type = types.attrsOf types.str;
                default = { };
              };
            };
          }
        );
      };

      config.devkit = {
        setups.files = {
          description = "Write the files that devkit generates";
          command = cfg.mkSetup {
            name = "setup-files";
            mode = "644";
            files = generated;
          };
        };
        checks.files.command = cfg.mkCommand {
          name = "check-files";
          template = ./check.sh.in;
          packages = [ pkgs.diffutils ];
          replacements = import ../setups/targets.nix lib generated;
        };
      };
    }
  );
}
