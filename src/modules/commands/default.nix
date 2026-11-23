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
          args:
          let
            script = extra: pkgs.writeShellApplication (args // cfg.commandArgs args // extra);
          in
          {
            run = script { checkPhase = ":"; };
            checked = script { };
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
