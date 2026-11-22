{
  imports = [
    ../checks
    ../setups
  ];

  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      texts = lib.mapAttrsToList (name: _: ./LICENSES + "/${name}") (builtins.readDir ./LICENSES);
      copyright = "2026 The Sic Contributors";
      license = "Apache-2.0 WITH LLVM-exception";
    in
    {
      devkit.checks = {
        reuse = {
          tools = [ pkgs.reuse ];
          command = "reuse lint";
        };
        licenses = {
          tools = [
            pkgs.diffutils
            pkgs.jq
            pkgs.taplo
          ];
          command = ''
            status=0
            for text in ${lib.concatStringsSep " " texts}; do
              name=''${text#*-}
              if ! diff -u "LICENSES/$name" "$text"; then
                echo "LICENSES/$name is not the text of devkit above:" \
                  "write it with setup-licenses, with --force over another text" >&2
                status=1
              fi
            done
            if ! taplo get -f REUSE.toml -o json | jq -e '
              any(
                .annotations[]?;
                .path == "**"
                and ."SPDX-FileCopyrightText" == "${copyright}"
                and ."SPDX-License-Identifier" == "${license}"
              )' >/dev/null; then
              echo 'REUSE.toml has no annotation path = "**"' \
                'with SPDX-FileCopyrightText = "${copyright}"' \
                'and SPDX-License-Identifier = "${license}"' >&2
              status=1
            fi
            exit "$status"
          '';
        };
      };

      devkit.setups.licenses = {
        description = "Write the license texts of devkit to LICENSES/";
        command = config.devkit.mkSetup {
          name = "setup-licenses";
          dir = "$(git rev-parse --show-toplevel)/LICENSES";
          mode = "644";
          sources = texts;
        };
      };
    };
}
