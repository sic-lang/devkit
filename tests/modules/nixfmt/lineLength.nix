{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.nixfmt ]) devShells;
  # The nixfmt that the module provides, which the check and the formatter also run.
  nixfmt = lib.findFirst (
    package: package.name == "nixfmt"
  ) (throw "no nixfmt in the development shell") devShells.default.nativeBuildInputs;
in
{
  # Bash traces the command that the wrapper runs, with its arguments as nixfmt receives them.
  shared = repository {
    name = "shared";
    command = "${lib.getExe pkgs.bash} -x ${lib.getExe nixfmt} --version";
    output = [ " --width 100 --version" ];
  };
}
