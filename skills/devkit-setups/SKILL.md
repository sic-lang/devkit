---
name: devkit-setups
description: Implement a repository-specific setup, such as one that writes recommended files into the repository, with devkit's `setups` module. Use this when a repository needs a setup that none of devkit's modules provides.
---

# setups

The `setups` module lets a repository define its own setups, beyond those that devkit's modules provide.

## Add a setup

`devkit.setups.<name>` defines a setup named `<name>`.
It has a `description` and a `command`, which receives the setup's arguments.

`devkit.mkSetup` builds a command that writes files from the flake or the Nix store to their paths in the repository.
It never overwrites a file that differs from the one it writes, unless it is given `--force`:

```nix
devkit.setups.vscode = {
  description = "Write the recommended VS Code settings";
  command = config.devkit.mkSetup {
    name = "setup-vscode";
    mode = "644";
    files.".vscode/settings.json" = settings;
  };
};
```

When the directory of the files is known only when the setup runs, `directory` gives the Bash code that expands to it, and the paths in `files` are relative to it:

```nix
config.devkit.mkSetup {
  name = "setup-example";
  mode = "644";
  directory = ''"$(git rev-parse --absolute-git-dir)"'';
  files."example/file.txt" = example;
}
```

The `command` can also be built with the `commands` module, as described in the `devkit-commands` skill.

## Run a setup

`nix run .#setup-<name>` runs the `<name>` setup from the repository's root and passes it any arguments given after `--`.

## Run all the setups

`nix run .#setup` goes through every setup in the repository, including those from devkit's modules.
It asks before running each one, because each setup configures a tool that the contributor may not use.
It passes any arguments given after `--`, such as `--force`, to each setup it runs.
