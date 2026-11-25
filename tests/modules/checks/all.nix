{
  consumer,
  flakeModules,
  lib,
  repository,
  ...
}:
let
  check =
    checks:
    (consumer [
      flakeModules.checks
      { perSystem.devkit = { inherit checks; }; }
    ]).apps.check.program;
  passing.command = "echo hidden";
  failing.command = "echo shown; false";
  case =
    name: arguments:
    repository (
      {
        inherit name;
      }
      // arguments
    );
in
lib.mapAttrs case {
  passed = {
    command = check { inherit passing; };
    output = [ "ok    passing" ];
    # errexit ignores a failure under `!`, so the condition fails the build with `exit`.
    after = "if grep -q hidden \"$TMPDIR/output\"; then exit 1; fi";
  };
  # The failure of one check does not stop the others, and shows only its own output.
  failed = {
    command = check { inherit failing passing; };
    status = 1;
    output = [
      "FAIL  failing"
      "shown"
      "ok    passing"
    ];
    after = "if grep -q hidden \"$TMPDIR/output\"; then exit 1; fi";
  };
}
