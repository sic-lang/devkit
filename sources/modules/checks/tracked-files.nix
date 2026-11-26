# The programs that list the files that Git tracks and run a command on a list of files, and the
# checks that run a command on the files that Git tracks.
# Commands run them from the directory of their choice, so they are packages, not commands built by
# mkCommand, which would change to the repository's root.
pkgs:
let
  application = import ../commands/shell-application.nix pkgs;
  trackedFiles = application {
    name = "tracked-files";
    runtimeInputs = [ pkgs.git ];
    # Lists the files that git ls-files selects with the given arguments, each followed by a NUL
    # character, keeping only those that are regular files in the working tree.
    # Git lists an unmerged path once for each stage, unless told to deduplicate.
    # Git also lists submodules, and files deleted from the working tree, which a tool would walk
    # as a directory or fail to read.
    # Git tracks the target path of a symbolic link but not the target's content, so the list
    # leaves out symbolic links, even those to regular files.
    text = ''
      git ls-files -z --deduplicate "$@" | while IFS= read -r -d ''' file; do
        if [ -f "$file" ] && [ ! -L "$file" ]; then
          printf '%s\0' "$file"
        fi
      done
    '';
  };
  onFiles = application {
    name = "on-files";
    runtimeInputs = [ pkgs.findutils ];
    # Runs the command between the first argument and `--` on the files that the command after
    # `--` lists, each followed by a NUL character.
    # The first argument says why the list can be empty, for the message of the failure.
    # The names follow the command's own `--`, so that it reads no name as an option.
    text = ''
      reason=$1
      shift
      command=()
      while [ "$1" != -- ]; do
        command+=("$1")
        shift
      done
      shift
      mapfile -d ''' files < <("$@")
      wait "$!"
      # Without files, the command would search for files itself or read its standard input.
      if [ "''${#files[@]}" -eq 0 ]; then
        echo "No file to check: $reason" >&2
        exit 1
      fi
      printf '%s\0' "''${files[@]}" | xargs -0 "''${command[@]}" --
    '';
  };
  onTrackedFiles = application {
    name = "on-tracked-files";
    runtimeInputs = [
      onFiles
      trackedFiles
    ];
    # Runs the command after `--` on the regular files that Git tracks and that the pathspecs
    # before `--` select, or on all of them without pathspecs.
    text = ''
      pathspecs=()
      while [ "$1" != -- ]; do
        pathspecs+=("$1")
        shift
      done
      shift
      reason="Git tracks no regular file"
      if [ "''${#pathspecs[@]}" -gt 0 ]; then
        alternatives=$(printf ' or %s' "''${pathspecs[@]}")
        reason+=" that matches ''${alternatives# or }"
      fi
      on-files "$reason" "$@" -- tracked-files -- "''${pathspecs[@]}"
    '';
  };
in
{
  inherit onFiles trackedFiles;
  # A check that runs the command line `command` on the files that `pathspecs` selects.
  check =
    {
      pathspecs ? [ ],
      command,
      packages,
    }:
    let
      run = pkgs.lib.escapeShellArgs ([ "on-tracked-files" ] ++ pathspecs ++ [ "--" ]);
    in
    {
      command = "${run} ${command}";
      packages = [ onTrackedFiles ] ++ packages;
    };
}
