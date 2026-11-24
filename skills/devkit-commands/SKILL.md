---
name: devkit-commands
description: Implement a custom repository-specific command as a Bash template using devkit's `commands` module, and set environment variables for all of a repository's commands. Use this when a repository requires a command of its own, or when its commands need environment variables.
---

# commands

The `commands` module builds a repository's commands.
Each command becomes an app, run with `nix run .#<name>`.
Each command also gets a flake check, `lint-<name>`.

## Write a command

A command is written as a Bash template in its own file, such as `example.sh.in`:

```bash
jq -n --arg greeting "@greeting@" --arg first "${1-}" '{$greeting, $first}'
```

`devkit.mkCommand` builds it:

```nix
config.devkit.mkCommand {
  name = "example";
  template = ./example.sh.in;
  replacements.greeting = "hello";
  packages = [ pkgs.jq ];
}
```

- The template has no shebang.
  `mkCommand` prepends a header that sets the interpreter, the Bash options `errexit`, `nounset` and `pipefail`, the variables from `devkit.commandEnv`, and a `PATH` that includes the programs of `packages`.
  The header then changes to the repository's root.
- Each `@name@` placeholder is replaced with its value from `replacements`, as plain text.
  Either quote the placeholder in the template, or quote the value with `lib.escapeShellArg` (`lib.escapeShellArgs` for a list).
- The header uses the `bash`, `path` and `env` placeholders, so templates cannot use these names.
- The build fails if a replacement matches no placeholder, or if a placeholder is left unreplaced.
  The flake check fails if ShellCheck finds a problem in the built script, or if shfmt would format it differently.
  The template itself is not checked, because it is not valid Bash until its placeholders are replaced.

`devkit.commands.<name>` exposes its `command` as the `<name>` app, with a `description`.
The app passes its arguments to the script as `"$@"`.

## Give the commands an environment

`devkit.commandEnv` sets environment variables for every command in the repository, including those that devkit's modules build themselves.
Set it to a function that receives the arguments given to `mkCommand`, with their defaults, and returns the variables to export.
For example, Lake notices a new Lean only if `LEAN_GITHASH` identifies it, so every command that runs Lean needs this variable:

```nix
devkit.commandEnv =
  { packages, ... }:
  lib.optionalAttrs (lib.elem pkgs.lean4 packages) { LEAN_GITHASH = "${pkgs.lean4}"; };
```

## Configure the development shell

The `commands` module also defines the repository's development shell, which `nix develop` starts.
`devkit.shell.packages` adds packages to it, `devkit.shell.env` sets its environment variables, and `devkit.shell.shellHook` runs commands when it starts:

```nix
devkit.shell = {
  packages = [ pkgs.nixd ];
  env.LEAN_GITHASH = "${pkgs.lean4}";
};
```
