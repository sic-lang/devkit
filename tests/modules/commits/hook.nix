{
  consumer,
  flakeModules,
  lib,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.commits ]) apps;
  case =
    name:
    {
      flags ? "",
      ...
    }@arguments:
    repository (
      removeAttrs arguments [ "flags" ]
      // {
        inherit name;
        # The sandbox has no /usr/bin/env, which the hook's shebang names.
        before = ''
          git config user.name "A U Thor"
          git config user.email author@example.com
          ${apps.setup-hooks.program}
          patchShebangs --build "$(git rev-parse --git-path hooks)/commit-msg"
        '';
        command = "git commit -q --allow-empty -m Change ${flags}";
      }
    );
  # The commit that the hook rejected does not exist.
  rejected = {
    status = 1;
    after = "if git rev-parse -q --verify HEAD; then exit 1; fi";
  };
in
lib.mapAttrs case {
  signed-off.flags = "--signoff";
  no-sign-off = rejected // {
    output = [ "no Signed-off-by: A U Thor <author@example.com>, which git commit -s adds" ];
  };
  sign-off-of-someone-else = rejected // {
    flags = ''--trailer "Signed-off-by: Someone Else <else@example.com>"'';
    output = [ "no Signed-off-by: A U Thor <author@example.com>" ];
  };
  # git commit --signoff signs off as the committer, who is not the author here.
  sign-off-of-the-committer = rejected // {
    flags = ''--signoff --author "Someone Else <else@example.com>"'';
    output = [ "no Signed-off-by: Someone Else <else@example.com>" ];
  };
}
