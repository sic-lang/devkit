---
name: devkit-commits
description: Check that a branch's commits are signed off by their authors and merge only their base, and install a Git hook that rejects a commit without its author's sign-off, with devkit's `commits` module. Use this when setting up the commits check or the hook, or when the check or the hook fails.
---

# commits

The `commits` module checks the commits of a branch, from its base to its head.
It also provides a `commit-msg` hook that rejects a commit without its author's sign-off before Git creates it.

## Set it up

1. Import `inputs.devkit.flakeModules.commits`, as the `devkit` skill shows.
2. Run `nix run .#setup-hooks` to install the hook.
3. Run `nix run .#check-commits`.

## What the check requires

`nix run .#check-commits -- <base> <head>` checks the commits after `<base>` up to `<head>`.
`<base>` is `origin/main` by default, and `<head>` is `HEAD`.
The check fails if the clone lacks either of them, or if the clone is shallow, since a shallow clone may miss commits between them.
It requires that:

- every commit has a `Signed-off-by` trailer equal to its author's name and email;
- every merge commit merges only commits of `<base>`, as when `git merge --signoff origin/main` resolves a conflict with `<base>`.

The author commits with `git commit --signoff`.

A pull request's workflow gives the check the base and the head of the pull request, and fetches the history of both, as [devkit's workflow](https://github.com/sic-lang/devkit/blob/main/.github/workflows/checks.yml) does.

## The hook

`nix run .#setup-hooks` installs the `commit-msg` hook in the clone.
The hook needs Bash and Git on the contributor's `PATH`.
