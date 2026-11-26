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
    in
    {
      options.devkit.files = mkOption {
        description = ''
          The files that devkit generates, each keyed by its path in the repository. The
          repository commits them, so that editors read them too.
        '';
        default = { };
        type = types.attrsOf (
          types.submodule {
            options.source = mkOption {
              description = "The file, from the flake or the Nix store, that devkit copies.";
              type = types.path;
            };
          }
        );
      };

      options.devkit.formats = mkOption {
        description = ''
          The formats of the generated files, JSON and YAML, like those of nixpkgs' `pkgs.formats`:
          each gives the `type` of its values, for an option that merges them, and `generate`,
          which writes a value to a file with the indentation of devkit's library.
        '';
        type = types.attrsOf types.raw;
        readOnly = true;
      };

      config.devkit = {
        # The YAML format of nixpkgs does not indent the sequences of a mapping, and wraps a long
        # value after a trailing space, which yamllint refuses, so devkit writes YAML with yq, and
        # JSON too, so that one tool writes both with devkit's indentation.
        formats =
          lib.mapAttrs
            (output: format: {
              inherit (format) type;
              generate =
                name: value:
                pkgs.runCommand name {
                  nativeBuildInputs = [ pkgs.yq-go ];
                  value = builtins.toJSON value;
                  passAsFile = [ "value" ];
                } ''yq -p json -o ${output} -P --indent ${indent} "$valuePath" >"$out"'';
            })
            {
              json = pkgs.formats.json { };
              yaml = pkgs.formats.yaml_1_2 { };
            };
        setups.files = {
          description = "Write the files that devkit generates";
          command = cfg.mkSetup {
            name = "setup-files";
            mode = "644";
            files = generated;
          };
        };
        checks.files.command =
          let
            inherit (import ../setups/targets.nix lib generated) targets sources;
          in
          cfg.mkCommand {
            name = "check-files";
            packages = [ pkgs.diffutils ];
            text = ''
              targets=(${targets})
              sources=(${sources})
              status=0
              for i in "''${!targets[@]}"; do
                target=''${targets[$i]}
                if [ ! -e "$target" ]; then
                  echo "$target is missing: run setup-files to write it" >&2
                  status=1
                elif ! cmp -s "''${sources[$i]}" "$target"; then
                  diff -u "$target" "''${sources[$i]}" || true
                  echo "$target differs from the generated one above: change its source in" \
                    "devkit.files, then run setup-files --force to rewrite it" >&2
                  status=1
                fi
              done
              exit "$status"
            '';
          };
      };
    }
  );
}
