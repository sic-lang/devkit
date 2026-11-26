let
  shared = import ../../lib.nix;
in
{ flake-parts-lib, lib, ... }:
{
  imports = [ ../files ];

  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      inherit (config.devkit.editorconfig) settings;
      # Spaces around "=", as in the examples of EditorConfig.
      ini = pkgs.formats.iniWithGlobalSection {
        mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
      };
      unset = {
        indent_size = "unset";
        max_line_length = "unset";
      };
    in
    {
      options.devkit.editorconfig.settings = lib.mkOption {
        description = ''
          The repository's EditorConfig, which the module writes to `.editorconfig` with devkit's
          own settings. A section comes after those whose names sort before its own, so a section
          that overrides another one needs a name that sorts after it.
        '';
        type = ini.type;
        default = { };
      };

      config.devkit = {
        editorconfig.settings = {
          globalSection.root = true;
          sections = {
            "*" = {
              charset = "utf-8";
              end_of_line = "lf";
              indent_size = shared.indentSize;
              indent_style = "space";
              insert_final_newline = true;
              # So that every repository wraps at the same length.
              max_line_length = shared.lineLength;
              trim_trailing_whitespace = true;
            };
            # Markdown continues ordered list items with 3 spaces, and puts one sentence on each
            # line.
            "*.md" = unset;
            # The yaml module checks the line length of YAML files, and allows words that cannot be
            # broken.
            "*.{yaml,yml}".max_line_length = "unset";
            # License texts are verbatim copies, with their own indentation and line breaks.
            "LICENSES/*" = unset;
          };
        };
        files.".editorconfig".source = ini.generate "editorconfig" settings;
        # Without files, editorconfig-checker also checks the files that Git does not track.
        checks.editorconfig = (import ../checks/tracked-files.nix pkgs).check {
          command = "editorconfig-checker";
          packages = [ pkgs.editorconfig-checker ];
        };
      };
    }
  );
}
