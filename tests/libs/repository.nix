{ lib, pkgs }:
{
  name,
  files ? { },
  before ? "",
  command,
  arguments ? [ ],
  status ? 0,
  output ? [ ],
  after ? "",
}:
let
  install = file: source: "install -D -m 644 -- ${source} ${lib.escapeShellArg file}";
in
pkgs.runCommand name { nativeBuildInputs = [ pkgs.git ]; } ''
  export HOME=$TMPDIR
  mkdir repository
  cd repository
  git init -q
  ${lib.concatLines (lib.mapAttrsToList install files)}
  ${before}
  status=0
  ${command} ${lib.escapeShellArgs arguments} >"$TMPDIR/output" 2>&1 || status=$?
  cat "$TMPDIR/output"
  [ "$status" -eq ${toString status} ]
  ${lib.concatMapStrings (line: ''
    grep -qF -- ${lib.escapeShellArg line} "$TMPDIR/output"
  '') output}
  ${after}
  touch "$out"
''
