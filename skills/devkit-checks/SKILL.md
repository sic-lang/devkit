---
name: devkit-checks
description: Add a check to a repository that uses devkit, or run its checks. Use when a repository needs a new check, or before pushing a change to it.
---

# Checks

The module `checks` runs the checks of the repository: `nix run .#check-<name>` runs one of them from the root of the repository, and `nix run .#check` runs all of them, printing `ok` or `FAIL` and the output of each failure.
The development shell provides the tools of every check.

## Add a check

A check of one command gives the command and its tools:

```nix
devkit.checks.actionlint = {
  tools = [ pkgs.actionlint ];
  command = "actionlint";
};
```

The command receives the arguments of `check-<name>` as `"$@"`.
A check of more than one command gives instead a template, with its `replacements`, as the skill `devkit-commands` describes; its template starts with `cd "$(git rev-parse --show-toplevel)"`.
