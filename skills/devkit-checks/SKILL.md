---
name: devkit-checks
description: Implement a custom repository-specific check using devkit's checks module. Use this when a repository requires a check that is not provided by any of devkit's existing modules.
---

# Checks

The `checks` module lets a repository define its own checks, beyond those that devkit's modules provide.

## Add a check

`devkit.checks.<name>` defines a check named `<name>`.
Its command receives the check's arguments and returns a failure status when the check fails.

The command is either a command line, which Bash runs as a whole, arguments, pipes and `&&` included, with the tools it needs:

```nix
devkit.checks.actionlint = {
  command = "actionlint -color";
  tools = [ pkgs.actionlint ];
};
```

or a command made with the `commands` module, as the `devkit-commands` skill describes:

```nix
devkit.checks.example.command = config.devkit.mkCommand {
  name = "check-example";
  template = ./check-example.sh.in;
  tools = [ pkgs.jq ];
};
```

## Run a check

`nix run .#check-<name>` runs the check `<name>` from the repository's root, and passes it the arguments given after `--`.

## Run all the checks

`nix run .#check` runs every check of the repository, including those of devkit's modules, and prints `ok` or `FAIL` for each one, with the output of every failure.
