lib:
let
  inherit (lib) mkOption types;
in
types.submodule {
  options = {
    command = mkOption {
      description = "The command, as made by mkCommand.";
      type = import ./built.nix lib;
    };
    description = mkOption {
      description = "The description of the app.";
      type = types.str;
    };
  };
}
