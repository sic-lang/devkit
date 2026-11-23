{
  consumer,
  flakeModules,
  lib,
  pkgs,
  ...
}:
let
  evaluates =
    settings:
    (builtins.tryEval
      (consumer [
        flakeModules.files
        { perSystem.devkit = settings; }
      ]).apps.check-files.program
    ).success;
in
lib.mapAttrs
  (
    name:
    { settings, success }:
    assert evaluates settings == success;
    pkgs.writeText name ""
  )
  {
    # Without it, an unrelated error would make the other cases pass.
    unset = {
      settings = { };
      success = true;
    };
    set-80 = {
      settings.lineLength = 80;
      success = false;
    };
    # Even its own value, which a mere conflict between definitions would accept.
    set-100 = {
      settings.lineLength = 100;
      success = false;
    };
  }
