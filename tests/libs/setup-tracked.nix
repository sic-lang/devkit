# Writes the generated files of the module whose apps are `apps`, then has Git track them with the
# files of the case.
apps: "${apps.setup-files.program} && git add -A"
