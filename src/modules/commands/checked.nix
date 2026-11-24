# The ShellCheck and shfmt check of the Bash script `script`.
pkgs: name: script:
pkgs.runCommand "${name}-checked" {
  nativeBuildInputs = [
    pkgs.shellcheck
    pkgs.shfmt
  ];
  inherit script;
  indentSize = toString (import ../../lib.nix).indentSize;
} (builtins.readFile ./checked.sh)
