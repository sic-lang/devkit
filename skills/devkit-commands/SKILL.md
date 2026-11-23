---
name: devkit-commands
description: Implement a custom repository-specific command as a Bash template using devkit's commands module, and set the environment variables of every command of a repository. Use this when a repository requires a command of its own, or when its commands need environment variables.
---

# Commands

The module `commands` is the frame of every command: each one is an app, run by `nix run .#<name>`, and a flake check, which ShellCheck runs on its script.

## Write a command

A command is a Bash template of its own, `<name>.sh.in`, such as `example.sh.in`:

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

- The template has no shebang: mkCommand puts before it a header with the interpreter, the options `errexit`, `nounset` and `pipefail`, the variables of `devkit.commandEnv`, and `tools` on `PATH`, and the command runs from the root of the repository.
- Each placeholder `@name@` of the template takes its value in `replacements`, as text: quote it in the template, or give it quoted with `lib.escapeShellArg`, and a list with `lib.escapeShellArgs`.
- `bash`, `path` and `env` are the placeholders of the header: a template does not use these names.
- The build fails when a value has no placeholder or a placeholder remains, and the flake check when ShellCheck finds a fault in the script built; the template itself is not checked, since it is not Bash until its placeholders are replaced.

mkCommand returns the command; `devkit.commands.<name>`, with a `description`, makes it the app `<name>`, which passes its arguments to the script as `"$@"`.

## Give the commands an environment

`devkit.commandEnv` applies to every command of the repository, those of the modules of devkit included: it is a function from the arguments of mkCommand to the environment variables that the command exports, such as a variable for the commands whose `tools` include a given package.
`devkit.shell` sets the packages, the variables and the hook of the development shell.
