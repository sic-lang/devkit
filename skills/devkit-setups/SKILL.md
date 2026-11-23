---
name: devkit-setups
description: Write a setup of a repository of its own, which writes recommended files into it, through the module setups of devkit. Use when a repository should write files such as the settings of an editor.
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
