# Shared drive artwork

`masters/opened.png` and `masters/closed.png` are the user-owned originals.
They are preserved unchanged. Both physical bays use the same pictures:

- `drive-open-empty.png`: complete open, empty drive.
- `drive-closed-mechanism.png`: complete closed mechanism.
- `drive-closed-{black,yellow,green,blue,red}.png`: disk-only overlays.

Draw the cabinet, the open face OR closed mechanism plus chosen disk, then
the activity LEDs. All drive patches are 450 x 180 RGBA. Placement is left
(174,1006), right (632,1006); see `placement.json`. Separate bay positions
and disk states remain independent even though their images are shared.

`archive/disk-materials/disk-*.png` retains one source per disk colour.
Assembly registers the entire master face, excluding its white margins,
and copies the material into the slot as one straight, constant-height
strip (rows 57-62), interrupted only by the latch and the slanted slot ends.
Cuts are whole columns, so every drawn column is the full six rows.
The materials are complete strips with a soft lever shadow at x 95-110;
`scripts/repair-disk-materials.ps1` rebuilds them from the pristine copies
in `archive/before-shared-masters-2026-11-15/masters/disk-materials/`.
No image generation or master retouching is needed.

Rebuild with `rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File scripts/apply-drive-masters.ps1`.
The old `apply-closed-drive-master.ps1` command forwards to this script.
Master hashes are verified unchanged after assembly.

`all-states-preview.png` shows the shared six-state set;
`configurations-preview.png` shows DD, SD, sticker and HD20 combinations.
The existing HDD and blank modules remain distinct because they differ visually.

Superseded A/B patches, masks, duplicate materials and previews are retained
under `archive/before-shared-masters-2026-11-15/`. Earlier historical images
remain in `archive/`. Historical assembly scripts are not current rebuild paths.
