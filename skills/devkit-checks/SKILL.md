---
name: devkit-checks
description: Implement a custom repository-specific check using devkit's checks module. Use this when a repository requires a check that is not provided by any of devkit's existing modules.
---

# Checks

The module `checks` lets the repository write checks of its own: `nix run .#check-<name>` runs one of them from the root of the repository, and `nix run .#check` all the checks, printing `ok` or `FAIL` and the output of each failure.
The development shell provides the tools of every check.

## Add a check

A check is a command, which fails when the check fails and receives the arguments of `check-<name>`.
It is either a command line, which Bash runs, with the packages it runs:

```nix
devkit.checks.actionlint = {
  command = "actionlint";
  tools = [ pkgs.actionlint ];
};
```

or a command of the module `commands`, for a check that is more than one command, as the skill `devkit-commands` describes:

```nix
devkit.checks.example.command = config.devkit.mkCommand {
  name = "check-example";
  template = ./check-example.sh.in;
  tools = [ pkgs.jq ];
};
```
