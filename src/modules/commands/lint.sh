# shellcheck shell=bash
# The builder of the command's lint runs this script with Bash, and sets these variables.
shellcheck "${script:?}"
shfmt --indent "${indentSize:?}" --diff --filename "${script##*/}" <"$script"
touch "${out:?}"
