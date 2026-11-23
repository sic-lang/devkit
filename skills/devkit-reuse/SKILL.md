---
name: devkit-reuse
description: Check and write the licenses of the files of a repository with REUSE and the SPDX license list, through the module reuse of devkit. Use when setting up the licenses of a repository, when the checks reuse or licenses fail, or when adding a file of a third party.
---

# Licenses

The module `reuse` checks that every file of the repository has its copyright and license, with [REUSE](https://reuse.software), and writes the texts of the licenses from the SPDX license list.

## Set it up

1. Import `inputs.devkit.flakeModules.reuse`, as the skill `devkit` shows.
2. Write `REUSE.toml` with one annotation for every file:

   ```toml
   version = 1

   [[annotations]]
   path = "**"
   SPDX-FileCopyrightText = "2026 The Sic Contributors"
   SPDX-License-Identifier = "Apache-2.0"
   ```

3. Run `nix run .#setup-licenses`, which writes the texts of `LICENSES/`, then `nix run .#check-reuse` and `nix run .#check-licenses`.

## What the checks require

- `nix run .#check-reuse` runs `reuse lint`.
- `nix run .#check-licenses` requires that:
  - every file of `LICENSES/` is named `<id>.txt`, with `<id>` a license or exception of the SPDX list, and is exactly its text;
  - every license and exception is of the SPDX list, without `LicenseRef-` or `AdditionRef-`;
  - every copyright and license comes from `REUSE.toml`, not from a file header or a `.license` file;
  - `REUSE.toml` has exactly one annotation whose path is `"**"`, as a string, whose copyright is `<year> The Sic Contributors`.

A file of a third party gets its own annotation in `REUSE.toml`, after the annotation `"**"`, since REUSE applies the last annotation that matches a file.

## Write the texts

`nix run .#setup-licenses` rewrites every text of `LICENSES/` from the SPDX list, adds the texts that REUSE reports missing, and removes those that it reports unused; it reports, without touching it, a text or a license that is not of the SPDX list.
