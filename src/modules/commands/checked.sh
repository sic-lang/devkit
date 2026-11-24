# shellcheck shell=bash
# The builder of the command's check runs this script with Bash, and sets these variables.
${dryRun:?} "${script:?}"
shellcheck "$script"
shfmt --indent "${indentSize:?}" --diff --filename "${script##*/}" <"$script"
touch "${out:?}"
