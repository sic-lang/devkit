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
It requires that:

- every commit has a `Signed-off-by` trailer equal to its author's name and email, which `git commit -s` adds when the author commits;
- every merge commit merges only commits of `<base>`, as when `git merge --signoff origin/main` resolves a conflict with `<base>`.

A pull request's workflow gives the base and the head of the pull request, and fetches the history of both:

```yaml
- if: github.event_name == 'pull_request'
  run: |
    git fetch --quiet --unshallow origin "$HEAD" "$BASE"
    nix run --quiet .#check-commits -- "$BASE" "$HEAD"
  env:
    BASE: ${{ github.event.pull_request.base.sha }}
    HEAD: ${{ github.event.pull_request.head.sha }}
```

## The hook

`nix run .#setup-hooks` copies the `commit-msg` hook to the directory where Git looks for the hooks: `.git/hooks`, unless `core.hooksPath` gives another one.
It keeps a hook that differs from it, unless it is given `--force`.
The hook rejects a commit whose message has no `Signed-off-by` trailer equal to its author.
It runs the contributor's Bash and Git, so it keeps working when the Nix store changes.
