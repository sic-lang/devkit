lib:
let
  inherit (lib) mkOption types;
in
types.submodule {
  options = {
    run = mkOption {
      description = "The script, which the app runs.";
      type = types.package;
    };
    checked = mkOption {
      description = "The check of the script by ShellCheck, which the flake check builds.";
      type = types.package;
    };
    tools = mkOption {
      description = "The packages that the script runs.";
      type = types.listOf types.package;
    };
  };
}
