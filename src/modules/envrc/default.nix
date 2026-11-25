{
  imports = [ ../files ];

  perSystem.devkit.files.".envrc".template = ./envrc.in;
}
