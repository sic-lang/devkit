---
name: devkit-checks
description: Implement a repository-specific check with devkit's `checks` module. Use this when a repository needs a check that none of devkit's modules provides.
---

# Checks

The `checks` module lets a repository define its own checks, beyond those that devkit's modules provide.

## Add a check

`devkit.checks.<name>` defines a check named `<name>`.
Its `command` receives the check's arguments and returns a failure status when the check fails.

The `command` can be a command line, which Bash runs.
`tools` lists the packages whose programs it runs:

```nix
devkit.checks.actionlint = {
  command = "actionlint -color";
  tools = [ pkgs.actionlint ];
};
```

The development shell includes every check's `tools`.

The `command` can also be built with the `commands` module, as described in the `devkit-commands` skill:

```nix
devkit.checks.example.command = config.devkit.mkCommand {
  name = "check-example";
  template = ./check-example.sh.in;
  tools = [ pkgs.jq ];
};
```

## Run a check

`nix run .#check-<name>` runs the `<name>` check from the repository's root and passes it any arguments given after `--`.

## Run all the checks

`nix run .#check` runs every check in the repository, including those from devkit's modules.
It prints `ok` or `FAIL` for each check, followed by the output of each failed check.
