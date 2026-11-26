# The command that fails if shfmt, with devkit's indentation, would change the script `$target`
# named `name`, for the check of a script that Nix builds.
pkgs: name: ''
  ${pkgs.lib.getExe pkgs.shfmt} --indent ${toString (import ../../lib.nix).indentSize} \
    --diff --filename ${name} <"$target"
''
