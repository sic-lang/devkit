---
name: devkit-checks
description: Implement a custom repository-specific check using devkit's checks module. Use this when a repository requires a check that is not provided by any of devkit's existing modules.
---

# Checks

The module `checks` lets a repository write checks of its own.

## Add a check

`devkit.checks.<name>` adds the check `<name>`, whose command receives the arguments of the check and fails when the check fails.
The command is either a command line, which Bash runs whole, with its arguments, its pipes and its lists of commands, and the packages it runs:

```nix
devkit.checks.actionlint = {
  command = "actionlint -color";
  tools = [ pkgs.actionlint ];
};
```

or a command of the module `commands`, as the skill `devkit-commands` describes:

```nix
devkit.checks.example.command = config.devkit.mkCommand {
  name = "check-example";
  template = ./check-example.sh.in;
  tools = [ pkgs.jq ];
};
```

## Run a check

`nix run .#check-<name>` runs the check `<name>` from the root of the repository, and passes it the arguments given after `--`.

## Run all the checks

`nix run .#check` runs every check of the repository, those of the modules of devkit included, and prints `ok` or `FAIL` for each, with the output of each failure.
