---
name: devkit-checks
description: Write a check of a repository of its own, through the module checks of devkit. Use when a repository needs a check that no module of devkit gives.
---

# Checks

The module `checks` lets the repository write checks of its own: `nix run .#check-<name>` runs one of them from the root of the repository, and `nix run .#check` all the checks, printing `ok` or `FAIL` and the output of each failure.
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
