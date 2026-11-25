{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
rec {
  spdx = "${pkgs.spdx-license-list-data.text}/text";
  apache = "${spdx}/Apache-2.0.txt";
  llvm = "${spdx}/LLVM-exception.txt";
  # The texts of Sic's license, which the "**" annotation must carry.
  sic = {
    "Apache-2.0.txt" = apache;
    "LLVM-exception.txt" = llvm;
  };
  inherit (consumer [ flakeModules.licenses ]) apps;
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
  # A case runs the given command, unless it names another.
  case =
    default: name:
    {
      command ? default,
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
}
