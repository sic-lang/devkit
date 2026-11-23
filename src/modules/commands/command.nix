lib:
let
  inherit (lib) mkOption types;
in
types.submodule {
  options = {
    command = mkOption {
      description = "The command, as made by `mkCommand`.";
      type = import ./built.nix lib;
    };
    description = mkOption {
      description = "The app's description.";
      type = types.str;
    };
  };
}
