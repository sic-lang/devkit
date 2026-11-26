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
      setups = lib.attrValues cfg.setups;
      setupAll = cfg.mkCommand {
        name = "setup";
        text = ''
          descriptions=(${lib.escapeShellArgs (lib.catAttrs "description" setups)})
          programs=(${lib.escapeShellArgs (map (setup: lib.getExe setup.command.run) setups)})
          status=0
          for i in "''${!programs[@]}"; do
            read -r -p "''${descriptions[$i]}? [y/N] " answer || true
            if [[ $answer == [yY]* ]]; then
              "''${programs[$i]}" "$@" || status=1
            fi
          done
          exit "$status"
        '';
      };
    in
    {
      options.devkit = {
        setups = mkOption {
          description = ''
            The setups, each run by its `setup-<name>` app, and by the `setup` app if the
            contributor confirms it, because each setup configures a tool that the contributor may
            not use.
          '';
          default = { };
          type = types.attrsOf (import ../commands/command.nix lib);
        };
        mkSetup = mkOption {
          description = ''
            Builds the `name` setup, which writes each file in `files`, from the flake or the Nix
            store, to its path in the repository, with mode `mode`. It never overwrites a file that
            differs, unless `--force` is given. The paths are relative to the repository's root,
            or to `directory`, the Bash code that expands to the directory when the setup runs.
          '';
          type = types.functionTo types.raw;
          readOnly = true;
        };
      };

      config = {
        devkit.mkSetup =
          {
            name,
            files,
            mode,
            directory ? "",
          }:
          let
            inherit (import ./targets.nix lib files) targets sources;
          in
          cfg.mkCommand {
            inherit name;
            packages = [ pkgs.diffutils ];
            text = ''
              force=false
              case "$*" in
              "") ;;
              --force) force=true ;;
              *)
                echo "usage: ${name} [--force]" >&2
                exit 2
                ;;
              esac
              directory=${directory}
              targets=(${targets})
              sources=(${sources})
              status=0
              for i in "''${!targets[@]}"; do
                target=''${directory:+$directory/}''${targets[$i]}
                source=''${sources[$i]}
                if [ ! -e "$target" ]; then
                  install -D -m ${mode} "$source" "$target"
                  echo "created $target"
                elif cmp -s "$source" "$target"; then
                  echo "up to date $target"
                elif $force; then
                  install -m ${mode} "$source" "$target"
                  echo "overwritten $target"
                else
                  diff -u --color=auto "$target" "$source" || true
                  echo "kept $target, which differs from the file that ${name} writes, shown" \
                    "above: overwrite it with --force" >&2
                  status=1
                fi
              done
              exit "$status"
            '';
          };

        devkit.commands =
          lib.mapAttrs' (name: setup: lib.nameValuePair "setup-${name}" setup) cfg.setups
          // {
            setup = {
              command = setupAll;
              description = "Run every setup";
            };
          };
      };
    }
  );
}
