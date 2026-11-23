---
name: devkit-yamllint
description: Check the YAML files of a repository with yamllint, through the module yamllint of devkit, which also generates its configuration. Use when setting up the check of the YAML files, when it fails, or when the length of their lines changes.
---

# yamllint

The module `yamllint` checks every YAML file of the repository with `yamllint --strict`, from a configuration that it generates, `.yamllint.yaml`, which the repository commits so that the editors read it too.

## Set it up

1. Import `inputs.devkit.flakeModules.yamllint`, as the skill `devkit` shows.
2. Run `nix run .#setup-files`, which writes `.yamllint.yaml`, and commit it.
3. Run `nix run .#check-yamllint`, and `nix run .#check-files`, which fails when `.yamllint.yaml` differs from the one generated.

## Change the configuration

The configuration is the default of yamllint, except for the workflows of GitHub, which start without `---` and use the key `on`, and for the length of the lines: `devkit.yamllint.lineLength`, by default `devkit.lineLength`, itself 100 by default.
Change it through these options, never in `.yamllint.yaml`, then run `nix run .#setup-files -- --force`.
