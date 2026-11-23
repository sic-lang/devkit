---
name: devkit-files
description: Generate a file of a repository, such as the configuration of a tool, from values shared by several files, through the module files of devkit. Use when a repository should generate a file of its own, or change a value shared by the generated files.
---

# Generated files

The module `files` writes generated files into the repository, which commits them, so that the editors, GitHub and a fresh clone read the same file as the checks.

- `nix run .#setup-files` writes them; it keeps a file that differs, unless it is given `--force`.
- `nix run .#check-files` fails when one of them is missing or differs from the generated one, and shows the difference: change the file through the options that generate it, then run `nix run .#setup-files -- --force`.

## Share a value

`devkit.lineLength`, 100 by default, is the length of the longest line, the default of each generated file that has one.

## Generate a file

A file is generated from a template of its own, `<file>.in`, whose placeholders `@name@` `pkgs.replaceVars` replaces, under its path in the repository:

```nix
devkit.files."example.toml" = pkgs.replaceVars ./example.toml.in {
  lineLength = toString config.devkit.lineLength;
};
```

The template keeps the comments of the file, which give the reason of each value that differs from the default of its tool.
