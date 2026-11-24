{
  template = ./editorconfig.in;
  replacements.lineLength = toString (import ../../lib.nix).lineLength;
}
