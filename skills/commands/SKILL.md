---
name: commands
description: Implement a custom repository-specific command in Bash using devkit's `commands` module, and set environment variables for all of a repository's commands. Use this when a repository requires a command of its own, or when its commands need environment variables.
---

# commands

The `commands` module builds a repository's commands.
Each command becomes an app, run with `nix run .#<name>`.

## Write a command

A command is Bash code in the Nix file itself, which `devkit.mkCommand` builds with nixpkgs' [`writeShellApplication`](https://nixos.org/manual/nixpkgs/unstable/#trivial-builder-writeShellApplication).
This example builds a command that prints a JSON object:

```nix
config.devkit.mkCommand {
  name = "example";
  packages = [ pkgs.jq ];
  text = ''
    jq -n --arg greeting ${lib.escapeShellArg "hello"} --arg first "''${1-}" '{$greeting, $first}'
  '';
}
```

- The script runs from the repository's root, with the programs of `packages` on `PATH`, the variables from `devkit.commandEnv`, and the Bash options `errexit`, `nounset` and `pipefail`.
- A Nix value goes into the code by interpolation, quoted with `lib.escapeShellArg` (`lib.escapeShellArgs` for a list); a Bash expansion that starts with `${` is written `''${` in the Nix string.
- The build fails if Bash or ShellCheck rejects the script, or if shfmt would format it differently.

`devkit.commands.<name>` exposes its `command` as the `<name>` app, with a `description`.
The app passes its arguments to the script as `"$@"`.

## Give the commands an environment

`devkit.commandEnv` sets environment variables for every command in the repository, including those that devkit's modules build themselves.
Set it to a function that receives the arguments given to `mkCommand`, with their defaults, and returns the variables to export.
`writeShellApplication` writes a value that holds a quote, or that reads as a command, in a way that ShellCheck rejects, so such a value fails the build.
For example, every command that runs Lean gets `LEAN_GITHASH`:

```nix
devkit.commandEnv =
  { packages, ... }:
  lib.optionalAttrs (lib.elem pkgs.lean4 packages) { LEAN_GITHASH = "${pkgs.lean4}"; };
```

## Configure the development shell

The `commands` module also defines the repository's development shell, which `nix develop` starts.
With the `envrc` module, [direnv](https://direnv.net) also loads it, as the `devkit:envrc` skill shows.
`devkit.shell.packages` adds packages to it, `devkit.shell.env` sets its environment variables, and `devkit.shell.shellHook` runs commands when it starts:

```nix
devkit.shell = {
  packages = [ pkgs.nixd ];
  env.LEAN_GITHASH = "${pkgs.lean4}";
};
```
