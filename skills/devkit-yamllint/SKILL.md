---
name: devkit-yamllint
description: Check a repository's YAML files with yamllint, from a configuration that devkit's yamllint module generates. Use this when setting up the check of the YAML files, when it fails, or when their maximum line length changes.
---

# yamllint

The `yamllint` module checks every YAML file of the repository with `yamllint --strict`, using a configuration that it generates, `.yamllint.yaml`, which the repository commits so that editors read it too.

## Set it up

1. Import `inputs.devkit.flakeModules.yamllint`, as the `devkit` skill shows.
2. Run `nix run .#setup-files`, which writes `.yamllint.yaml`, and commit the file.
3. Run `nix run .#check-yamllint`, and `nix run .#check-files`, which fails when `.yamllint.yaml` differs from the generated one.

## Change the configuration

The configuration is yamllint's default, except for two points: GitHub workflows may start without `---` and use the key `on`, and the maximum line length is `devkit.yamllint.lineLength`, which defaults to `devkit.lineLength`, itself 100 by default.
Change these options rather than `.yamllint.yaml`, then run `nix run .#setup-files -- --force`.
