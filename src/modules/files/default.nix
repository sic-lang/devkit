{ flake-parts-lib, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [
    ../checks
    ../setups
  ];

  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      cfg = config.devkit;
      generated = lib.mapAttrs (_: file: file.source) cfg.files;
      indent = toString (import ../../lib.nix).indentSize;
      # A format whose files `command` writes from the JSON of the value, in the file that its last
      # argument names, with the programs of `package`.
      format = type: package: command: {
        inherit type;
        generate =
          name: value:
          pkgs.runCommand name {
            nativeBuildInputs = [ package ];
            value = builtins.toJSON value;
            passAsFile = [ "value" ];
          } ''${command} "$valuePath" >"$out"'';
      };
    in
    {
      options.devkit.files = mkOption {
        description = ''
          The files that devkit generates, each keyed by its path in the repository. The
          repository commits them, so that editors read them too.
        '';
        default = { };
        type = types.attrsOf (
          types.submodule (
            { config, ... }:
            {
              options = {
                source = mkOption {
                  description = ''
                    The file, from the flake or the Nix store, which devkit copies as it is. It
                    defaults to the file built from `template`.
                  '';
                  type = types.path;
                };
                template = mkOption {
                  description = "The file's template, from the flake or the Nix store.";
                  type = types.nullOr types.path;
                  default = null;
                };
                replacements = mkOption {
                  description = "The value of each `@name@` placeholder of the template.";
                  type = types.attrsOf types.str;
                  default = { };
                };
              };
              config.source = lib.mkIf (config.template != null) (
                pkgs.replaceVars config.template config.replacements
              );
            }
          )
        );
      };

      options.devkit.formats = mkOption {
        description = ''
          The formats of the generated files, like those of nixpkgs' `pkgs.formats`: each gives the
          `type` of its values, for an option that merges them, and `generate`, which writes a value
          to a file with the indentation of devkit's library.
        '';
        type = types.attrsOf types.raw;
        readOnly = true;
      };

      config.devkit = {
        formats = {
          json = format (pkgs.formats.json { }).type pkgs.jq "jq --indent ${indent} .";
          # yq indents the sequences of a mapping and does not wrap long values, as yamllint
          # requires.
          yaml =
            format (pkgs.formats.yaml_1_2 { }).type pkgs.yq-go
              "yq -p json -o yaml -P --indent ${indent} .";
        };
        setups.files = {
          description = "Write the files that devkit generates";
          command = cfg.mkSetup {
            name = "setup-files";
            mode = "644";
            files = generated;
          };
        };
        checks.files.command = cfg.mkCommand {
          name = "check-files";
          template = ./check.sh.in;
          packages = [ pkgs.diffutils ];
          replacements = import ../setups/targets.nix lib generated;
        };
      };
    }
  );
}
