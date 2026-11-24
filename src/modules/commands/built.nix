lib:
let
  inherit (lib) mkOption types;
in
types.submodule {
  options = {
    run = mkOption {
      description = "The script that the app runs.";
      type = types.package;
    };
    checked = mkOption {
      description = "The ShellCheck and shfmt check of the script, which the flake check builds.";
      type = types.package;
    };
    packages = mkOption {
      description = "The packages whose programs the script runs.";
      type = types.listOf types.package;
    };
  };
}
