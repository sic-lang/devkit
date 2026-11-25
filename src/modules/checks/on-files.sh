# shellcheck shell=bash
# Runs the command given after the first argument on the files that the standard input lists, each
# followed by a NUL character.
# The names follow the command's own `--`, so that it reads no name as an option.
# The first argument says why the list is empty, for the message of the failure.
reason=$1
shift
mapfile -d '' files
# Without files, the command would search for files itself, untracked ones included.
if [ "${#files[@]}" -eq 0 ]; then
  echo "No file to check: $reason" >&2
  exit 1
fi
printf '%s\0' "${files[@]}" | xargs -0 "$@" --
