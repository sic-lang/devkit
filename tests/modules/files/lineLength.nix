{
  consumer,
  flakeModules,
  pkgs,
  ...
}:
let
  # A repository that sets the line length, even to its own value, and a file that reads it.
  outputs = consumer [
    flakeModules.files
    {
      perSystem =
        { config, ... }:
        {
          devkit = {
            lineLength = 100;
            files."example.txt" = {
              template = pkgs.writeText "example.txt.in" "@lineLength@\n";
              replacements.lineLength = toString config.devkit.lineLength;
            };
          };
        };
    }
  ];
in
{
  read-only =
    assert !(builtins.tryEval outputs.apps.setup-files.program).success;
    pkgs.writeText "read-only" "";
}
