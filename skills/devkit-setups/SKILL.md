---
name: devkit-setups
description: Implement a custom repository-specific setup, which writes recommended files into the repository, using devkit's setups module. Use this when a repository requires a setup that is not provided by any of devkit's existing modules.
---

# Setups

The module `setups` lets the repository write setups of its own: `nix run .#setup-<name>` runs one of them, and `nix run .#setup` asks for each one before running it, since each configures a tool that the contributor may not use.
A setup never overwrites a file that differs from the one it recommends, unless it is given `--force`: `nix run .#setup -- --force` passes it to every setup.

## Add a setup that writes files

`devkit.mkSetup` makes a setup that writes files of the Nix store to their paths in the repository:

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

A setup that does more is a command, as the skill `devkit-commands` describes, given with its description to `devkit.setups.<name>`.
