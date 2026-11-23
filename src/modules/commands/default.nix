{ flake-parts-lib, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      cfg = config.devkit;
    in
    {
      options.devkit = {
        commands = mkOption {
          description = "The commands, each run by its app and checked by its flake check <name>.";
          default = { };
          type = types.attrsOf (import ./command.nix lib);
        };
        mkCommand = mkOption {
          description = ''
            Makes the command name from the Bash template template, whose header is that of
            header.sh.in and whose placeholders @name@ are replaced by the values of replacements,
            with the packages tools on its PATH, in two variants: run, for nix run, and checked,
            which ShellCheck checks, for nix flake check.
          '';
          type = types.functionTo types.raw;
          readOnly = true;
        };
        shell = {
          packages = mkOption {
            description = "The packages of the development shell.";
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
          {
            name,
            template,
            replacements ? { },
            tools ? [ ],
          }:
          let
            run = pkgs.replaceVarsWith {
              inherit name;
              src = pkgs.concatText "${name}.sh.in" [
                ./header.sh.in
                template
              ];
              dir = "bin";
              isExecutable = true;
              # coreutils keeps PATH from starting with an empty entry, the current directory.
              replacements = {
                bash = pkgs.runtimeShell;
                path = lib.makeBinPath ([ pkgs.coreutils ] ++ tools);
              }
              // replacements;
              meta.mainProgram = name;
            };
          in
          {
            inherit run;
            checked = pkgs.runCommand "${name}-checked" {
              nativeBuildInputs = [ pkgs.shellcheck ];
              script = lib.getExe run;
              dryRun = pkgs.stdenv.shellDryRun;
            } (builtins.readFile ./checked.sh);
          };

        apps = lib.mapAttrs (name: command: {
          type = "app";
          program = lib.getExe command.command.run;
          meta = { inherit (command) description; };
        }) cfg.commands;

        checks = lib.mapAttrs (name: command: command.command.checked) cfg.commands;

        devShells.default = pkgs.mkShellNoCC {
          packages = lib.unique cfg.shell.packages;
          inherit (cfg.shell) env shellHook;
        };
      };
    }
  );
}
