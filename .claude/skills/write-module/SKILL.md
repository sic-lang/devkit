---
name: write-module
description: Write or change a devkit module, with its tests and its skill. Use this when adding a module to devkit, or when changing what a module provides.
---

# Write a module

A devkit module is a [flake-parts](https://flake.parts) module that gives a repository checks, setups, generated files, commands, a development shell or a formatter.
This skill gives the rules that no check of devkit enforces.
The flake, the tests and the workflow already enforce the rest, as the last section says.

## Name it

A module is named after the kind of files it handles, never after a tool.
A check that runs one tool is named after the tool, so that a failure names the tool.
A module that handles no kind of files is named after what it gives.

## Lay it out

- `src/modules/<name>/` holds every file of the module: `default.nix`, and the templates (`*.in`), scripts and configurations that it reads.
  Code that is not Nix goes in a file of its own, never in a Nix string, unless it is a single command line.
- `tests/modules/<name>/` holds only the module's test files.
  A helper of one module's tests goes in `tests/libs/<name>.nix`, and a helper of several modules' tests in `tests/libs/`.
- `skills/devkit-<name>/SKILL.md` is the module's skill.

## Build it on the other modules

- A module reads devkit's shared values from `../../lib.nix`.
- It reads only its own files and those of the modules that it imports, directly or through another module, never those of a module that builds on it.
- It gives its checks, generated files, setups and commands only through the options of the `checks`, `files`, `setups` and `commands` modules.
  A script built outside `mkCommand` needs a comment that gives the reason.

## Use the shared values

A tool or a file that has a setting for a value of `src/lib.nix` gets the shared value explicitly, even when it equals the tool's default.
A file or section that does not want such a setting leaves it unset, and never sets another value.
A new shared value is a constant of `src/lib.nix`, never an option, with a comment that gives why devkit needs the constant.

## One check, one module

Each verification has one module responsible for it.
A module never checks what another module checks, and relies on that module for it.

## Offer only what is needed

A module offers nothing that no repository needs today: no check, setup, generated file, command, option, override or guard.

## Test it

Each test file of `tests/modules/<name>/` is named after what it tests.
It returns an attribute set of cases, each named after what it shows.

- A case runs what the module gives: an app, a flake check, the formatter or a package of the development shell.
  When the run needs a repository, the case builds one with the `repository` helper of `tests/libs/repository.nix`.
- A case takes what it runs from `consumer`, given the module and only the configuration that the case needs, so that nothing else changes what the case tests.
- Each app has a case that succeeds and a case for each way it fails, with the status and the output that the failure must print.
- Each shared value that the module passes to a tool has a case that shows the tool receives it.
- A case shows how a tool behaves only when the module relies on that behavior.
  Its comment gives that reason.

## Document it

The module's skill describes the module as a black box: what to import, its apps, options and generated files, and how to set it up.
It never describes the modules that it builds on; it says only which ones it uses.
It links each tool rather than describing what the tool does or prints, and it points to a generated file rather than restating its rules or values.

The skill's `description` says what the module does, names devkit's module, and ends with `Use this when …`:

- a module that checks a kind of files: "Check a repository's … with …, using devkit's `…` module. Use this when setting up the … check.";
- a module for writing one's own checks, setups, commands or files: "Implement a repository-specific … with devkit's `…` module. Use this when a repository needs … that none of devkit's modules provides."

The description adds "or when it fails" only when the skill has a section for failures.

A module that checks a kind of files has a `Set it up` section with numbered steps:

1. Import `inputs.devkit.flakeModules.<name>`, as the `devkit` skill shows.
2. Run each of its setups, and commit the files that the repository keeps.
3. Run each of its checks.

## Use it in devkit

devkit's `flake.nix` imports the module of each kind of files that devkit has, in alphabetical order.

## What devkit already enforces

- `flakeModules` has one module for each directory of `src/modules`.
- The `alone` test imports each module alone and builds every check, app, shell and formatter that it gives, so that a missing import fails.
- Each command gets a `lint-<name>` flake check with ShellCheck and shfmt, built by the module's `test-<name>` check.
- A template fails to build when a replacement matches no placeholder, or when a placeholder is left unreplaced.
- The loader imports every file of `tests/modules/<name>/` as a test file, and refuses a directory that has no module.
- The workflow runs a job for each `check-<name>` app and each `test-<name>` check, so that a new module needs no change in `.github/workflows`.
- devkit runs its own checks on its files, so that `check-files` fails when devkit does not commit a file that its modules generate.

## Before pushing

Run `nix run .#check` and `nix flake check`.
The workflow builds no `lint-<name>` check of devkit's own commands, so only `nix flake check` builds them.
