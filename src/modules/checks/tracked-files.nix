# Builds a check that runs the command line `command` on the files that Git tracks.
# `pathspecs` selects among them, and without pathspecs the command receives every tracked file.
# The names follow `--`, so that the command reads no name as an option.
pkgs:
{
  pathspecs ? [ ],
  command,
  packages,
}:
let
  list = pkgs.lib.escapeShellArgs (
    [
      "git"
      "ls-files"
      "-z"
    ]
    ++ pathspecs
  );
in
{
  command = "${list} | xargs -0 ${command} --";
  packages = [ pkgs.findutils ] ++ packages;
}
