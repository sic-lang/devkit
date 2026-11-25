# shellcheck shell=bash
# Paths can select no Nix file, so nixfmt only runs on a file.
nix-files "$@" | xargs -0 --no-run-if-empty nixfmt --
