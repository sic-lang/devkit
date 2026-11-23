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
      jq = toString (
        lib.fileset.toSource {
          root = ./.;
          fileset = ./reuse.jq;
        }
      );
      template =
        name:
        pkgs.concatText "${name}.sh.in" [
          ./common.sh.in
          ./${name}.sh.in
        ];
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
            pkgs.reuse
            pkgs.taplo
          ];
          template = template "check";
          replacements = { inherit jq spdx; };
        };
      };

      devkit.setups.licenses = {
        description = "Make LICENSES/ the SPDX texts of the licenses that REUSE needs";
        command = config.devkit.mkCommand {
          name = "setup-licenses";
          template = template "setup";
          tools = [
            pkgs.diffutils
            pkgs.git
            pkgs.jq
            pkgs.reuse
          ];
          replacements = { inherit spdx; };
        };
      };
    };
}
