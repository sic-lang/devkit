# devkit's flake, whose commit the generated settings pin.
{ devkit }:
{ flake-parts-lib, lib, ... }:
let
  inherit (lib) mkOption;
  inherit (import ../../lib.nix) marketplace plugin repository;
in
{
  imports = [ ../files ];

  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, ... }:
    let
      inherit (config.devkit.claude-code) settings;
      inherit (config.devkit.formats) json;
      pinned = devkit ? rev;
    in
    {
      options.devkit.claude-code.settings = mkOption {
        description = ''
          The repository's Claude Code settings, which the module writes to `.claude/settings.json`.
          The module adds the settings that enable devkit's plugin at the commit of devkit that the
          flake locks.
        '';
        type = json.type;
        default = { };
      };

      # Without a commit, the module generates no settings, so that the setups and checks leave the
      # committed ones as they are.
      config.devkit =
        lib.mkIf
          (lib.warnIfNot pinned (
            "devkit is at a version that no commit holds, such as a working tree with changes,"
            + " so the claude-code module does not generate .claude/settings.json"
          ) pinned)
          {
            claude-code.settings = {
              extraKnownMarketplaces.${marketplace}.source = {
                source = "github";
                repo = repository;
                ref = devkit.rev;
              };
              enabledPlugins."${plugin}@${marketplace}" = true;
            };
            files.".claude/settings.json".source = json.generate "settings.json" settings;
          };
    }
  );
}
