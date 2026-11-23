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
        cfg.mkCommand {
          name = "check-${name}";
          tools = [ pkgs.git ] ++ check.tools;
          inherit (check) replacements;
          template =
            if (check.command == null) == (check.template == null) then
              throw "The check ${name} needs either a command or a template."
            else if check.template != null then
              check.template
            else
              pkgs.replaceVars ./check.sh.in { inherit (check) command; };
        }
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
              tools = mkOption {
                description = "The packages that the check runs, also in the shell.";
                type = types.listOf types.package;
                default = [ ];
              };
              command = mkOption {
                description = ''
                  The Bash command of the check, which fails if the check fails, and receives the
                  arguments of check-<name> as "$@", unless the check has a template.
                '';
                type = types.nullOr types.str;
                default = null;
              };
              template = mkOption {
                description = ''
                  The Bash template of the check, as mkCommand takes it, which goes to the root of
                  the repository first, for a check that is more than one command.
                '';
                type = types.nullOr types.path;
                default = null;
              };
              replacements = mkOption {
                description = "The values of the placeholders of the template.";
                type = types.attrsOf types.str;
                default = { };
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
          shell.packages = lib.concatMap (check: check.tools) (lib.attrValues cfg.checks);
        };
      };
    }
  );
}
