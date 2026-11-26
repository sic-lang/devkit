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
            text = check.command;
            inherit (check) packages;
          }
        else
          check.command
      ) cfg.checks;
      programs = map lib.getExe (lib.catAttrs "run" (lib.attrValues checkCommands));
      checkAll = cfg.mkCommand {
        name = "check";
        text = ''
          names=(${lib.escapeShellArgs (lib.attrNames checkCommands)})
          programs=(${lib.escapeShellArgs programs})
          status=0
          for i in "''${!names[@]}"; do
            if output=$("''${programs[$i]}" 2>&1); then
              echo "ok    ''${names[$i]}"
            else
              echo "FAIL  ''${names[$i]}"
              echo "$output"
              status=1
            fi
          done
          exit "$status"
        '';
      };
    in
    {
      options.devkit.checks = mkOption {
        description = "The checks, each run from the repository's root by its `check-<name>` app.";
        default = { };
        type = types.attrsOf (
          types.submodule {
            options = {
              command = mkOption {
                description = ''
                  The check's command. It receives the arguments of its `check-<name>` app and
                  returns a failure status if the check fails. It is either a command line, which
                  Bash runs with the arguments as `"$@"`, or a command built by `mkCommand`.
                '';
                type = types.either types.str (import ../commands/built.nix lib);
              };
              packages = mkOption {
                description = "The packages whose programs a command line runs.";
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
          shell.packages = lib.concatMap (command: command.packages) (lib.attrValues checkCommands);
        };
      };
    }
  );
}
