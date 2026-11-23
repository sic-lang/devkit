lib: files: {
  targets = lib.escapeShellArgs (lib.attrNames files);
  # Interpolation copies a local file into the Nix store, which toString does not.
  sources = lib.escapeShellArgs (map (file: "${file}") (lib.attrValues files));
}
