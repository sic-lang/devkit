---
name: devkit-files
description: Implement a custom repository-specific generated file, such as the configuration of a tool, from values shared by several files, using devkit's files module. Use this when a repository requires a generated file that is not provided by any of devkit's existing modules, or to change a value shared by the generated files.
---

# Generated files

The `files` module writes generated files into the repository, which commits them, so that editors, GitHub and fresh clones all read the same file as the checks.

- `nix run .#setup-files` writes them, but keeps a file that differs unless it is given `--force`.
- `nix run .#check-files` fails when a file is missing or differs from the generated one, and shows the difference; to change such a file, change the options that generate it, then run `nix run .#setup-files -- --force`.

## Share a value

`devkit.lineLength` sets the maximum line length, 100 by default, which every generated file that has one uses unless told otherwise.

## Generate a file

A generated file comes from a template in its own file, such as `example.toml.in`, whose placeholders `@name@` are replaced by `pkgs.replaceVars`, and is declared under its path in the repository:

```nix
devkit.files."example.toml" = pkgs.replaceVars ./example.toml.in {
  lineLength = toString config.devkit.lineLength;
};
```

The template keeps the file's comments, which explain why each value differs from the tool's default.
