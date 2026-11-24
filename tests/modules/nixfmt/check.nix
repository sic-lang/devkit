{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.nixfmt ]) apps;
  formatted = pkgs.writeText "formatted.nix" "{ a = 1; }\n";
  unformatted = pkgs.writeText "unformatted.nix" "{a=1;}\n";
  case =
    name: arguments:
    repository (
      {
        inherit name;
        before = "git add .";
        command = apps.check-nixfmt.program;
      }
      // arguments
    );
in
lib.mapAttrs case {
  formatted.files."file.nix" = formatted;
  unformatted = {
    files."file.nix" = unformatted;
    status = 123;
    output = [ "file.nix: not formatted" ];
  };
  nested-unformatted = {
    files."directory/file.nix" = unformatted;
    status = 123;
    output = [ "directory/file.nix: not formatted" ];
  };
  space-in-name.files."a file.nix" = formatted;
  untracked = {
    files."file.nix" = formatted;
    before = ''
      git add .
      cp ${unformatted} untracked.nix
    '';
  };
  other-extension = {
    files = {
      "file.nix" = formatted;
      "file.txt" = unformatted;
    };
    after = ''
      if grep -qF file.txt "$TMPDIR/output"; then exit 1; fi
    '';
  };
}
