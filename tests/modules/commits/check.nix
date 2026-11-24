{
  consumer,
  flakeModules,
  lib,
  pkgs,
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
  # A clone of the branch topic and of origin/main, each with its last commit only.
  shallow = ''
    git clone -q --depth 1 --branch topic "file://$PWD" ../shallow
    cd ../shallow
    git fetch -q --depth 1 origin refs/remotes/origin/main:refs/remotes/origin/main
  '';
  # An SSH key that signs the commits, and whose signatures git log checks and shows.
  signing =
    let
      ssh-keygen = lib.getExe' pkgs.openssh "ssh-keygen";
    in
    ''
      ${ssh-keygen} -q -t ed25519 -N "" -C "" -f "$TMPDIR/key"
      echo "author@example.com $(cat "$TMPDIR/key.pub")" >"$TMPDIR/signers"
      git config gpg.format ssh
      git config gpg.ssh.program ${ssh-keygen}
      git config gpg.ssh.allowedSignersFile "$TMPDIR/signers"
      git config user.signingKey "$TMPDIR/key"
      git config log.showSignature true
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
  # A trailer's value may continue on an indented line.
  folded-sign-off.before = ''
    ${commit} -m Change -m "$(printf 'Signed-off-by: A U Thor\n <author@example.com>')"
  '';
  # A value that starts with the author's ident, but holds more, is not the author's sign-off.
  sign-off-with-more = {
    before = ''${commit} --trailer "Signed-off-by: A U Thor <author@example.com>x" -m Change'';
    status = 1;
    output = [ "Change: no Signed-off-by: A U Thor <author@example.com>" ];
  };
  author-under-another-key = {
    before = ''${commit} --trailer "Co-authored-by: A U Thor <author@example.com>" -m Change'';
    status = 1;
    output = [ "Change: no Signed-off-by: A U Thor <author@example.com>" ];
  };
  # With log.showSignature, git log prints the signature's check before the format, in the author
  # and in the sign-offs alike.
  no-sign-off-with-show-signature = {
    before = ''
      ${signing}
      ${commit} --gpg-sign -m Change
    '';
    status = 1;
    output = [ "Change: no Signed-off-by: A U Thor <author@example.com>" ];
  };
  signed-off-with-show-signature.before = ''
    ${signing}
    ${commit} --gpg-sign --signoff -m Change
  '';
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
  # Every parent after the first counts, not only the second.
  octopus-merge-of-another-branch = {
    before = ''
      git switch -q -c other
      ${commit} --signoff -m "Change of another branch"
      git switch -q --detach origin/main
      ${commit} --signoff -m "Change of the base"
      git update-ref refs/remotes/origin/main HEAD
      git switch -q topic
      ${commit} --signoff -m Change
      git merge -q --no-edit --signoff origin/main other
    '';
    status = 1;
    output = [ "merges another branch than origin/main" ];
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
  # A shallow clone, such as a workflow's checkout, may lack the base, which would hide the commits.
  no-origin-main = {
    before = ''
      ${commit} -m Change
      git update-ref -d refs/remotes/origin/main
    '';
    status = 1;
    output = [ "origin/main is not a commit of the clone" ];
  };
  # A shallow clone's commits have no parents, which hides the commits and the merges behind them.
  shallow-unsigned = {
    before = ''
      ${commit} -m Change
      ${shallow}
    '';
    status = 1;
    output = [ "the clone is shallow" ];
  };
  shallow-merge-of-another-branch = {
    before = ''
      git switch -q -c other
      ${commit} -m "Change of another branch"
      git switch -q topic
      git merge -q --no-edit --signoff other
      ${shallow}
    '';
    status = 1;
    output = [ "the clone is shallow" ];
  };
  missing-base = {
    before = "${commit} -m Change";
    arguments = [ "missing" ];
    status = 1;
    output = [ "missing is not a commit of the clone" ];
  };
  missing-head = {
    before = "${commit} -m Change";
    arguments = [
      "origin/main"
      "missing"
    ];
    status = 1;
    output = [ "missing is not a commit of the clone" ];
  };
  # A ref may name another object than a commit, such as a tree.
  tree-base = {
    before = "${commit} -m Change";
    arguments = [ "HEAD^{tree}" ];
    status = 1;
    output = [ "HEAD^{tree} is not a commit of the clone" ];
  };
  tree-head = {
    before = "${commit} -m Change";
    arguments = [
      "origin/main"
      "HEAD^{tree}"
    ];
    status = 1;
    output = [ "HEAD^{tree} is not a commit of the clone" ];
  };
  # A commit that git cannot read stops the check, rather than leaving the commits behind it unseen.
  missing-object = {
    before = ''
      ${commit} --signoff -m Change
      git switch -q --detach origin/main
      ${commit} --signoff -m "Change of the base"
      merged=$(git rev-parse HEAD)
      git update-ref refs/remotes/origin/main HEAD
      git switch -q topic
      git merge -q --no-edit --signoff origin/main
      git switch -q --detach origin/main
      ${commit} --signoff -m "Later change of the base"
      git update-ref refs/remotes/origin/main HEAD
      git switch -q topic
      rm ".git/objects/''${merged:0:2}/''${merged:2}"
    '';
    status = 128;
  };
  # A replace ref would show git another commit in place of the one in the history.
  replaced = {
    before = ''
      ${commit} -m Change
      signoff="Signed-off-by: A U Thor <author@example.com>"
      signed=$(git commit-tree -p HEAD^ -m Change -m "$signoff" HEAD^{tree})
      git replace HEAD "$signed"
    '';
    status = 1;
    output = [ "Change: no Signed-off-by: A U Thor <author@example.com>" ];
  };
  # A graft would give a commit other parents than those of the history.
  grafted = {
    before = ''
      ${commit} -m Unsigned
      ${commit} --signoff -m Signed
      echo "$(git rev-parse HEAD) $(git rev-parse origin/main)" >.git/info/grafts
    '';
    status = 1;
    output = [ "Unsigned: no Signed-off-by: A U Thor <author@example.com>" ];
  };
  # A pull request with no commit after its base, such as one that its base merged.
  no-commits.arguments = [
    "origin/main"
    "origin/main"
  ];
}
