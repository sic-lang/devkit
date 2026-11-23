---
name: devkit-yamllint
description: Check the YAML files of a repository that uses devkit with yamllint, from a generated configuration. Use when the check yamllint fails or when the length of the lines of the YAML files changes.
---

# yamllint

The module `yamllint` checks every YAML file of the repository with `yamllint --strict`, and generates its configuration, `.yamllint.yaml`, as the skill `devkit-files` describes.

The configuration is the default of yamllint, except for the workflows of GitHub, which start without `---` and use the key `on`, and for the length of the lines, `devkit.yamllint.lineLength`, by default `devkit.lineLength`.
Change it through these options, never in `.yamllint.yaml`, then run `nix run .#setup-files -- --force`.
