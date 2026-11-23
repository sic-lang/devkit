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
      checkCommands = lib.mapAttrs (
        name: check:
        if lib.isString check.command then
          cfg.mkCommand {
            name = "check-${name}";
            template = pkgs.replaceVars ./check.sh.in { inherit (check) command; };
            inherit (check) tools;
          }
        else
          check.command
      ) cfg.checks;
      checkAll = cfg.mkCommand {
        name = "check";
        template = ./all.sh.in;
        replacements = {
          names = lib.escapeShellArgs (lib.attrNames checkCommands);
          programs = lib.escapeShellArgs (
            map (command: lib.getExe command.run) (lib.attrValues checkCommands)
          );
        };
      };
    in
    {
      options.devkit.checks = mkOption {
        description = "The checks, each run from the root of the repository by check-<name>.";
        default = { };
        type = types.attrsOf (
          types.submodule {
            options = {
              command = mkOption {
                description = ''
                  The command of the check, which fails if the check fails, and receives the
                  arguments of check-<name>: either a command line, which Bash runs and which
                  receives them as "$@", or a command made by mkCommand.
                '';
                type = types.either types.str (import ../commands/built.nix lib);
              };
              tools = mkOption {
                description = "The packages that a command line runs.";
                type = types.listOf types.package;
                default = [ ];
              };
            };
          }
        );
      };

      config = {
        devkit = {
          commands =
            lib.mapAttrs' (
              name: command:
              lib.nameValuePair "check-${name}" {
                inherit command;
                description = "Run the ${name} check";
              }
            ) checkCommands
            // {
              check = {
                command = checkAll;
                description = "Run every check";
              };
            };
          shell.packages = lib.concatMap (command: command.tools) (lib.attrValues checkCommands);
        };
      };
    }
  );
}
