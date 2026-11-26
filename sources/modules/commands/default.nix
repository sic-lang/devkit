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
          description = ''
            The commands, each run by its `<name>` app.
          '';
          default = { };
          type = types.attrsOf (import ./command.nix lib);
        };
        commandEnv = mkOption {
          description = ''
            The environment variables that a command exports, as a function of the arguments passed
            to `mkCommand` to build it, with their defaults.
          '';
          type = types.functionTo (types.attrsOf types.str);
          default = _: { };
        };
        mkCommand = mkOption {
          description = ''
            Builds the `name` command, which runs the Bash code `text` from the repository's root,
            with nixpkgs' `writeShellApplication`: the programs of `packages` on `PATH`, the
            variables from `commandEnv`, and the build fails if ShellCheck or shfmt rejects the
            script. Returns `run`, the script for `nix run`, and `packages`.
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
            text,
            packages ? [ ],
          }@args:
          {
            inherit packages;
            run = import ./shell-application.nix pkgs {
              inherit name;
              runtimeInputs = [
                pkgs.coreutils
                pkgs.git
              ]
              ++ packages;
              runtimeEnv = cfg.commandEnv (args // { inherit packages; });
              text = ''
                cd "$(git rev-parse --show-toplevel)"
              ''
              + text;
            };
          };

        apps = lib.mapAttrs (name: command: {
          type = "app";
          program = lib.getExe command.command.run;
          meta = { inherit (command) description; };
        }) cfg.commands;

        devShells.default = pkgs.mkShellNoCC {
          packages = lib.unique cfg.shell.packages;
          inherit (cfg.shell) env shellHook;
        };
      };
    }
  );
}
