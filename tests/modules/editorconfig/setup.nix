{
  consumer,
  flakeModules,
  pkgs,
  repository,
  ...
}:
let
  setup = modules: (consumer modules).apps.setup-files.program;
  # The sections of devkit, after the global root.
  devkit = ''
    root = true

    [*]
    charset = utf-8
    end_of_line = lf
    indent_size = 2
    indent_style = space
    insert_final_newline = true
    max_line_length = 100
    trim_trailing_whitespace = true

    [*.md]
    indent_size = unset
    max_line_length = unset

    [*.{yaml,yml}]
    max_line_length = unset

    [LICENSES/*]
    indent_size = unset
    max_line_length = unset
  '';
  written = text: "cmp ${pkgs.writeText "editorconfig" text} .editorconfig";
in
{
  writes = repository {
    name = "writes";
    command = setup [ flakeModules.editorconfig ];
    output = [ "created .editorconfig" ];
    after = written devkit;
  };
  # The repository's own section comes after those of devkit whose names sort before its own.
  merges = repository {
    name = "merges";
    command = setup [
      flakeModules.editorconfig
      { perSystem.devkit.editorconfig.settings.sections."lake-manifest.json".indent_size = 4; }
    ];
    output = [ "created .editorconfig" ];
    after = written (devkit + "\n[lake-manifest.json]\nindent_size = 4\n");
  };
}
