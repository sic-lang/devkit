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
      spdx = "${pkgs.spdx-license-list-data.text}/text";
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
            shopt -s nullglob
            for file in LICENSES/*; do
              name=''${file#LICENSES/}
              text=${spdx}/''${name%.txt}.txt
              if [ ! -e "$text" ]; then
                echo "$file is not the text of an SPDX license or exception" >&2
                status=1
              elif ! cmp -s "$file" "$text"; then
                diff -u "$file" "$text" || true
                echo "$file differs from the SPDX text above: setup-licenses rewrites it" >&2
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
        description = "Write to LICENSES/ the SPDX texts of the licenses that REUSE needs";
        command = config.devkit.mkCommand {
          name = "setup-licenses";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.diffutils
            pkgs.git
            pkgs.jq
            pkgs.reuse
          ];
          text = ''
            case "$*" in
            "" | --force) ;;
            *)
              echo "usage: setup-licenses [--force]" >&2
              exit 2
              ;;
            esac
            cd "$(git rev-parse --show-toplevel)"
            status=0
            shopt -s nullglob
            for file in LICENSES/*; do
              name=''${file#LICENSES/}
              text=${spdx}/''${name%.txt}.txt
              if [ ! -e "$text" ]; then
                echo "kept $file, which is not the text of an SPDX license or exception" >&2
                status=1
              elif cmp -s "$text" "$file"; then
                echo "up to date $file"
              else
                install -m 644 "$text" "$file"
                echo "rewritten $file"
              fi
            done
            report=$(reuse lint --json || true)
            if [ -z "$report" ]; then
              echo "reuse lint gave no report of the missing licenses" >&2
              exit 1
            fi
            for id in $(jq -r '.non_compliant.missing_licenses[]' <<<"$report"); do
              if [ -e "${spdx}/$id.txt" ]; then
                install -D -m 644 "${spdx}/$id.txt" "LICENSES/$id.txt"
                echo "created LICENSES/$id.txt"
              else
                echo "no SPDX text of $id: write LICENSES/$id.txt by hand" >&2
                status=1
              fi
            done
            exit "$status"
          '';
        };
      };
    };
}
