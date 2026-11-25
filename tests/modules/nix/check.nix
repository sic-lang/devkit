{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.nix ]) apps;
  formatted = pkgs.writeText "formatted.nix" "{ a = 1; }\n";
  unformatted = pkgs.writeText "unformatted.nix" "{a=1;}\n";
  failure = import ../../libs/xargs-failure.nix;
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
    status = failure;
    output = [ "file.nix: not formatted" ];
  };
  nested-unformatted = {
    files."directory/file.nix" = unformatted;
    status = failure;
    output = [ "directory/file.nix: not formatted" ];
  };
  space-in-name.files."a file.nix" = formatted;
  dash-name = {
    files."-x.nix" = unformatted;
    status = failure;
    output = [ "-x.nix: not formatted" ];
  };
  # A UTF-8 locale, under which a name that is not valid UTF-8 is not text.
  latin-1-name = {
    files."file.nix" = formatted;
    before = ''
      export LC_ALL=C.UTF-8
      cp ${unformatted} "$(printf 'caf\351.nix')"
      git add .
    '';
    # nixfmt 1.5.0 fails to print such a name, so the output does not name the file.
    status = failure;
  };
  untracked = {
    files."file.nix" = formatted;
    before = ''
      git add .
      cp ${unformatted} untracked.nix
    '';
  };
  no-nix-file = import ../../libs/no-file.nix // {
    files."file.txt" = formatted;
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
