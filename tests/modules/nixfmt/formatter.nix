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
  # nixfmt leaves a file that is not a Nix file as it is, but warns that it is deprecated.
  notGivenOtherFiles = ''
    if grep -qF deprecated "$TMPDIR/output"; then exit 1; fi
  '';
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
      ${notGivenOtherFiles}
    '';
  };
  dash-name = {
    files = {
      "-x.nix" = unformatted;
      "directory/-y.nix" = unformatted;
    };
    after = ''
      cmp ./-x.nix ${formatted}
      cmp directory/-y.nix ${formatted}
    '';
  };
  dash-name-in-subdirectory = {
    files."directory/-y.nix" = unformatted;
    before = ''
      git add .
      cd directory
    '';
    arguments = [ "-y.nix" ];
    after = "cmp ./-y.nix ${formatted}";
  };
  # A UTF-8 locale, under which a name that is not valid UTF-8 is not text.
  latin-1-name = {
    files."file.nix" = unformatted;
    before = ''
      export LC_ALL=C.UTF-8
      cp ${unformatted} "$(printf 'caf\351.nix')"
      git add .
    '';
    after = ''
      cmp file.nix ${formatted}
      cmp "$(printf 'caf\351.nix')" ${formatted}
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
  literal-path = {
    files = {
      "g[1].nix" = unformatted;
      "g1.nix" = unformatted;
    };
    arguments = [ "g[1].nix" ];
    after = ''
      cmp 'g[1].nix' ${formatted}
      cmp g1.nix ${unformatted}
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
      ${notGivenOtherFiles}
    '';
  };
}
