let
  shared = import ../../lib.nix;
in
{ flake-parts-lib, lib, ... }:
{
  imports = [ ../files ];

  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      inherit (config.devkit.formats) yaml;
      inherit (config.devkit.yaml) settings;
    in
    {
      options.devkit.yaml.settings = lib.mkOption {
        description = ''
          The repository's yamllint configuration, which the module writes to `.yamllint.yaml`
          with devkit's own settings.
        '';
        type = yaml.type;
        default = { };
      };

      config.devkit = {
        yaml.settings = {
          extends = "default";
          rules = {
            # Workflows do not start with "---" by convention.
            document-start = "disable";
            # So that YAML files indent like the other files.
            indentation.spaces = shared.indentSize;
            # So that YAML files wrap at the same length as the other files that have a limit.
            # A value without spaces cannot wrap, so it may go past the limit after its key.
            line-length = {
              max = shared.lineLength;
              allow-non-breakable-inline-mappings = true;
            };
            # Workflows use the "on" key for their triggers.
            truthy.check-keys = false;
          };
        };
        files.".yamllint.yaml".source = yaml.generate "yamllint.yaml" settings;
        # Given a directory, yamllint also checks the files that Git does not track.
        checks.yamllint = (import ../checks/tracked-files.nix pkgs).check {
          pathspecs = [
            "*.yaml"
            "*.yml"
          ];
          command = "yamllint --strict";
          packages = [ pkgs.yamllint ];
        };
      };
    }
  );
}
