# The programs that list the files that Git tracks and run a command on a list of files, and the
# checks that run a command on the files that Git tracks.
# Commands run them from the directory of their choice, so they are packages, not commands built by
# mkCommand, which would change to the repository's root.
pkgs:
let
  trackedFiles = pkgs.writeShellApplication {
    name = "tracked-files";
    runtimeInputs = [ pkgs.git ];
    text = builtins.readFile ./tracked-files.sh;
  };
  onFiles = pkgs.writeShellApplication {
    name = "on-files";
    runtimeInputs = [ pkgs.findutils ];
    text = builtins.readFile ./on-files.sh;
  };
  onTrackedFiles = pkgs.writeShellApplication {
    name = "on-tracked-files";
    runtimeInputs = [
      onFiles
      trackedFiles
    ];
    text = builtins.readFile ./on-tracked-files.sh;
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
