{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.nixfmt ]) formatter;
  formatted = pkgs.writeText "formatted.nix" "{ a = 1; }\n";
  unformatted = pkgs.writeText "unformatted.nix" "{a=1;}\n";
  case =
    name: arguments:
    repository (
      {
        inherit name;
        before = "git add .";
        command = lib.getExe formatter;
      }
      // arguments
    );
in
lib.mapAttrs case {
  tracked = {
    files = {
      "file.nix" = unformatted;
      "directory/file.nix" = unformatted;
    };
    after = ''
      cmp file.nix ${formatted}
      cmp directory/file.nix ${formatted}
    '';
  };
  untracked = {
    files."file.nix" = unformatted;
    before = ''
      git add .
      cp ${unformatted} untracked.nix
    '';
    after = ''
      cmp file.nix ${formatted}
      cmp untracked.nix ${unformatted}
    '';
  };
  other-extension = {
    files = {
      "file.nix" = unformatted;
      "file.txt" = unformatted;
    };
    after = ''
      cmp file.nix ${formatted}
      cmp file.txt ${unformatted}
    '';
  };
  subdirectory = {
    files = {
      "file.nix" = unformatted;
      "directory/file.nix" = unformatted;
    };
    before = ''
      git add .
      cd directory
    '';
    after = ''
      cmp ../file.nix ${formatted}
      cmp file.nix ${formatted}
    '';
  };
  paths = {
    files = {
      "file.nix" = unformatted;
      "directory/file.nix" = unformatted;
      "other/file.nix" = unformatted;
    };
    arguments = [
      "file.nix"
      "directory"
    ];
    after = ''
      cmp file.nix ${formatted}
      cmp directory/file.nix ${formatted}
      cmp other/file.nix ${unformatted}
    '';
  };
  relative-paths = {
    files = {
      "file.nix" = unformatted;
      "directory/file.nix" = unformatted;
    };
    before = ''
      git add .
      cd directory
    '';
    arguments = [ "file.nix" ];
    after = ''
      cmp ../file.nix ${unformatted}
      cmp file.nix ${formatted}
    '';
  };
  no-nix-path = {
    files = {
      "file.nix" = unformatted;
      "file.txt" = unformatted;
    };
    arguments = [ "file.txt" ];
    after = ''
      cmp file.nix ${unformatted}
      cmp file.txt ${unformatted}
    '';
  };
}
