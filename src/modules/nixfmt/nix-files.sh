# Lists the Nix files that git tracks under the given paths, or in the whole repository without
# paths, relative to the current directory and each followed by a NUL character.
if [ "$#" -eq 0 ]; then
  set -- :/
fi
# grep fails when it selects no file, which is no error here.
git ls-files -z -- "$@" | { grep -z '\.nix$' || [ "$?" -eq 1 ]; }
