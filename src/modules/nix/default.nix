let
  shared = import ../../lib.nix;
in
{
  imports = [ ../checks ];

  perSystem =
    { lib, pkgs, ... }:
    let
      tracked = import ../checks/tracked-files.nix pkgs;
      application = import ../commands/shell-application.nix pkgs;
      # The one selection of the files that the check checks and the formatter formats.
      # It lists the Nix files that Git tracks as regular files under the given paths, or in the
      # whole repository without paths, relative to the current directory and each followed by a
      # NUL character.
      nixFiles = application {
        name = "nix-files";
        runtimeInputs = [
          pkgs.gnugrep
          tracked.trackedFiles
        ];
        text = ''
          options=()
          if [ "$#" -eq 0 ]; then
            set -- :/
          else
            # The paths are names, not patterns, and each must name a file or a directory that Git
            # tracks.
            export GIT_LITERAL_PATHSPECS=1
            options=(--error-unmatch)
          fi
          # grep fails when it selects no file, which is no error here.
          # -a keeps a name that is not valid in the locale, which grep would otherwise take for
          # binary data and leave out.
          tracked-files "''${options[@]}" -- "$@" | { grep -a -z '\.nix$' || [ "$?" -eq 1 ]; }
        '';
      };
      # nixfmt with devkit's line length and indentation, for the check, the formatter and the
      # development shell.
      nixfmt = application {
        name = "nixfmt";
        text = ''
          exec ${lib.getExe pkgs.nixfmt} \
            --width ${toString shared.lineLength} \
            --indent ${toString shared.indentSize} \
            "$@"
        '';
      };
      packages = [
        nixFiles
        nixfmt
        pkgs.findutils
      ];
    in
    {
      # Formats the Nix files that Git tracks, under the given paths or in the whole repository.
      # Paths can select no Nix file, so nixfmt only runs on a file.
      formatter = application {
        name = "format-nix";
        runtimeInputs = packages;
        text = ''
          nix-files "$@" | xargs -0 --no-run-if-empty nixfmt --
        '';
      };
      devkit.checks.nixfmt = {
        packages = packages ++ [ tracked.onFiles ];
        command = "on-files 'Git tracks no Nix file' nixfmt --check -- nix-files";
      };
    };
}
