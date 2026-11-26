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
  # The modules of a repository that adds `settings` to the EditorConfig.
  adding = settings: [
    flakeModules.editorconfig
    { perSystem.devkit.editorconfig.settings = settings; }
  ];
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
    command = setup (adding {
      sections."lake-manifest.json".indent_size = 4;
    });
    output = [ "created .editorconfig" ];
    after = written (devkit + "\n[lake-manifest.json]\nindent_size = 4\n");
  };
  # The repository's settings add to a section of the module.
  merges-into-all = repository {
    name = "merges-into-all";
    command = setup (adding {
      sections."*".spelling_language = "en-US";
    });
    output = [ "created .editorconfig" ];
    after = written (
      builtins.replaceStrings
        [ "max_line_length = 100\n" ]
        [
          "max_line_length = 100\nspelling_language = en-US\n"
        ]
        devkit
    );
  };
  # A setting that the module sets to another value fails the evaluation of the flake.
  conflict =
    assert
      !(builtins.tryEval (
        setup (adding {
          sections."*".indent_size = 4;
        })
      )).success;
    pkgs.emptyFile;
}
