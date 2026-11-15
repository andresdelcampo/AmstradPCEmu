# Approved photographic drive masters

`open-empty-approved.png` is the user's exact keeper image, copied without
editing. Its SHA-256 is recorded in `masters.json` and checked by the finishing
script. Do not regenerate, retouch, overwrite or rebuild this master.

`closed-user-draft.png` is the user's composite defining the closed geometry.
`closed-clean.png` is now **manually corrected by the user** after the initial
built-in image_gen colour/seam cleanup. Do not overwrite or retouch it using
the historical generation/finishing scripts. The distinct upper back wall, shelf, riser and lower ledge, the
lower stepped recess, and the real closed lever profile are authoritative.
Do not simplify these into single slopes or round-bottomed pockets.

The final pass uses a bounded paste-seam mask to keep the right face and LED
exactly unchanged. The open master is read only. These full-resolution masters
supersede the earlier generated candidates as visual references. The closed
master now supplies both shared runtime closed-mechanism layers. Existing
disk materials stay separate, with only the lever cut moved. Rebuild these
dependents using `scripts/apply-closed-drive-master.ps1`.

Exact prompt: [closed composite cleanup](../../../../docs/front-drive-user-composite-cleanup.md).
Historical generation sources remain under `local/artwork/drive-geometry-v3/`.
They are not authoritative for the manually corrected closed master.
