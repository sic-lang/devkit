# The ShellCheck and shfmt lint of the Bash script `script`, the flake check lint-<name>.
pkgs: name: script:
pkgs.runCommand "lint-${name}" {
  nativeBuildInputs = [
    pkgs.shellcheck
    pkgs.shfmt
  ];
  inherit script;
  indentSize = toString (import ../../lib.nix).indentSize;
} (builtins.readFile ./lint.sh)
