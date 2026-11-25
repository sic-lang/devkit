# shellcheck shell=bash
# Runs the command after `--` on the regular files that Git tracks and that the pathspecs before
# `--` select, or on all of them without pathspecs.
pathspecs=()
while [ "$1" != -- ]; do
  pathspecs+=("$1")
  shift
done
shift
reason="Git tracks no regular file"
if [ "${#pathspecs[@]}" -gt 0 ]; then
  reason+=" that matches ${pathspecs[*]}"
fi
tracked-files -- "${pathspecs[@]}" | on-files "$reason" "$@"
