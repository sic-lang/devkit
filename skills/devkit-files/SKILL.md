---
name: devkit-files
description: Generate a file of a repository that uses devkit, such as the configuration of a tool, from values shared by several files. Use when adding a generated file, changing a shared value such as the length of the lines, or when the check files fails.
---

# Generated files

The module `files` writes the files that devkit generates, such as the configurations of the tools, into the repository, which commits them, so that the editors, GitHub and a fresh clone read the same file as the checks.

- `nix run .#setup-files` writes them; it keeps a file that differs, unless it is given `--force`.
- The check `files` fails when one of them is missing or differs from the generated one, and shows the difference.

A file differs when it was edited by hand or when an option changed: change it through the options, then run `nix run .#setup-files -- --force`.

## Share a value

`devkit.lineLength`, 100 by default, is the length of the longest line, the default of each generated file that has one; a module can let the repository set its own value instead, such as `devkit.yamllint.lineLength`.

## Generate a file

A module generates a file from a template of its own, `<file>.in`, whose placeholders `@name@` it replaces with `pkgs.replaceVars`, and gives it under its path in the repository:

```nix
devkit.files.".yamllint.yaml" = pkgs.replaceVars ./yamllint.yaml.in {
  lineLength = toString config.devkit.yamllint.lineLength;
};
```

The template keeps the comments of the file, which give the reason of each value that differs from the default of the tool.
