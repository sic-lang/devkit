{ flake-parts-lib, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
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
          run() {
            local name=$1 output
            shift
            if output=$("$@" 2>&1); then
              echo "ok    $name"
            else
              echo "FAIL  $name"
              echo "$output"
              status=1
            fi
          }
          ${lib.concatMapStrings (name: "run ${name} ${lib.getExe checkCommands.${name}.run}\n") (
            lib.attrNames checkCommands
          )}
          exit "$status"
        '';
      };
    in
    {
      options.devkit = {
        commands = mkOption {
          description = "The commands, each run by its app and checked by its flake check <name>.";
          default = { };
          type = types.attrsOf (
            types.submodule {
              options = {
                command = mkOption {
                  description = "The command, as made by mkCommand.";
                  type = types.submodule {
                    options = {
                      run = mkOption { type = types.package; };
                      checked = mkOption { type = types.package; };
                    };
                  };
                };
                description = mkOption {
                  description = "The description of the app.";
                  type = types.str;
                };
              };
            }
          );
        };
        checks = mkOption {
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
                  description = "The Bash command of the check, which fails if the check fails.";
                  type = types.str;
                };
              };
            }
          );
        };
        commandArgs = mkOption {
          description = ''
            The arguments that a command adds to those given to writeShellApplication, as a function
            of them.
          '';
          type = types.functionTo (types.attrsOf types.anything);
          default = _: { };
        };
        mkCommand = mkOption {
          description = ''
            Makes a command from the arguments of writeShellApplication, in two variants: run, which
            skips ShellCheck, for nix run, and checked, which runs it, for nix flake check.
          '';
          type = types.functionTo types.raw;
          readOnly = true;
        };
        shell = {
          packages = mkOption {
            description = "The packages of the development shell, besides the tools of the checks.";
            type = types.listOf types.package;
            default = [ ];
          };
          env = mkOption {
            description = "The environment variables of the development shell.";
            type = types.attrsOf types.str;
            default = { };
          };
          shellHook = mkOption {
            description = "The commands that the development shell runs when it starts.";
            type = types.lines;
            default = "";
          };
        };
      };

      config = {
        devkit.mkCommand =
          args:
          let
            script = extra: pkgs.writeShellApplication (args // cfg.commandArgs args // extra);
          in
          {
            run = script { checkPhase = ":"; };
            checked = script { };
          };

        devkit.commands =
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

        apps = lib.mapAttrs (name: command: {
          type = "app";
          program = lib.getExe command.command.run;
          meta = { inherit (command) description; };
        }) cfg.commands;

        checks = lib.mapAttrs (name: command: command.command.checked) cfg.commands;

        devShells.default = pkgs.mkShellNoCC {
          packages = lib.unique (
            lib.concatMap (check: check.tools) (lib.attrValues cfg.checks) ++ cfg.shell.packages
          );
          inherit (cfg.shell) env shellHook;
        };
      };
    }
  );
}
