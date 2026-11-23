# The replacements of a template that goes through files keyed by their paths in the repository:
# targets, the paths, and sources, the files, each the elements of a Bash array.
lib: files: {
  targets = lib.escapeShellArgs (lib.attrNames files);
  # Interpolation copies a local file into the Nix store, which toString does not.
  sources = lib.escapeShellArgs (map (file: "${file}") (lib.attrValues files));
}
