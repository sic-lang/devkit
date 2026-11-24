# shellcheck shell=bash
# The builder of the command's check runs this script with Bash, and sets these variables.
${dryRun:?} "${script:?}"
shellcheck "$script"
# shfmt takes its indentation from the .editorconfig of the current directory, as in a repository.
cp "${editorconfig:?}" .editorconfig
shfmt --diff --filename "${script##*/}" <"$script"
touch "${out:?}"
