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
      inherit (import ../../lib.nix) copyrightHolder license;
      # The jq module reuse, for the reports of reuse lint and the annotations of REUSE.toml.
      jq = pkgs.writeTextDir "reuse.jq" ''
        def everything:
          [
            .annotations[]?
            | select(.path == "**" or (.path | type == "array" and any(.[]; . == "**")))
          ];

        def custom:
          [
            .files[].spdx_expressions[].value
            | scan("(?:LicenseRef|AdditionRef)-[A-Za-z0-9.-]+")
          ]
          | unique[];

        def outside:
          .files[]
          | [.path]
            + (
              (.copyrights[] | ["copyright", .source, .source_type]),
              (.spdx_expressions[] | ["license", .source, .source_type])
            )
          | select(.[3] != "reuse-toml")
          | "\(.[0]) takes its \(.[1]) from \(.[2]) (\(.[3]))";
      '';
      # The start of the check and of the setup: the texts of LICENSES/ and their SPDX texts, and
      # the report of reuse lint.
      common = ''
        spdx="${spdx}"
        spdx_only="a license or exception on the SPDX list, the only ones a repository may use"
        status=0

        licenses=()
        texts=()
        shopt -s nullglob
        for file in LICENSES/*; do
          name=''${file#LICENSES/}
          text=$spdx/''${name%.txt}.txt
          if [ -e "$text" ]; then
            licenses+=("$file")
            texts+=("$text")
          else
            echo "$file is not named <id>.txt, where <id> is $spdx_only" >&2
            status=1
          fi
        done
        shopt -u nullglob

        lint() {
          report=$(reuse lint --json || true)
          if [ -z "$report" ]; then
            echo "reuse lint gave no report" >&2
            exit 1
          fi
        }
      '';
    in
    {
      devkit.checks = {
        reuse = {
          packages = [ pkgs.reuse ];
          command = "reuse lint";
        };
        licenses.command = config.devkit.mkCommand {
          name = "check-licenses";
          packages = [
            pkgs.diffutils
            pkgs.jq
            pkgs.reuse
            pkgs.taplo
          ];
          text = common + ''

            license="${license}"
            holder="${copyrightHolder}"

            for i in "''${!licenses[@]}"; do
              if ! cmp -s "''${licenses[$i]}" "''${texts[$i]}"; then
                diff -u "''${licenses[$i]}" "''${texts[$i]}" || true
                echo "''${licenses[$i]} differs from the SPDX text above: run setup-licenses to" \
                  "rewrite it" >&2
                status=1
              fi
            done

            reuse_jq() {
              jq -L "${jq}" "$@"
            }

            if ! toml=$(taplo get -f REUSE.toml -o json); then
              echo "REUSE.toml cannot be read" >&2
              exit 1
            fi
            if ! reuse_jq -e 'include "reuse"; everything | length == 1 and .[0].path == "**"' \
              <<<"$toml" >/dev/null; then
              echo 'REUSE.toml must have exactly one annotation whose path is the string "**",' \
                'because REUSE applies the last annotation that matches a file' >&2
              status=1
            else
              # jq reads the holder from the environment, so that its filter stays a literal string.
              if ! holder="$holder" reuse_jq -e '
                include "reuse";
                everything
                | .[0]."SPDX-FileCopyrightText"
                | type == "string" and test("^[0-9]{4} ") and .[5:] == env.holder
              ' <<<"$toml" >/dev/null; then
                echo 'In REUSE.toml, the SPDX-FileCopyrightText of the "**" annotation must be' \
                  "\"<year> $holder\"" >&2
                status=1
              fi
              identifier=$(
                reuse_jq -r 'include "reuse"; everything | .[0]."SPDX-License-Identifier"' \
                  <<<"$toml"
              )
              if [ "$identifier" != "$license" ]; then
                echo "In REUSE.toml, the SPDX-License-Identifier of the \"**\" annotation must be" \
                  "\"$license\", Sic's license" >&2
                status=1
              fi
            fi

            lint
            for id in $(reuse_jq -r 'include "reuse"; custom' <<<"$report"); do
              echo "$id is not $spdx_only" >&2
              status=1
            done
            outside=$(reuse_jq -r 'include "reuse"; outside' <<<"$report")
            if [ -n "$outside" ]; then
              echo "$outside" >&2
              echo "Every copyright and license must come from REUSE.toml: move those above into" \
                "an annotation in REUSE.toml" >&2
              status=1
            fi
            exit "$status"
          '';
        };
      };

      devkit.setups.licenses = {
        description = "Make LICENSES/ hold exactly the SPDX texts of the licenses that REUSE needs";
        command = config.devkit.mkCommand {
          name = "setup-licenses";
          packages = [
            pkgs.diffutils
            pkgs.jq
            pkgs.reuse
          ];
          # --force has no effect, because an SPDX text is never merged by hand.
          # It is still accepted, because the setup app passes its arguments to every setup.
          text = common + ''

            case "$*" in
            "" | --force) ;;
            *)
              echo "usage: setup-licenses [--force]" >&2
              exit 2
              ;;
            esac

            for i in "''${!licenses[@]}"; do
              if cmp -s "''${texts[$i]}" "''${licenses[$i]}"; then
                echo "up to date ''${licenses[$i]}"
              else
                install -m 644 "''${texts[$i]}" "''${licenses[$i]}"
                echo "rewritten ''${licenses[$i]}"
              fi
            done

            lint
            for id in $(jq -r '.non_compliant.missing_licenses[]' <<<"$report"); do
              if [ -e "$spdx/$id.txt" ]; then
                install -D -m 644 "$spdx/$id.txt" "LICENSES/$id.txt"
                echo "created LICENSES/$id.txt"
              else
                echo "$id is not $spdx_only" >&2
                status=1
              fi
            done
            for id in $(jq -r '.non_compliant.unused_licenses[]' <<<"$report"); do
              if [ -e "$spdx/$id.txt" ] && [ -e "LICENSES/$id.txt" ]; then
                rm "LICENSES/$id.txt"
                echo "removed LICENSES/$id.txt, which no file uses"
              else
                echo "kept the unused text of $id, because it is not an SPDX text at" \
                  "LICENSES/$id.txt" >&2
              fi
            done
            exit "$status"
          '';
        };
      };
    };
}
