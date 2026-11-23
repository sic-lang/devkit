{ flake-parts-lib, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [ ../commands ];

  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      cfg = config.devkit;
      setups = lib.attrValues cfg.setups;
      setupAll = cfg.mkCommand {
        name = "setup";
        template = ./all.sh.in;
        replacements = {
          descriptions = lib.escapeShellArgs (lib.catAttrs "description" setups);
          programs = lib.escapeShellArgs (map (setup: lib.getExe setup.command.run) setups);
        };
      };
    in
    {
      options.devkit = {
        setups = mkOption {
          description = ''
            The setups, each run by its app setup-<name>, and by the app setup if the contributor
            confirms it, since each one configures a tool they may not use.
          '';
          default = { };
          type = types.attrsOf (import ../commands/command.nix lib);
        };
        mkSetup = mkOption {
          description = ''
            Makes the setup name that writes each file of the Nix store of files to its path in the
            repository, with the mode mode, without overwriting a file that differs from it, unless
            --force is given.
          '';
          type = types.functionTo types.raw;
          readOnly = true;
        };
      };

      config = {
        devkit.mkSetup =
          {
            name,
            files,
            mode,
          }:
          cfg.mkCommand {
            inherit name;
            template = ./write.sh.in;
            tools = [
              pkgs.diffutils
              pkgs.git
            ];
            replacements = {
              inherit name mode;
              targets = lib.escapeShellArgs (lib.attrNames files);
              sources = lib.escapeShellArgs (map toString (lib.attrValues files));
            };
          };

        devkit.commands =
          lib.mapAttrs' (name: setup: lib.nameValuePair "setup-${name}" setup) cfg.setups
          // {
            setup = {
              command = setupAll;
              description = "Run every setup";
            };
          };
      };
    }
  );
}
