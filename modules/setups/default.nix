{ flake-parts-lib, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [ ../commands ];

  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      config,
      options,
      pkgs,
      ...
    }:
    let
      cfg = config.devkit;
      setupAll = cfg.mkCommand {
        name = "setup";
        text = ''
          status=0
          ${lib.concatMapStrings (name: ''
            read -r -p "${cfg.setups.${name}.description}? [y/N] " answer || true
            if [[ $answer == [yY]* ]]; then
              ${lib.getExe cfg.setups.${name}.command.run} "$@" || status=1
            fi
          '') (lib.attrNames cfg.setups)}
          exit "$status"
        '';
      };
    in
    {
      options.devkit = {
        setups = mkOption {
          description = ''
            The setups, each run by its app setup-<name>, and by the app setup if the contributor
            confirms it, since each one configures a tool they may not use.
          '';
          default = { };
          type = types.attrsOf options.devkit.commands.type.nestedTypes.elemType;
        };
        mkSetup = mkOption {
          description = ''
            Makes a setup that writes the files sources to the directory dir, each under the name of
            its source in the Nix store and with the mode mode, without overwriting a file that
            differs from it, unless --force is given.
          '';
          type = types.functionTo types.raw;
          readOnly = true;
        };
      };

      config = {
        devkit.mkSetup =
          {
            name,
            dir,
            mode,
            sources,
          }:
          cfg.mkCommand {
            inherit name;
            runtimeInputs = [
              pkgs.coreutils
              pkgs.diffutils
              pkgs.git
            ];
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
              dir=${dir}
              sources=(${lib.concatStringsSep " " sources})
              status=0
              for source in "''${sources[@]}"; do
                target=$dir/''${source#*-}
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
                  echo "kept $target, which differs from the recommended one above:" \
                    "merge it by hand, or overwrite it with --force" >&2
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
