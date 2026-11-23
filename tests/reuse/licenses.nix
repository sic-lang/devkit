{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  spdx = "${pkgs.spdx-license-list-data.text}/text";
  inherit (consumer [ flakeModules.reuse ]) checks;
  annotation =
    {
      path ? "**",
      copyright ? "2026 The Sic Contributors",
      license ? "Apache-2.0",
    }:
    ''
      [[annotations]]
      path = ${builtins.toJSON path}
      SPDX-FileCopyrightText = ${builtins.toJSON copyright}
      SPDX-License-Identifier = ${builtins.toJSON license}
    '';
  reuseToml =
    annotations:
    pkgs.writeText "REUSE.toml" (
      lib.concatStringsSep "\n" ([ "version = 1\n" ] ++ map annotation annotations)
    );
  text = pkgs.writeText "text";
  other = text "Another text.\n";
  case =
    name:
    {
      command ? "check-licenses",
      licenses ? {
        "Apache-2.0.txt" = "${spdx}/Apache-2.0.txt";
      },
      reuse ? reuseToml [ { } ],
      files ? { },
      ...
    }@arguments:
    repository (
      removeAttrs arguments [
        "licenses"
        "reuse"
      ]
      // {
        inherit name;
        command = lib.getExe checks.${command};
        files = {
          README = text "A file under the licenses of REUSE.toml.\n";
        }
        // lib.mapAttrs' (file: lib.nameValuePair "LICENSES/${file}") licenses
        // lib.optionalAttrs (reuse != null) { "REUSE.toml" = reuse; }
        // files;
      }
    );
in
lib.mapAttrs case {
  check-apache = { };
  check-other-license = {
    licenses."MIT.txt" = "${spdx}/MIT.txt";
    reuse = reuseToml [ { license = "MIT"; } ];
  };
  check-other-annotations = {
    reuse = reuseToml [
      { }
      {
        path = "vendor/**";
        copyright = "2020 Someone else";
      }
      {
        path = [
          "a"
          "b/**"
        ];
      }
    ];
  };
  check-different-text = {
    licenses."Apache-2.0.txt" = other;
    status = 1;
    output = [ "LICENSES/Apache-2.0.txt differs from the SPDX text" ];
  };
  check-unknown-name = {
    licenses = {
      "Apache-2.0.txt" = "${spdx}/Apache-2.0.txt";
      "LicenseRef-Sic.txt" = other;
    };
    status = 1;
    output = [ "LICENSES/LicenseRef-Sic.txt is not the text of an SPDX license or exception" ];
  };
  check-no-reuse-toml = {
    reuse = null;
    status = 1;
    output = [ "REUSE.toml cannot be read" ];
  };
  check-two-annotations-of-every-file = {
    reuse = reuseToml [
      { }
      { }
    ];
    status = 1;
    output = [ "exactly one annotation whose path is" ];
  };
  check-path-as-list = {
    reuse = reuseToml [ { path = [ "**" ]; } ];
    status = 1;
    output = [ "exactly one annotation whose path is" ];
  };
  check-other-holder = {
    reuse = reuseToml [ { copyright = "2026 Someone else"; } ];
    status = 1;
    output = [ "<year> The Sic Contributors" ];
  };
  check-holder-with-more = {
    reuse = reuseToml [ { copyright = "2026 The Sic Contributors and others"; } ];
    status = 1;
    output = [ "<year> The Sic Contributors" ];
  };
  check-short-year = {
    reuse = reuseToml [ { copyright = "26 The Sic Contributors"; } ];
    status = 1;
    output = [ "<year> The Sic Contributors" ];
  };
  setup-writes = {
    command = "setup-licenses";
    licenses."Apache-2.0.txt" = other;
    reuse = reuseToml [ { license = "Apache-2.0 OR MIT"; } ];
    output = [
      "rewritten LICENSES/Apache-2.0.txt"
      "created LICENSES/MIT.txt"
    ];
    after = ''
      cmp LICENSES/Apache-2.0.txt ${spdx}/Apache-2.0.txt
      cmp LICENSES/MIT.txt ${spdx}/MIT.txt
      ${lib.getExe checks.check-licenses}
    '';
  };
  setup-keeps-custom = {
    command = "setup-licenses";
    licenses = {
      "Apache-2.0.txt" = "${spdx}/Apache-2.0.txt";
      "LicenseRef-Sic.txt" = other;
    };
    reuse = reuseToml [ { license = "Apache-2.0 OR LicenseRef-Other"; } ];
    status = 1;
    output = [
      "kept LICENSES/LicenseRef-Sic.txt"
      "no SPDX text of LicenseRef-Other"
    ];
    after = "cmp LICENSES/LicenseRef-Sic.txt ${other}";
  };
}
