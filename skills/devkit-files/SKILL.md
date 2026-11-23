---
name: devkit-files
description: Generate a repository-specific file, such as a tool's configuration, from a template with devkit's `files` module. Use this when a repository needs a generated file that no devkit module provides.
---

# files

The `files` module writes generated files into the repository.
The repository commits them, so that editors, GitHub and fresh clones all see the same files as the checks.

- `nix run .#setup-files` writes them.
  It keeps any existing file that differs from the generated one, unless given `--force`.
- `nix run .#check-files` fails if a file is missing or differs from the generated one, and shows the difference.
  To change a generated file, change its template or replacements in `devkit.files`, then run `nix run .#setup-files -- --force`.
- Neither touches a file that is no longer generated: delete it by hand.

## Generate a file

`devkit.files.<path>` generates `<path>` from a `template`, a file of the flake or the Nix store.
Each `@name@` placeholder in the template is replaced with its value from `replacements`:

```nix
devkit.files."example.toml" = {
  template = ./example.toml.in;
  replacements.lineLength = toString config.devkit.lineLength;
};
```

The build fails if a replacement matches no placeholder, or if a placeholder is left unreplaced.

## Share a value

A value that several generated files share is a devkit option, fixed in devkit, which each template receives as a replacement.
The value then has one source, and a repository cannot change it.

`devkit.lineLength` is the maximum line length, 100.
Every generated file that has a maximum line length uses it, even when 100 is already its tool's default.
