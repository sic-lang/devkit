# The ShellCheck check of the Bash script `script`, after Bash's own parse of it.
pkgs: name: script:
pkgs.runCommand "${name}-checked" {
  nativeBuildInputs = [ pkgs.shellcheck ];
  inherit script;
  dryRun = pkgs.stdenv.shellDryRun;
} (builtins.readFile ./checked.sh)
