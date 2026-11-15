# Project notes for agents

Amstrad PC1512/1640 emulator wrapper built on a patched 86Box. Repo:
andresdelcampo/AmstradPCEmu (private). Read `README.md` and `UPSTREAM.md` first.

## Git rules (important)

- `upstream/` (86Box, IBMulator) is **not tracked**. 86Box is edited in place, so
  git only protects those edits through `patches/86box-pc1512.patch`.
  **Before every commit, after touching anything under `upstream/86Box`, run
  `python scripts/export-patch.py` and include the updated patch in the commit.**
  Never commit without doing so if upstream changed.
- Never `git add` ignored areas: `upstream/`, `local/` (ROMs, disks, VM state),
  `backups/`, `assets/reference/`, `assets/front/backups/`, `*.exe`.
  Review any new large binary before committing.
- Do not change the pinned upstream commits in `UPSTREAM.md` without being asked;
  if they change, update the table and re-export the patch.
- Commit only when the user asks. Push needs `git config http.sslBackend schannel`
  (already set; antivirus HTTPS scanning breaks git's default cert bundle).
- Line endings: files are LF; Windows may warn about CRLF, which is harmless.

## Licensing

- Original code/docs: GPL-3.0-or-later (`LICENSE`). The 86Box patch stays under
  86Box terms (GPL-2.0-or-later per its README); IBMulator CRT shader is
  GPL-3.0-or-later. Front artwork is not covered; see `docs/front-artwork.md`.
- New files that go into 86Box get a header stating GPL-2.0-or-later, like 86Box.
  Do not add GPL-2.0-only or non-GPL-compatible code to the build.
