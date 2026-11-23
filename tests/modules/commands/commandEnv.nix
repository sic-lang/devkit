{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  example.EXAMPLE = "it's set";
  inherit
    (consumer [
      flakeModules.checks
      {
        perSystem.devkit = {
          commandEnv = args: lib.optionalAttrs (lib.elem pkgs.hello args.tools) example;
          checks = {
            with-hello = {
              tools = [ pkgs.hello ];
              command = "printenv EXAMPLE";
            };
            without-hello.command = "printenv EXAMPLE";
          };
        };
      }
    ])
    apps
    ;
in
{
  with-tool = repository {
    name = "with-tool";
    command = apps.check-with-hello.program;
    output = [ "it's set" ];
  };
  without-tool = repository {
    name = "without-tool";
    command = apps.check-without-hello.program;
    status = 1;
  };
}
