---
name: devkit-files
description: Generate a repository-specific file, such as a tool's configuration, from values shared across files, with devkit's `files` module. Use this when a repository needs a generated file that no devkit module provides, or to change a value that the generated files share.
---

# Generated files

The `files` module writes generated files into the repository.
The repository commits them, so that editors, GitHub and fresh clones all see the same files as the checks.

- `nix run .#setup-files` writes them.
  It keeps any existing file that differs from the generated one, unless given `--force`.
- `nix run .#check-files` fails if a file is missing or differs from the generated one, and shows the difference.
  To change a generated file, change the options that generate it, then run `nix run .#setup-files -- --force`.

## Share a value

`devkit.lineLength` sets the maximum line length, 100 by default.
Every generated file with a maximum line length uses it, unless that file's own option overrides it.

## Generate a file

A generated file comes from a template in its own file, such as `example.toml.in`.
`pkgs.replaceVars` replaces the template's `@name@` placeholders, and the result is declared under the file's path in the repository:

```nix
devkit.files."example.toml" = pkgs.replaceVars ./example.toml.in {
  lineLength = toString config.devkit.lineLength;
};
```

Keep the file's comments in the template: they explain why each value differs from the tool's default.
