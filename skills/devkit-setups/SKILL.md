---
name: devkit-setups
description: Implement a custom repository-specific setup, which writes recommended files into the repository, using devkit's setups module. Use this when a repository requires a setup that is not provided by any of devkit's existing modules.
---

# Setups

The module `setups` lets a repository write setups of its own.

## Add a setup

`devkit.setups.<name>` adds the setup `<name>`, with a description and a command, which receives the arguments of the setup.
`devkit.mkSetup` makes the command of a setup that writes files of the Nix store to their paths in the repository, and never overwrites a file that differs from the one it recommends, unless it is given `--force`:

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

The command can also be a command of the module `commands`, as the skill `devkit-commands` describes.

## Run a setup

`nix run .#setup-<name>` runs the setup `<name>` from the root of the repository, and passes it the arguments given after `--`.

## Run all the setups

`nix run .#setup` asks for each setup of the repository, those of the modules of devkit included, whether to run it, since each configures a tool that the contributor may not use, and passes them the arguments given after `--`, such as `--force`.
