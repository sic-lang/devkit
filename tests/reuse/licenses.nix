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
  # Split, so that REUSE does not take these lines of this file for its own.
  tags = ''
    SPDX-${""}FileCopyrightText: 2020 Someone else
    SPDX-${""}License-Identifier: Apache-2.0
  '';
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
  check-with-exception = {
    licenses = {
      "Apache-2.0.txt" = "${spdx}/Apache-2.0.txt";
      "LLVM-exception.txt" = "${spdx}/LLVM-exception.txt";
    };
    reuse = reuseToml [ { license = "Apache-2.0 WITH LLVM-exception"; } ];
  };
  check-no-licenses-directory = {
    licenses = { };
    before = "[ ! -e LICENSES ]";
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
      "Sic.txt" = other;
    };
    status = 1;
    output = [ "LICENSES/Sic.txt is not the text of a license or exception of the SPDX list" ];
  };
  check-custom-text = {
    licenses = {
      "Apache-2.0.txt" = "${spdx}/Apache-2.0.txt";
      "LicenseRef-Sic.txt" = other;
    };
    status = 1;
    output = [ "LICENSES/LicenseRef-Sic.txt is not the text of a license or exception" ];
  };
  check-custom-license = {
    licenses = {
      "Apache-2.0.txt" = "${spdx}/Apache-2.0.txt";
      "LicenseRef-Sic.txt" = other;
    };
    reuse = reuseToml [ { license = "Apache-2.0 OR LicenseRef-Sic"; } ];
    status = 1;
    output = [ "LicenseRef-Sic is not a license or exception of the SPDX list" ];
  };
  check-custom-exception = {
    licenses = {
      "Apache-2.0.txt" = "${spdx}/Apache-2.0.txt";
      "AdditionRef-Sic.txt" = other;
    };
    reuse = reuseToml [ { license = "Apache-2.0 WITH AdditionRef-Sic"; } ];
    status = 1;
    output = [ "AdditionRef-Sic is not a license or exception of the SPDX list" ];
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
  check-file-header = {
    files.README = text tags;
    status = 1;
    output = [
      "README takes its copyright from README (file-header)"
      "README takes its license from README (file-header)"
    ];
  };
  check-dot-license = {
    files = {
      "data.bin" = text "Data.\n";
      "data.bin.license" = text tags;
    };
    status = 1;
    output = [
      "data.bin takes its copyright from data.bin.license (dot-license)"
      "data.bin takes its license from data.bin.license (dot-license)"
    ];
  };
  check-unused-text = {
    command = "check-reuse";
    licenses = {
      "Apache-2.0.txt" = "${spdx}/Apache-2.0.txt";
      "MIT.txt" = "${spdx}/MIT.txt";
    };
    status = 1;
    output = [ "Unused licenses: MIT" ];
  };
  setup-removes-unused = {
    command = "setup-licenses";
    licenses = {
      "Apache-2.0.txt" = "${spdx}/Apache-2.0.txt";
      "MIT.txt" = "${spdx}/MIT.txt";
    };
    output = [ "removed LICENSES/MIT.txt, which no file uses" ];
    after = ''
      [ ! -e LICENSES/MIT.txt ]
      ${lib.getExe checks.check-reuse}
    '';
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
  setup-with-exception = {
    command = "setup-licenses";
    reuse = reuseToml [ { license = "Apache-2.0 WITH LLVM-exception"; } ];
    output = [ "created LICENSES/LLVM-exception.txt" ];
    after = "cmp LICENSES/LLVM-exception.txt ${spdx}/LLVM-exception.txt";
  };
  setup-no-licenses-directory = {
    command = "setup-licenses";
    licenses = { };
    output = [ "created LICENSES/Apache-2.0.txt" ];
    after = lib.getExe checks.check-reuse;
  };
  setup-twice = {
    command = "setup-licenses";
    licenses = {
      "Apache-2.0.txt" = other;
      "ISC.txt" = "${spdx}/ISC.txt";
    };
    reuse = reuseToml [ { license = "Apache-2.0 OR MIT"; } ];
    before = ''
      ${lib.getExe checks.setup-licenses}
      find LICENSES -type f -exec sha256sum {} + | sort >"$TMPDIR/first"
    '';
    output = [
      "up to date LICENSES/Apache-2.0.txt"
      "up to date LICENSES/MIT.txt"
    ];
    after = ''
      find LICENSES -type f -exec sha256sum {} + | sort | cmp - "$TMPDIR/first"
      if grep -qE "^(rewritten|created|removed)" "$TMPDIR/output"; then
        exit 1
      fi
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
      "LICENSES/LicenseRef-Sic.txt is not the text of a license or exception of the SPDX list"
      "LicenseRef-Other is not a license or exception of the SPDX list"
      "kept the unused text of LicenseRef-Sic"
    ];
    after = "cmp LICENSES/LicenseRef-Sic.txt ${other}";
  };
}
