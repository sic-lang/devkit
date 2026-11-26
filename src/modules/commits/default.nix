{
  imports = [
    ../checks
    ../setups
  ];

  perSystem =
    { config, pkgs, ... }:
    let
      # The commit-msg hook rejects a commit without the sign-off of its author, which the commits
      # check requires, before the commit exists.
      # It runs the contributor's Bash and Git, since its copy outside the Nix store cannot depend
      # on paths that the store may collect, so it is not built by writeShellApplication, whose
      # check it runs.
      hook = pkgs.writeTextFile {
        name = "commit-msg";
        executable = true;
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail
          author=$(git var GIT_AUTHOR_IDENT | sed 's/ [0-9]* [-+][0-9]*$//')
          if ! git interpret-trailers --parse "$1" | grep -qxF "Signed-off-by: $author"; then
            echo "no Signed-off-by: $author, which git commit -s adds" >&2
            exit 1
          fi
        '';
        checkPhase = ''
          ${pkgs.stdenv.shellDryRun} "$target"
          ${pkgs.lib.getExe pkgs.shellcheck} "$target"
        ''
        + import ../commands/shfmt.nix pkgs "commit-msg";
      };
    in
    {
      devkit = {
        # The commits after a base, origin/main by default, up to a head, HEAD by default: each one
        # is signed off by its author, and a merge commit only merges the base, to resolve a
        # conflict.
        checks.commits.command = config.devkit.mkCommand {
          name = "check-commits";
          text = ''
            # Replace refs could show other commits in place of those of the history, and grafts
            # other parents.
            # Git advises against a graft file each time it reads one, even an empty one.
            export GIT_NO_REPLACE_OBJECTS=1
            export GIT_GRAFT_FILE=/dev/null
            export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=advice.graftFileDeprecated \
              GIT_CONFIG_VALUE_0=false
            base=''${1:-origin/main}
            head=''${2:-HEAD}
            for ref in "$base" "$head"; do
              if ! git rev-parse --verify --quiet "$ref^{commit}" >/dev/null; then
                echo "$ref is not a commit of the clone: fetch it, or give the base and head" \
                  "as arguments" >&2
                exit 1
              fi
            done
            # A format of a commit, without the check of its signature that log.showSignature
            # would print.
            show() {
              git log -1 --no-show-signature --format="$1" "$2"
            }
            status=0
            # Each commit, followed by its parents.
            history=$(git rev-list --parents "$base..$head")
            # The commits that a shallow clone holds without their parents, which hide the commits
            # behind them.
            boundary=$(git rev-parse --git-path shallow)
            commits=$(cut -d " " -f 1 <<<"$history")
            if [ -f "$boundary" ] && grep -qFxf "$boundary" <<<"$commits"; then
              echo "the clone is shallow and misses commits after $base: fetch them with" \
                "git fetch --unshallow" >&2
              exit 1
            fi
            while read -r -a parents; do
              if [ "''${#parents[@]}" -eq 0 ]; then
                continue
              fi
              commit=''${parents[0]}
              for parent in "''${parents[@]:2}"; do
                if ! git merge-base --is-ancestor "$parent" "$base"; then
                  echo "$(show '%h %s' "$commit"): merges another branch than $base" >&2
                  status=1
                fi
              done
              author=$(show '%an <%ae>' "$commit")
              signoffs=$(show '%(trailers:key=Signed-off-by,valueonly,unfold)' "$commit")
              # Whole lines compared, so that an author on several lines matches none.
              signed=false
              while IFS= read -r signoff; do
                if [ "$signoff" = "$author" ]; then
                  signed=true
                fi
              done <<<"$signoffs"
              if ! "$signed"; then
                echo "$(show '%h %s' "$commit"): no Signed-off-by: $author" >&2
                status=1
              fi
            done <<<"$history"
            exit "$status"
          '';
        };
        setups.hooks = {
          description = "Copy the recommended Git hooks to the hooks of the clone";
          command = config.devkit.mkSetup {
            name = "setup-hooks";
            mode = "755";
            # Where Git looks for the hooks: .git/hooks, unless core.hooksPath says otherwise.
            directory = ''"$(git rev-parse --path-format=absolute --git-path hooks)"'';
            files.commit-msg = hook;
          };
        };
      };
    };
}
