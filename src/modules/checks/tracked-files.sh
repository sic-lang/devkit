# shellcheck shell=bash
# Lists the files that git ls-files selects with the given arguments, each followed by a NUL
# character, keeping only those that are regular files in the working tree.
# Git also lists submodules, and files deleted from the working tree, which a tool would walk as a
# directory or fail to read.
# Git tracks the target path of a symbolic link but not the target's content, so the list leaves
# out symbolic links, even those to regular files.
git ls-files -z "$@" | while IFS= read -r -d '' file; do
  if [ -f "$file" ] && [ ! -L "$file" ]; then
    printf '%s\0' "$file"
  fi
done
