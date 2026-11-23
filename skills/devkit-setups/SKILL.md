---
name: devkit-setups
description: Implement a custom repository-specific setup, which writes recommended files into the repository, using devkit's setups module. Use this when a repository requires a setup that is not provided by any of devkit's existing modules.
---

# Setups

The `setups` module lets a repository define its own setups, beyond those that devkit's modules provide.

## Add a setup

`devkit.setups.<name>` defines a setup named `<name>`, with a description and a command, which receives the setup's arguments.

`devkit.mkSetup` makes a command that writes files from the Nix store to their paths in the repository.
It never overwrites a file that differs from the recommended one, unless it is given `--force`:

```nix
devkit.setups.vscode = {
  description = "Write the recommended settings of VS Code";
  command = config.devkit.mkSetup {
    name = "setup-vscode";
    mode = "644";
    files.".vscode/settings.json" = settings;
  };
};
```

The command can also be made with the `commands` module, as the `devkit-commands` skill describes.

## Run a setup

`nix run .#setup-<name>` runs the setup `<name>` from the repository's root, and passes it the arguments given after `--`.

## Run all the setups

`nix run .#setup` goes through every setup of the repository, including those of devkit's modules, and asks before running each one, since each configures a tool that the contributor may not use.
It passes them the arguments given after `--`, such as `--force`.
