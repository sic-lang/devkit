{
  imports = [
    ../checks
    ../setups
  ];

  perSystem =
    { config, pkgs, ... }:
    {
      devkit = {
        # The commits after a base, origin/main by default, up to a head, HEAD by default: each one
        # is signed off by its author, and a merge commit only merges the base, to resolve a
        # conflict.
        checks.commits.command = config.devkit.mkCommand {
          name = "check-commits";
          template = ./check.sh.in;
          packages = [ pkgs.gnugrep ];
        };
        setups.hooks = {
          description = "Copy the recommended Git hooks to the hooks of the clone";
          command = config.devkit.mkSetup {
            name = "setup-hooks";
            mode = "755";
            # Where Git looks for the hooks: .git/hooks, unless core.hooksPath says otherwise.
            directory = ''"$(git rev-parse --path-format=absolute --git-path hooks)"'';
            files.commit-msg = ./commit-msg;
          };
        };
      };
      # The commit-msg hook rejects a commit without the sign-off of its author, which the commits
      # check requires, before the commit exists. It runs the contributor's Bash and Git, since its
      # copy outside the Nix store cannot depend on paths that the store may collect.
      checks.hook-commit-msg = import ../commands/checked.nix pkgs "commit-msg" ./commit-msg;
    };
}
