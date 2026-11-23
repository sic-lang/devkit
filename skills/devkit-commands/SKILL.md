---
name: devkit-commands
description: Write a command of a repository that uses devkit, as a Bash template, or give the commands an environment. Use when adding an app, a check or a setup whose script is more than one command, or when commands need environment variables.
---

# Commands

The module `commands` is the frame of every command: each one is an app, run by `nix run .#<name>`, and a flake check, which ShellCheck runs on its script.

## Write a command

A command is a Bash template of its own, `<name>.sh.in`, that `devkit.mkCommand` builds:

```nix
config.devkit.mkCommand {
  name = "example";
  template = ./example.sh.in;
  replacements.greeting = "hello";
  tools = [ pkgs.jq ];
}
```

- The template has no shebang: mkCommand puts before it a header with the interpreter, the options `errexit`, `nounset` and `pipefail`, the variables of `devkit.commandEnv`, and `tools` on `PATH`.
- Each placeholder `@name@` of the template takes its value in `replacements`, as text: quote it in the template, or give it quoted with `lib.escapeShellArg`, and a list with `lib.escapeShellArgs`.
- `bash`, `path` and `env` are the placeholders of the header: a template does not use these names.
- The build fails when a value has no placeholder or a placeholder remains, and the flake check when ShellCheck finds a fault in the script built; the template itself is not checked, since it is not Bash until its placeholders are replaced.

mkCommand returns the script, `run`, and its check, `checked`: give both to `devkit.commands.<name>` with a `description`, or to a setup.

## Give the commands an environment

`devkit.commandEnv` is a function from the arguments of mkCommand to the environment variables that the command exports, such as a variable for the commands whose `tools` include a given package.
`devkit.shell` sets the packages, the variables and the hook of the development shell.
