{
  consumer,
  flakeModules,
  lib,
  pkgs,
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
    annotations: lib.concatStringsSep "\n" ([ "version = 1\n" ] ++ map annotation annotations);
  # A repository with a file, the texts licenses, named after their files, and the REUSE.toml reuse,
  # in which the command, a check or a setup, succeeds, or fails with a message that contains
  # error; then the script after runs in it.
  test =
    {
      command,
      licenses ? {
        "Apache-2.0.txt" = "${spdx}/Apache-2.0.txt";
      },
      reuse ? reuseToml [ { } ],
      error ? null,
      after ? "",
    }:
    pkgs.runCommand "test" { nativeBuildInputs = [ pkgs.git ]; } ''
      export HOME=$TMPDIR
      mkdir repository
      cd repository
      git init -q
      echo "A file under the licenses of REUSE.toml." >README
      mkdir LICENSES
      ${lib.concatStrings (
        lib.mapAttrsToList (name: text: "cp ${text} LICENSES/${lib.escapeShellArg name}\n") licenses
      )}
      ${lib.optionalString (reuse != null) "cp ${pkgs.writeText "REUSE.toml" reuse} REUSE.toml"}
      if ${lib.getExe checks.${command}} >"$TMPDIR/output" 2>&1; then
        succeeded=true
      else
        succeeded=false
      fi
      cat "$TMPDIR/output"
      ${
        if error == null then
          "$succeeded"
        else
          ''
            if "$succeeded"; then
              exit 1
            fi
            grep -qF ${lib.escapeShellArg error} "$TMPDIR/output"
          ''
      }
      ${after}
      touch "$out"
    '';
  check = args: test ({ command = "check-licenses"; } // args);
  setup = args: test ({ command = "setup-licenses"; } // args);
  other = pkgs.writeText "other" "Another text.\n";
in
{
  check-apache = check { };
  check-other-license = check {
    licenses."MIT.txt" = "${spdx}/MIT.txt";
    reuse = reuseToml [ { license = "MIT"; } ];
  };
  check-other-annotations = check {
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
  check-different-text = check {
    licenses."Apache-2.0.txt" = other;
    error = "LICENSES/Apache-2.0.txt differs from the SPDX text";
  };
  check-unknown-name = check {
    licenses = {
      "Apache-2.0.txt" = "${spdx}/Apache-2.0.txt";
      "LicenseRef-Sic.txt" = other;
    };
    error = "LICENSES/LicenseRef-Sic.txt is not the text of an SPDX license or exception";
  };
  check-no-reuse-toml = check {
    reuse = null;
    error = "REUSE.toml cannot be read";
  };
  check-two-annotations-of-every-file = check {
    reuse = reuseToml [
      { }
      { }
    ];
    error = "exactly one annotation whose path is";
  };
  check-path-as-list = check {
    reuse = reuseToml [ { path = [ "**" ]; } ];
    error = "exactly one annotation whose path is";
  };
  check-other-holder = check {
    reuse = reuseToml [ { copyright = "2026 Someone else"; } ];
    error = "<year> The Sic Contributors";
  };
  check-holder-with-more = check {
    reuse = reuseToml [ { copyright = "2026 The Sic Contributors and others"; } ];
    error = "<year> The Sic Contributors";
  };
  check-short-year = check {
    reuse = reuseToml [ { copyright = "26 The Sic Contributors"; } ];
    error = "<year> The Sic Contributors";
  };
  setup-writes = setup {
    licenses."Apache-2.0.txt" = other;
    reuse = reuseToml [ { license = "Apache-2.0 OR MIT"; } ];
    after = ''
      cmp LICENSES/Apache-2.0.txt ${spdx}/Apache-2.0.txt
      cmp LICENSES/MIT.txt ${spdx}/MIT.txt
      ${lib.getExe checks.check-licenses}
    '';
  };
  setup-keeps-custom = setup {
    licenses = {
      "Apache-2.0.txt" = "${spdx}/Apache-2.0.txt";
      "LicenseRef-Sic.txt" = other;
    };
    reuse = reuseToml [ { license = "Apache-2.0 OR LicenseRef-Other"; } ];
    error = "no SPDX text of LicenseRef-Other";
    after = ''
      grep -qF "kept LICENSES/LicenseRef-Sic.txt" "$TMPDIR/output"
      cmp LICENSES/LicenseRef-Sic.txt ${other}
    '';
  };
}
