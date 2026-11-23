lib:
let
  inherit (lib) mkOption types;
in
types.submodule {
  options = {
    command = mkOption {
      description = "The command, as made by mkCommand.";
      type = types.submodule {
        options = {
          run = mkOption {
            description = "The script, which the app runs.";
            type = types.package;
          };
          checked = mkOption {
            description = "The check of the script by ShellCheck, which the flake check builds.";
            type = types.package;
          };
        };
      };
    };
    description = mkOption {
      description = "The description of the app.";
      type = types.str;
    };
  };
}
