# shellcheck shell=bash
# Formats the Nix files that git tracks, under the given paths or in the whole repository. Paths can
# select no Nix file, so nixfmt only runs on a file.
nix-files "$@" | xargs -0 --no-run-if-empty nixfmt --
