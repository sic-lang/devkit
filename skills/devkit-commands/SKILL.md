---
name: devkit-commands
description: Implement a custom repository-specific command as a Bash template using devkit's commands module, and set the environment variables of every command of a repository. Use this when a repository requires a command of its own, or when its commands need environment variables.
---

# Commands

The `commands` module builds the commands of a repository: each command is an app, run by `nix run .#<name>`, and a flake check, which runs ShellCheck on its script.

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
  tools = [ pkgs.jq ];
}
```

- The template has no shebang: mkCommand adds a header that sets the interpreter, the Bash options `errexit`, `nounset` and `pipefail`, the variables of `devkit.commandEnv` and the `PATH` of the tools, then moves to the repository's root.
- Each placeholder `@name@` is replaced by its value in `replacements`, as plain text: quote it in the template, or quote the value with `lib.escapeShellArg`, or a list with `lib.escapeShellArgs`.
- The header uses the placeholders `bash`, `path` and `env`, so a template cannot use these names.
- The build fails when a replacement has no placeholder or a placeholder is left, and the flake check fails when ShellCheck finds a fault in the built script; the template itself is not checked, since it is not valid Bash until its placeholders are replaced.

`devkit.commands.<name>` turns the command into the app `<name>`, with a `description`; the app passes its arguments to the script as `"$@"`.

## Give the commands an environment

`devkit.commandEnv` sets environment variables for every command of the repository, including those of devkit's modules.
It is a function that takes the arguments given to mkCommand and returns the variables, so it can, for instance, set a variable only for the commands whose tools include a given package.

`devkit.shell` sets the packages, the variables and the hook of the development shell.
