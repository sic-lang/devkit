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
      eachText = body: ''
        shopt -s nullglob
        for file in LICENSES/*; do
          name=''${file#LICENSES/}
          text=${spdx}/''${name%.txt}.txt
          if [ ! -e "$text" ]; then
            echo "$file is not the text of an SPDX license or exception" >&2
            status=1
          else
            ${body}
          fi
        done
      '';
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
            ${eachText ''
              if ! cmp -s "$file" "$text"; then
                diff -u "$file" "$text" || true
                echo "$file differs from the SPDX text above: setup-licenses rewrites it" >&2
                status=1
              fi
            ''}
            if ! reuse=$(taplo get -f REUSE.toml -o json); then
              echo "REUSE.toml cannot be read" >&2
              exit 1
            fi
            everything='[
              .annotations[]?
              | select(.path == "**" or (.path | type == "array" and any(.[]; . == "**")))
            ]'
            if ! jq -e "$everything"' | length == 1 and .[0].path == "**"' <<<"$reuse" \
              >/dev/null; then
              echo 'REUSE.toml must have exactly one annotation whose path is "**", as a string,' \
                'since REUSE applies the last annotation that matches a file' >&2
              status=1
            elif ! jq -e "$everything"'
              | .[0]."SPDX-FileCopyrightText"
              | type == "string" and test("^[0-9]{4} The Sic Contributors$")
            ' <<<"$reuse" >/dev/null; then
              echo 'The SPDX-FileCopyrightText of the annotation "**" of REUSE.toml must be' \
                '"<year> The Sic Contributors"' >&2
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
            # --force has no effect, since a text of SPDX is never merged by hand, but is accepted,
            # since the app setup passes its arguments to every setup.
            case "$*" in
            "" | --force) ;;
            *)
              echo "usage: setup-licenses [--force]" >&2
              exit 2
              ;;
            esac
            cd "$(git rev-parse --show-toplevel)"
            status=0
            ${eachText ''
              if cmp -s "$text" "$file"; then
                echo "up to date $file"
              else
                install -m 644 "$text" "$file"
                echo "rewritten $file"
              fi
            ''}
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
