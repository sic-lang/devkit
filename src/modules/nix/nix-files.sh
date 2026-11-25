# shellcheck shell=bash
options=()
if [ "$#" -eq 0 ]; then
  set -- :/
else
  # The paths are names, not patterns, and each must name a file or a directory that git tracks.
  export GIT_LITERAL_PATHSPECS=1
  options=(--error-unmatch)
fi
# grep fails when it selects no file, which is no error here.
# -a keeps a name that is not valid in the locale, which grep would otherwise take for binary data
# and leave out.
git ls-files -z "${options[@]}" -- "$@" | { grep -a -z '\.nix$' || [ "$?" -eq 1 ]; }
