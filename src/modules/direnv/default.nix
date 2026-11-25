{
  imports = [
    ../commands
    ../files
  ];

  perSystem.devkit.files.".envrc".template = ./envrc.in;
}
