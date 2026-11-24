{
  consumer,
  flakeModules,
  lib,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.commits ]) apps;
  commit = "git commit -q --allow-empty";
  # A clone whose origin/main is a commit signed off by its author, with the branch topic from it.
  clone = ''
    git config user.name "A U Thor"
    git config user.email author@example.com
    ${commit} --signoff -m Base
    git update-ref refs/remotes/origin/main HEAD
    git switch -q -c topic
  '';
  case =
    name:
    {
      before ? "",
      ...
    }@arguments:
    repository (
      arguments
      // {
        inherit name;
        command = apps.check-commits.program;
        before = clone + before;
      }
    );
in
lib.mapAttrs case {
  signed-off.before = "${commit} --signoff -m Change";
  no-sign-off = {
    before = "${commit} -m Change";
    status = 1;
    output = [ "Change: no Signed-off-by: A U Thor <author@example.com>" ];
  };
  sign-off-of-someone-else = {
    before = ''${commit} --trailer "Signed-off-by: Someone Else <else@example.com>" -m Change'';
    status = 1;
    output = [ "Change: no Signed-off-by: A U Thor <author@example.com>" ];
  };
  # git commit --signoff signs off as the committer, who is not the author here.
  sign-off-of-the-committer = {
    before = ''${commit} --signoff --author "Someone Else <else@example.com>" -m Change'';
    status = 1;
    output = [ "Change: no Signed-off-by: Someone Else <else@example.com>" ];
  };
  merge-of-the-base.before = ''
    ${commit} --signoff -m Change
    git switch -q --detach origin/main
    ${commit} --signoff -m "Change of the base"
    git update-ref refs/remotes/origin/main HEAD
    git switch -q topic
    git merge -q --no-edit --signoff origin/main
  '';
  merge-of-another-branch = {
    before = ''
      git switch -q -c other
      ${commit} --signoff -m "Change of another branch"
      git switch -q topic
      ${commit} --signoff -m Change
      git merge -q --no-edit --signoff other
    '';
    status = 1;
    output = [ "Merge branch 'other' into topic: merges another branch than origin/main" ];
  };
  merge-without-sign-off = {
    before = ''
      ${commit} --signoff -m Change
      git switch -q --detach origin/main
      ${commit} --signoff -m "Change of the base"
      git update-ref refs/remotes/origin/main HEAD
      git switch -q topic
      git merge -q --no-edit origin/main
    '';
    status = 1;
    output = [ "into topic: no Signed-off-by: A U Thor <author@example.com>" ];
  };
  # The commits from a base to a head that the arguments give, as in a pull request, with no
  # origin/main and a commit after the head that would fail.
  base-and-head = {
    before = ''
      git tag base
      ${commit} --signoff -m Change
      git tag head
      ${commit} -m Later
      git update-ref -d refs/remotes/origin/main
    '';
    arguments = [
      "base"
      "head"
    ];
  };
  base-only = {
    before = ''
      git tag base
      ${commit} --signoff -m Change
      git update-ref -d refs/remotes/origin/main
      ${commit} -m Later
    '';
    arguments = [ "base" ];
    status = 1;
    output = [ "Later: no Signed-off-by: A U Thor <author@example.com>" ];
  };
  merge-of-another-branch-than-the-base = {
    before = ''
      git tag base
      git switch -q -c other
      ${commit} --signoff -m "Change of another branch"
      git switch -q topic
      ${commit} --signoff -m Change
      git merge -q --no-edit --signoff other
    '';
    arguments = [ "base" ];
    status = 1;
    output = [ "merges another branch than base" ];
  };
}
