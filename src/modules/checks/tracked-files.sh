# shellcheck shell=bash
# Lists the files that git ls-files selects with the given arguments, each followed by a NUL
# character, keeping only those that are regular files in the working tree.
# Git also tracks symbolic links and submodules, and still lists a file deleted from the working
# tree, which a tool would walk as a directory or fail to read.
# A symbolic link to a regular file stays, as the tools read it as that file.
git ls-files -z "$@" | while IFS= read -r -d '' file; do
  if [ -f "$file" ]; then
    printf '%s\0' "$file"
  fi
done
