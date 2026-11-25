# shellcheck shell=bash
# Runs the command between the first argument and `--` on the files that the command after `--`
# lists, each followed by a NUL character.
# The first argument says why the list can be empty, for the message of the failure.
# The names follow the command's own `--`, so that it reads no name as an option.
reason=$1
shift
command=()
while [ "$1" != -- ]; do
  command+=("$1")
  shift
done
shift
mapfile -d '' files < <("$@")
wait "$!"
# Without files, the command would search for files itself or read its standard input.
if [ "${#files[@]}" -eq 0 ]; then
  echo "No file to check: $reason" >&2
  exit 1
fi
printf '%s\0' "${files[@]}" | xargs -0 "${command[@]}" --
