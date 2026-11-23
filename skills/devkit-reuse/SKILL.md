---
name: devkit-reuse
description: Check a repository's licenses with REUSE and write their texts from the SPDX license list, with devkit's `reuse` module. Use this when setting up a repository's licenses, when the `reuse` or `licenses` check fails, or when adding a third-party file.
---

# Licenses

The `reuse` module uses [REUSE](https://reuse.software) to check that every file in the repository has a copyright and a license.
It also writes the license texts from the SPDX license list.

## Set it up

1. Import `inputs.devkit.flakeModules.reuse`, as the `devkit` skill shows.
2. Write at least this `REUSE.toml`, whose annotation covers every file:

   ```toml
   version = 1

   [[annotations]]
   path = "**"
   SPDX-FileCopyrightText = "2026 The Sic Contributors"
   SPDX-License-Identifier = "Apache-2.0"
   ```

3. Run `nix run .#setup-licenses` to write the license texts into `LICENSES/`.
   Then run `nix run .#check-reuse` and `nix run .#check-licenses`.

## What the checks require

- `nix run .#check-reuse` expects `reuse lint` to pass.
- `nix run .#check-licenses` requires that:
  - every file in `LICENSES/` is named `<id>.txt`, where `<id>` is a license or exception on the SPDX list, and contains exactly that license's or exception's text;
  - every copyright and license comes from `REUSE.toml`, never from a file header or a `.license` file;
  - every license and exception is on the SPDX list: no `LicenseRef-` or `AdditionRef-` identifiers;
  - `REUSE.toml` has exactly one annotation whose path is the string `"**"` and whose copyright is `<year> The Sic Contributors`.

A third-party file gets its own annotation in `REUSE.toml`, after the `"**"` one, since REUSE applies the last annotation that matches a file.

## Write the license texts

`nix run .#setup-licenses` rewrites every text in `LICENSES/` from the SPDX list, adds the texts that REUSE reports as missing, and removes those it reports as unused.
It reports any text or license that is not on the SPDX list, and leaves it untouched.
