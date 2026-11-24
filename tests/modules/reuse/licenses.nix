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
  apache = "${spdx}/Apache-2.0.txt";
  llvm = "${spdx}/LLVM-exception.txt";
  # The texts of Sic's license, which the "**" annotation must carry.
  sic = {
    "Apache-2.0.txt" = apache;
    "LLVM-exception.txt" = llvm;
  };
  inherit (consumer [ flakeModules.reuse ]) apps;
  annotation =
    {
      path ? "**",
      copyright ? "2026 The Sic Contributors",
      license ? "Apache-2.0 WITH LLVM-exception",
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
  # A third-party file, whose annotation follows the "**" one and may carry any license.
  vendor = license: {
    files."vendor/file" = text "A third-party file.\n";
    reuse = reuseToml [
      { }
      {
        path = "vendor/**";
        copyright = "2020 Someone else";
        inherit license;
      }
    ];
  };
  other = text "Another text.\n";
  checked = lib.concatMapStrings (check: "${apps.${check}.program}\n") [
    "check-licenses"
    "check-reuse"
  ];
  # Split so that REUSE does not mistake these lines for this file's own tags.
  tags = ''
    SPDX-${""}FileCopyrightText: 2020 Someone else
    SPDX-${""}License-Identifier: Apache-2.0
  '';
  case =
    name:
    {
      command ? "check-licenses",
      licenses ? sic,
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
        command = apps.${command}.program;
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
  check-sic-license = { };
  check-third-party-license = vendor "MIT" // {
    licenses = sic // {
      "MIT.txt" = "${spdx}/MIT.txt";
    };
  };
  check-other-license = {
    licenses."MIT.txt" = "${spdx}/MIT.txt";
    reuse = reuseToml [ { license = "MIT"; } ];
    status = 1;
    output = [
      ''In REUSE.toml, the SPDX-License-Identifier of the "**" annotation must be "Apache-2.0 WITH LLVM-exception", Sic's license''
    ];
  };
  check-no-exception = {
    licenses."Apache-2.0.txt" = apache;
    reuse = reuseToml [ { license = "Apache-2.0"; } ];
    status = 1;
    output = [ ''must be "Apache-2.0 WITH LLVM-exception", Sic's license'' ];
  };
  check-other-holder-and-license = {
    reuse = reuseToml [
      {
        copyright = "2026 Someone else";
        license = "MIT";
      }
    ];
    licenses."MIT.txt" = "${spdx}/MIT.txt";
    status = 1;
    output = [
      "<year> The Sic Contributors"
      "Sic's license"
    ];
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
    licenses = sic // {
      "Apache-2.0.txt" = other;
    };
    status = 1;
    output = [ "LICENSES/Apache-2.0.txt differs from the SPDX text" ];
  };
  check-unknown-name = {
    licenses = sic // {
      "Sic.txt" = other;
    };
    status = 1;
    output = [ "LICENSES/Sic.txt is not named <id>.txt, where <id> is a license" ];
  };
  check-custom-text = {
    licenses = sic // {
      "LicenseRef-Sic.txt" = other;
    };
    status = 1;
    output = [ "LICENSES/LicenseRef-Sic.txt is not named <id>.txt, where <id> is a license" ];
  };
  check-custom-license = vendor "LicenseRef-Sic" // {
    licenses = sic // {
      "LicenseRef-Sic.txt" = other;
    };
    status = 1;
    output = [ "LicenseRef-Sic is not a license or exception on the SPDX list" ];
  };
  check-custom-exception = vendor "Apache-2.0 WITH AdditionRef-Sic" // {
    licenses = sic // {
      "AdditionRef-Sic.txt" = other;
    };
    status = 1;
    output = [ "AdditionRef-Sic is not a license or exception on the SPDX list" ];
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
  check-misnamed-text = vendor "MIT" // {
    licenses = sic // {
      "MIT.md" = "${spdx}/MIT.txt";
    };
    status = 1;
    output = [ "LICENSES/MIT.md is not named <id>.txt, where <id> is a license" ];
  };
  check-unused-text = {
    command = "check-reuse";
    licenses = sic // {
      "MIT.txt" = "${spdx}/MIT.txt";
    };
    status = 1;
    output = [ "Unused licenses: MIT" ];
  };
  setup-removes-unused = {
    command = "setup-licenses";
    licenses = sic // {
      "MIT.txt" = "${spdx}/MIT.txt";
    };
    output = [ "removed LICENSES/MIT.txt, which no file uses" ];
    after = ''
      [ ! -e LICENSES/MIT.txt ]
      ${checked}
    '';
  };
  setup-writes = vendor "MIT" // {
    command = "setup-licenses";
    licenses."Apache-2.0.txt" = other;
    output = [
      "rewritten LICENSES/Apache-2.0.txt"
      "created LICENSES/LLVM-exception.txt"
      "created LICENSES/MIT.txt"
    ];
    after = ''
      cmp LICENSES/Apache-2.0.txt ${apache}
      cmp LICENSES/LLVM-exception.txt ${llvm}
      cmp LICENSES/MIT.txt ${spdx}/MIT.txt
      ${checked}
    '';
  };
  setup-no-licenses-directory = {
    command = "setup-licenses";
    licenses = { };
    output = [
      "created LICENSES/Apache-2.0.txt"
      "created LICENSES/LLVM-exception.txt"
    ];
    after = checked;
  };
  setup-twice = vendor "MIT" // {
    command = "setup-licenses";
    licenses = {
      "Apache-2.0.txt" = other;
      "ISC.txt" = "${spdx}/ISC.txt";
    };
    before = ''
      ${apps.setup-licenses.program}
      find LICENSES -type f -exec sha256sum {} + | sort >"$TMPDIR/first"
    '';
    output = [
      "up to date LICENSES/Apache-2.0.txt"
      "up to date LICENSES/LLVM-exception.txt"
      "up to date LICENSES/MIT.txt"
    ];
    after = ''
      find LICENSES -type f -exec sha256sum {} + | sort | cmp - "$TMPDIR/first"
      if grep -qE "^(rewritten|created|removed)" "$TMPDIR/output"; then
        exit 1
      fi
    '';
  };
  setup-keeps-custom-text = vendor "LicenseRef-Sic" // {
    command = "setup-licenses";
    licenses = sic // {
      "LicenseRef-Sic.txt" = other;
    };
    status = 1;
    output = [ "LICENSES/LicenseRef-Sic.txt is not named <id>.txt, where <id> is a license" ];
    after = "cmp LICENSES/LicenseRef-Sic.txt ${other}";
  };
  setup-keeps-unused-custom-text = {
    command = "setup-licenses";
    licenses = sic // {
      "LicenseRef-Sic.txt" = other;
    };
    status = 1;
    output = [
      "LICENSES/LicenseRef-Sic.txt is not named <id>.txt, where <id> is a license"
      "kept the unused text of LicenseRef-Sic, because it is not an SPDX text"
    ];
    after = "cmp LICENSES/LicenseRef-Sic.txt ${other}";
  };
  setup-keeps-unused-misnamed-text = {
    command = "setup-licenses";
    licenses = sic // {
      "MIT.md" = "${spdx}/MIT.txt";
    };
    status = 1;
    output = [
      "LICENSES/MIT.md is not named <id>.txt, where <id> is a license"
      "kept the unused text of MIT, because it is not an SPDX text at LICENSES/MIT.txt"
    ];
    after = "cmp LICENSES/MIT.md ${spdx}/MIT.txt";
  };
  setup-reports-custom-license = vendor "LicenseRef-Other" // {
    command = "setup-licenses";
    status = 1;
    output = [ "LicenseRef-Other is not a license or exception on the SPDX list" ];
  };
}
