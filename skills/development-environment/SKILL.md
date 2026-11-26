---
name: development-environment
description: Set up the development environment of a repository that uses devkit, with Nix, its development shell, direnv and its setups. Use this when starting to work in such a repository, or when a tool that its checks need is missing.
---

# Development environment

A repository that uses devkit gets its development environment from its flake.
The flake pins every tool, so that every contributor and the CI run the same versions.

## Install Nix

Install [Nix](https://nixos.org/download/), and enable [flakes](https://nix.dev/manual/nix/latest/development/experimental-features#xp-feature-flakes) and the `nix` command.

## Enter the development shell

`nix develop` starts the repository's development shell, which holds every tool that its checks run.

With [direnv](https://direnv.net), the repository's `.envrc` loads the shell when you enter the repository.
Read `.envrc`, then run `direnv allow` to let it run.

## Run the setups

`nix run .#setup` runs, after asking you, each setup of the repository.
The skill of the module that gives a setup says what it does.

## Run the checks

`nix run .#check` runs every check of the repository.
