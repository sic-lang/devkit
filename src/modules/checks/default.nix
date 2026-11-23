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
          runtimeInputs = [ pkgs.git ] ++ check.tools;
          text = ''
            cd "$(git rev-parse --show-toplevel)"
            ${check.command}
          '';
        }
      ) cfg.checks;
      checkAll = cfg.mkCommand {
        name = "check";
        text = ''
          status=0
          ${lib.concatMapStrings (name: ''
            if output=$(${lib.getExe checkCommands.${name}.run} 2>&1); then
              echo ${lib.escapeShellArg "ok    ${name}"}
            else
              echo ${lib.escapeShellArg "FAIL  ${name}"}
              echo "$output"
              status=1
            fi
          '') (lib.attrNames checkCommands)}
          exit "$status"
        '';
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
                description = "The packages that the command runs, also in the shell.";
                type = types.listOf types.package;
                default = [ ];
              };
              command = mkOption {
                description = ''
                  The Bash command of the check, which fails if the check fails, and receives the
                  arguments of check-<name> as "$@".
                '';
                type = types.str;
              };
            };
          }
        );
      };

      config.devkit = {
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
    }
  );
}
