{
  template = ./editorconfig.in;
  replacements = {
    indentSize = toString (import ../../lib.nix).indentSize;
    lineLength = toString (import ../../lib.nix).lineLength;
  };
}
