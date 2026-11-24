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
    lint = mkOption {
      description = "The ShellCheck and shfmt lint of the script, the `lint-<name>` flake check.";
      type = types.package;
    };
    packages = mkOption {
      description = "The packages whose programs the script runs.";
      type = types.listOf types.package;
    };
  };
}
