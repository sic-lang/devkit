{ lib, ... }@args:
let
  helpers = import ../../libs/licenses.nix args;
  inherit (helpers)
    apache
    other
    reuseToml
    sic
    spdx
    text
    vendor
    ;
  case = helpers.case "check-licenses";
  # Split so that REUSE does not mistake these lines for this file's own tags.
  tags = ''
    SPDX-${""}FileCopyrightText: 2020 Someone else
    SPDX-${""}License-Identifier: Apache-2.0
  '';
in
lib.mapAttrs case {
  sic-license = { };
  third-party-license = vendor "MIT" // {
    licenses = sic // {
      "MIT.txt" = "${spdx}/MIT.txt";
    };
  };
  other-license = {
    licenses."MIT.txt" = "${spdx}/MIT.txt";
    reuse = reuseToml [ { license = "MIT"; } ];
    status = 1;
    output = [
      ''In REUSE.toml, the SPDX-License-Identifier of the "**" annotation must be''
      ''"Apache-2.0 WITH LLVM-exception", Sic's license''
    ];
  };
  no-exception = {
    licenses."Apache-2.0.txt" = apache;
    reuse = reuseToml [ { license = "Apache-2.0"; } ];
    status = 1;
    output = [ ''must be "Apache-2.0 WITH LLVM-exception", Sic's license'' ];
  };
  other-holder-and-license = {
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
  no-licenses-directory = {
    licenses = { };
    before = "[ ! -e LICENSES ]";
  };
  other-annotations = {
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
  different-text = {
    licenses = sic // {
      "Apache-2.0.txt" = other;
    };
    status = 1;
    output = [ "LICENSES/Apache-2.0.txt differs from the SPDX text" ];
  };
  unknown-name = {
    licenses = sic // {
      "Sic.txt" = other;
    };
    status = 1;
    output = [ "LICENSES/Sic.txt is not named <id>.txt, where <id> is a license" ];
  };
  custom-text = {
    licenses = sic // {
      "LicenseRef-Sic.txt" = other;
    };
    status = 1;
    output = [ "LICENSES/LicenseRef-Sic.txt is not named <id>.txt, where <id> is a license" ];
  };
  custom-license = vendor "LicenseRef-Sic" // {
    licenses = sic // {
      "LicenseRef-Sic.txt" = other;
    };
    status = 1;
    output = [ "LicenseRef-Sic is not a license or exception on the SPDX list" ];
  };
  custom-exception = vendor "Apache-2.0 WITH AdditionRef-Sic" // {
    licenses = sic // {
      "AdditionRef-Sic.txt" = other;
    };
    status = 1;
    output = [ "AdditionRef-Sic is not a license or exception on the SPDX list" ];
  };
  no-reuse-toml = {
    reuse = null;
    status = 1;
    output = [ "REUSE.toml cannot be read" ];
  };
  two-annotations-of-every-file = {
    reuse = reuseToml [
      { }
      { }
    ];
    status = 1;
    output = [ "exactly one annotation whose path is" ];
  };
  path-as-list = {
    reuse = reuseToml [ { path = [ "**" ]; } ];
    status = 1;
    output = [ "exactly one annotation whose path is" ];
  };
  other-holder = {
    reuse = reuseToml [ { copyright = "2026 Someone else"; } ];
    status = 1;
    output = [ "<year> The Sic Contributors" ];
  };
  holder-with-more = {
    reuse = reuseToml [ { copyright = "2026 The Sic Contributors and others"; } ];
    status = 1;
    output = [ "<year> The Sic Contributors" ];
  };
  short-year = {
    reuse = reuseToml [ { copyright = "26 The Sic Contributors"; } ];
    status = 1;
    output = [ "<year> The Sic Contributors" ];
  };
  file-header = {
    files.README = text tags;
    status = 1;
    output = [
      "README takes its copyright from README (file-header)"
      "README takes its license from README (file-header)"
    ];
  };
  dot-license = {
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
  misnamed-text = vendor "MIT" // {
    licenses = sic // {
      "MIT.md" = "${spdx}/MIT.txt";
    };
    status = 1;
    output = [ "LICENSES/MIT.md is not named <id>.txt, where <id> is a license" ];
  };
  unused-text = {
    command = "check-reuse";
    licenses = sic // {
      "MIT.txt" = "${spdx}/MIT.txt";
    };
    status = 1;
    output = [ "Unused licenses: MIT" ];
  };
}
