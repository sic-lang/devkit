# shellcheck shell=bash
# Runs the command after `--` on the regular files that Git tracks and that the pathspecs before
# `--` select, or on all of them without pathspecs.
# The names follow the command's own `--`, so that it reads no name as an option.
pathspecs=()
while [ "$1" != -- ]; do
  pathspecs+=("$1")
  shift
done
shift
mapfile -d '' files < <(tracked-files -- "${pathspecs[@]}")
wait "$!"
# Without files, the command would search for files itself, untracked ones included.
if [ "${#files[@]}" -eq 0 ]; then
  message="No file to check: Git tracks no regular file"
  if [ "${#pathspecs[@]}" -gt 0 ]; then
    message+=" that matches ${pathspecs[*]}"
  fi
  echo "$message" >&2
  exit 1
fi
printf '%s\0' "${files[@]}" | xargs -0 "$@" --
