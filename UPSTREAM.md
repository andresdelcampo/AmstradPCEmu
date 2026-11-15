# Upstream sources

`upstream/` is not tracked in this repository. Clone each project there at the
pinned commit below. Our changes to 86Box live in `patches/86box-pc1512.patch`.

| Project   | URL                                    | Pinned commit                              |
|-----------|----------------------------------------|--------------------------------------------|
| 86Box     | https://github.com/86Box/86Box.git     | 978030cd0dc626bab794e74c8ddaa512c1a9fcc9   |
| IBMulator | https://github.com/barotto/IBMulator.git | 48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27 |

IBMulator is a reference only (UI direction, CRT shader); it is not modified.

## Restore from scratch

```
git clone https://github.com/86Box/86Box.git upstream/86Box
git -C upstream/86Box checkout 978030cd0dc626bab794e74c8ddaa512c1a9fcc9
git clone https://github.com/barotto/IBMulator.git upstream/IBMulator
git -C upstream/IBMulator checkout 48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27
powershell scripts/apply-patch.ps1
```

## Important

The 86Box working tree is edited in place. After changing anything under
`upstream/86Box`, run `python scripts/export-patch.py` and commit the updated
patch; otherwise those edits are not protected by git.
