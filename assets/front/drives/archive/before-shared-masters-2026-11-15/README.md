# Drive state patches

## Current closed-drive templates (revision 4)

The user manually corrected `masters/closed-clean.png`. Treat it as the
read-only source for the two `drive-*-closed-mechanism.png` layers. Each
`drive-*-closed-{black,yellow,green,blue,red}.png` is now **disk-only** again:
the existing disk materials are retained; only the lever occlusion is moved.
The original materials are retained under `masters/disk-materials/`.

The Qt loader combines the shared closed mechanism with the selected disk
layer once on load. Open runtime patches, approved open master, cabinet,
right face and independent LEDs are retained. Patch size and origins remain
450x180 at A (174,1006), B (632,1006).

To apply later manual closed-master corrections, run
`scripts/apply-closed-drive-master.ps1`. Historical retouch/assembly scripts
reject these current assets so they cannot overwrite the user-owned master
or restore obsolete geometry. `all-states-preview.png` shows both drives and
all disk colours. The application was rebuilt for the shared-layer loader.

## Historical geometry revision 2 (2026-11-15)

All twelve states now include corrected lever/recess artwork: the missing
lower-left inset is present, the pivot is farther right and the lever is
shorter. Closed states include both the mechanism and disk. The disk-only
description below applies to revision 1. All five disk materials are retained,
with the old lever gap filled and occlusion moved to the new lever. Disk
colour masks are updated.

The cabinet master and patch placement are unchanged. Columns 310–449 of
every state are verified pixel-identical to their previous versions. The
existing right-hand cavity surfaces are retained with feathered boundaries.

Rebuild using `scripts/assemble-drive-geometry-v2.ps1` through PowerShell.
Sources and original patches are in `local/artwork/drive-geometry-v2/`.
Legacy assemblers reject this revision to prevent restoring old geometry.
Preview: `geometry-v2-preview.png`. Exact built-in image_gen prompts:
[revision 2 prompts](../../../docs/front-drive-geometry-v2-prompts.md).

## Original revision notes

All runtime-ready assets are in this directory. Created 2026-11-14 for
`../pc1512-front.png` (1254 x 1254). The software renderer loads them from
`drives/` beside `AMSTRAD_CABINET` (override with `AMSTRAD_DRIVES`) and picks
each drive's state from 86Box's inserted-media state: open/empty when the drive
is empty, otherwise closed with a disk coloured by `amstrad::diskColour()` in
`qt_amstradscene.hpp`, which guesses from the image file name only â€” MS-DOS /
Disc 1 red, GEM / Disc 2 blue, GEM2 / GEM Desktop / BASIC 2 / Disc 3 green,
DOS Plus / Disc 4 yellow, anything else black. Animations are not connected.

Additional HDD and blank bay modules are saved here as `bay-left-hdd.png`,
`bay-left-blank.png`, `bay-left-blank-sticker.png`, `bay-right-blank.png` and
`bay-right-blank-sticker.png`. See [configuration assets](../CONFIGURATIONS.md)
for SD/HD20 badges, HDD LEDs and logical drive-letter mapping.

Each drive has six **450 x 180 RGBA PNG** states:

| State | Drive A (left) | Drive B (right) |
| --- | --- | --- |
| Open, empty | `drive-a-open-empty.png` | `drive-b-open-empty.png` |
| Closed, black disk | `drive-a-closed-black.png` | `drive-b-closed-black.png` |
| Closed, yellow disk | `drive-a-closed-yellow.png` | `drive-b-closed-yellow.png` |
| Closed, green disk | `drive-a-closed-green.png` | `drive-b-closed-green.png` |
| Closed, blue disk | `drive-a-closed-blue.png` | `drive-b-closed-blue.png` |
| Closed, red disk | `drive-a-closed-red.png` | `drive-b-closed-red.png` |

Draw the cabinet first, then exactly one drive state per drive, then the
independent LED patches. The selected states can differ between A and B.
Use top-left coordinates **A: (174, 1006), B: (632, 1006)**. Apply the same
scale/translation as the cabinet. Keep the transparent padding; do not trim
without changing placement. PNG alpha is straight, for source-over blending.
Restore the cabinet each frame before drawing a different state.

`placement.json` supplies canvas size, front SHA-256, placement, draw order
and `closed_variants` mapping keyed by `black`, `yellow`, `green`, `blue`, `red`.
The initial 450 x 150 crops were padded to 450 x 180 to remove the full old
latch shadow. The patch origin and the drive geometry are unchanged.

In open state the latch points right, matching the user's empty-drive photo.
Both drives use the same left-drive lever master at the same local coordinates;
the independently generated right-drive lever is discarded.
The original lower drive surface and straight bottom border are reconstructed
from clean neighbouring columns at the same row, preventing the earlier
generated-fill colour mismatch and shifted border. Only the latch/upper
recess and empty slit use the edited source directly.

In closed states the original cabinet supplies the exact unchanged lowered
latch and beige face. The PNG overlays **only the visible inserted disk edge**.
Every colour variant uses the same alpha/occlusion as its black counterpart.
`drive-a-disk-color-mask.png` and `drive-b-disk-color-mask.png` are opaque
grayscale masks for future edits: white is disk material, black is protected.
They are editing aids and must not be drawn as visible layers.

The coloured edge materials were generated with the built-in image_gen tool
using the supplied Amstrad system disk photograph as the colour reference,
then isolated through the existing disk masks. No labels or protruding disk
faces are shown. The later v19/v20 master repairs the false finger-well rails
and softens the over-bright case bevel. Disk overlay PNGs are unchanged.

`preview.png` shows open/empty and closed/black in cabinet context.
`all-states-preview.png` compares all six states, with drive LEDs idle.

Exact prompts: [mechanical states](../../../docs/front-drive-state-prompts.md)
and [colours](../../../docs/front-drive-colour-prompts.md). Generated originals,
user-supplied reference copies and full-front composites are under
`local/artwork/drive-states/`.

Rebuild from the project root (requires the retained generated sources):

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File scripts/assemble-drive-assets.ps1
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File scripts/assemble-drive-color-assets.ps1
```
