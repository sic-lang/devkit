---
name: devkit-reuse
description: Check a repository's licenses with REUSE and write their texts from the SPDX license list, using devkit's reuse module. Use this when setting up a repository's licenses, when the reuse or licenses check fails, or when adding a third-party file.
---

# Licenses

The `reuse` module checks with [REUSE](https://reuse.software) that every file of the repository has a copyright and a license, and writes the license texts from the SPDX license list.

## Set it up

1. Import `inputs.devkit.flakeModules.reuse`, as the `devkit` skill shows.
2. Write a `REUSE.toml` with one annotation that covers every file:

   ```toml
   version = 1

   [[annotations]]
   path = "**"
   SPDX-FileCopyrightText = "2026 The Sic Contributors"
   SPDX-License-Identifier = "Apache-2.0"
   ```

3. Run `nix run .#setup-licenses`, which writes the license texts into `LICENSES/`, then `nix run .#check-reuse` and `nix run .#check-licenses`.

## What the checks require

- `nix run .#check-reuse` runs `reuse lint`.
- `nix run .#check-licenses` requires that:
  - every file in `LICENSES/` is named `<id>.txt`, where `<id>` is a license or exception of the SPDX list, and holds exactly its text;
  - every license and exception comes from the SPDX list, without `LicenseRef-` or `AdditionRef-`;
  - every copyright and license comes from `REUSE.toml`, never from a file header or a `.license` file;
  - `REUSE.toml` has exactly one annotation whose path is the string `"**"`, with the copyright `<year> The Sic Contributors`.

A third-party file gets its own annotation in `REUSE.toml`, after the `"**"` one, since REUSE applies the last annotation that matches a file.

## Write the license texts

`nix run .#setup-licenses` rewrites every text in `LICENSES/` from the SPDX list, adds the texts that REUSE reports as missing, and removes those it reports as unused.
It leaves untouched, and reports, any text or license that is not on the SPDX list.
