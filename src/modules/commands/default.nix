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
          description = "The commands, each run by its app <name> and checked by its flake check.";
          default = { };
          type = types.attrsOf (import ./command.nix lib);
        };
        commandEnv = mkOption {
          description = ''
            The environment variables that a command exports, as a function of the arguments passed
            to mkCommand to build it.
          '';
          type = types.functionTo (types.attrsOf types.str);
          default = _: { };
        };
        mkCommand = mkOption {
          description = ''
            Builds the command `name` from the Bash template `template`, prefixed with the header
            from header.sh.in. The header sets the Bash options, exports the variables from
            commandEnv, puts the `tools` packages on PATH and changes to the repository's root. Each
            @name@ placeholder is replaced with its value from `replacements`. Returns `run`, the
            script for nix run; `checked`, its ShellCheck check for nix flake check; and `tools`.
          '';
          type = types.functionTo types.raw;
          readOnly = true;
        };
        shell = {
          packages = mkOption {
            description = "The development shell's packages.";
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
          }@args:
          let
            export = name: value: "export ${name}=${lib.escapeShellArg value}";
            run = pkgs.replaceVarsWith {
              inherit name;
              src = pkgs.concatText "${name}.sh.in" [
                ./header.sh.in
                template
              ];
              dir = "bin";
              isExecutable = true;
              # coreutils avoids an empty first entry in PATH, which would mean the current directory.
              replacements = {
                bash = pkgs.runtimeShell;
                path = lib.makeBinPath (
                  [
                    pkgs.coreutils
                    pkgs.git
                  ]
                  ++ tools
                );
                env = lib.concatLines (lib.mapAttrsToList export (cfg.commandEnv args));
              }
              // replacements;
              meta.mainProgram = name;
            };
          in
          {
            inherit run tools;
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
