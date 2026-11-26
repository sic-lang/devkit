{
  consumer,
  flakeModules,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.commits ]) apps;
in
{
  writes = repository {
    name = "writes";
    command = apps.setup-hooks.program;
    output = [ "created" ];
    after = ''
      [ -x .git/hooks/commit-msg ]
    '';
  };
  # Git then runs the hook from core.hooksPath, so that the hook rejects this commit.
  hooks-path = repository {
    name = "hooks-path";
    before = "git config core.hooksPath hooks";
    command = apps.setup-hooks.program;
    output = [ "created" ];
    after = ''
      [ ! -e .git/hooks/commit-msg ]
      patchShebangs --build hooks/commit-msg
      git config user.name "A U Thor"
      git config user.email author@example.com
      if git commit -q --allow-empty -m Change; then
        exit 1
      fi
    '';
  };
}
