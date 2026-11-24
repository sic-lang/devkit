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
            The setups, each run by its `setup-<name>` app, and by the `setup` app if the
            contributor confirms it, because each setup configures a tool that the contributor may
            not use.
          '';
          default = { };
          type = types.attrsOf (import ../commands/command.nix lib);
        };
        mkSetup = mkOption {
          description = ''
            Builds the `name` setup, which writes each file in `files`, from the flake or the Nix
            store, to its path in the repository, with mode `mode`. It never overwrites a file that
            differs, unless `--force` is given. The paths are relative to the repository's root,
            or to `directory`, the Bash code that expands to the directory when the setup runs.
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
            directory ? "",
          }:
          cfg.mkCommand {
            inherit name;
            template = ./write.sh.in;
            packages = [ pkgs.diffutils ];
            replacements = {
              inherit directory name mode;
            }
            // import ./targets.nix lib files;
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
