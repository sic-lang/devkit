{
  consumer,
  lib,
  modules,
  pkgs,
  repository,
  ...
}:
let
  revision = "0123456789abcdef0123456789abcdef01234567";
  inherit (modules { rev = revision; }) claude-code;
  # The settings that enable devkit's plugin at the commit `revision`.
  plugin = {
    extraKnownMarketplaces.sic-lang.source = {
      source = "github";
      repo = "sic-lang/devkit";
      ref = revision;
    };
    enabledPlugins."devkit@sic-lang" = true;
  };
  # Writes the settings with the setup of a flake that imports `module`, then runs `after`.
  case =
    name: module: after:
    repository {
      inherit name after;
      command = (consumer [ module ]).apps.setup-files.program;
      output = [ "created .claude/settings.json" ];
    };
  # Fails unless the written settings equal `expected`.
  equals = expected: ''
    ${lib.getExe pkgs.jq} -e --argjson expected ${lib.escapeShellArg (builtins.toJSON expected)} \
      '. == $expected' .claude/settings.json
  '';
in
{
  writes = case "writes" claude-code (equals plugin);
  # The repository's own settings are written with those of the plugin.
  merges = case "merges" {
    imports = [ claude-code ];
    perSystem.devkit.claude-code.settings.permissions.allow = [ "Bash(nix run:*)" ];
  } (equals (plugin // { permissions.allow = [ "Bash(nix run:*)" ]; }));
  # A setting that reads as a placeholder is written as it is.
  placeholder = case "placeholder" {
    imports = [ claude-code ];
    perSystem.devkit.claude-code.settings.env.EXAMPLE = "@HOME@";
  } (equals (plugin // { env.EXAMPLE = "@HOME@"; }));
  # A setting that the module sets to another value fails the evaluation of the flake.
  conflict =
    assert
      !(builtins.tryEval
        (consumer [
          claude-code
          { perSystem.devkit.claude-code.settings.enabledPlugins."devkit@sic-lang" = false; }
        ]).apps.setup-files.program
      ).success;
    pkgs.emptyFile;
}
