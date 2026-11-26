---
name: files
description: Generate a repository-specific file, such as a tool's configuration, with devkit's `files` module. Use this when a repository needs a generated file that no devkit module provides.
---

# files

The `files` module writes generated files into the repository.
The repository commits them, so that editors, GitHub and fresh clones all see the same files as the checks.

- `nix run .#setup-files` writes them.
  It keeps any existing file that differs from the generated one, unless given `--force`.
- `nix run .#check-files` fails if a file is missing or differs from the generated one, and shows the difference.
  To change a generated file, change its source, or its template or replacements, in `devkit.files`, then run `nix run .#setup-files -- --force`.
- Neither touches a file that is no longer generated: delete it by hand.

## Generate a configuration

A configuration file is built from a Nix value with a format of nixpkgs' [`pkgs.formats`](https://nixos.org/manual/nixos/unstable/#sec-settings-nix-representable), so that an option of the format's type can merge the values of several modules.
`devkit.files.<path>.source` takes the built file, which devkit copies as it is.
This example writes a JSON file:

```nix
perSystem =
  { pkgs, ... }:
  {
    devkit.files."example.json".source = (pkgs.formats.json { }).generate "example.json" { a = 1; };
  };
```

YAML is the exception: nixpkgs' format writes YAML that devkit's `yaml` check refuses, so `devkit.formats.yaml` gives the same `type` and `generate` with a YAML that the check accepts.

## Generate a file from a template

`devkit.files.<path>` can instead generate `<path>` from a `template`, a file from the flake or the Nix store.
Each `@name@` placeholder in the template is replaced with its value from `replacements`:

```nix
devkit.files."example.toml" = {
  template = ./example.toml.in;
  replacements.lineLength = toString inputs.devkit.lib.lineLength;
};
```

The build fails if a replacement matches no placeholder, or if a placeholder is left unreplaced.

## Share a value

A value that generated files share is a constant of devkit's library.
A repository reads it as `inputs.devkit.lib.<name>` and puts it in the value of a configuration, or passes it to a template as a replacement, as in the example above.
The value then has one source, and no repository can change it.
