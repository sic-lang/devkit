{ lib, ... }@args:
let
  helpers = import ./lib args;
  inherit (helpers)
    apache
    apps
    llvm
    other
    sic
    spdx
    vendor
    ;
  case = helpers.case "setup-licenses";
  checked = lib.concatMapStrings (check: "${apps.${check}.program}\n") [
    "check-licenses"
    "check-reuse"
  ];
in
lib.mapAttrs case {
  removes-unused = {
    licenses = sic // {
      "MIT.txt" = "${spdx}/MIT.txt";
    };
    output = [ "removed LICENSES/MIT.txt, which no file uses" ];
    after = ''
      [ ! -e LICENSES/MIT.txt ]
      ${checked}
    '';
  };
  writes = vendor "MIT" // {
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
  no-licenses-directory = {
    licenses = { };
    output = [
      "created LICENSES/Apache-2.0.txt"
      "created LICENSES/LLVM-exception.txt"
    ];
    after = checked;
  };
  twice = vendor "MIT" // {
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
  keeps-custom-text = vendor "LicenseRef-Sic" // {
    licenses = sic // {
      "LicenseRef-Sic.txt" = other;
    };
    status = 1;
    output = [ "LICENSES/LicenseRef-Sic.txt is not named <id>.txt, where <id> is a license" ];
    after = "cmp LICENSES/LicenseRef-Sic.txt ${other}";
  };
  keeps-unused-custom-text = {
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
  keeps-unused-misnamed-text = {
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
  reports-custom-license = vendor "LicenseRef-Other" // {
    status = 1;
    output = [ "LicenseRef-Other is not a license or exception on the SPDX list" ];
  };
}
