# nixpkgs' writeShellApplication, whose check, after Bash and ShellCheck, also runs shfmt, so that
# every script of devkit is formatted alike.
# writeShellApplication ends the script with a newline after the text, which ends with its own, so
# the text loses its own, which shfmt would report as an empty last line.
pkgs: args:
pkgs.writeShellApplication (
  args
  // {
    text = pkgs.lib.removeSuffix "\n" args.text;
    derivationArgs.postCheck = import ./shfmt.nix pkgs args.name;
  }
)
