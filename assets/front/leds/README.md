# Front LED replacement assets

HDD additions: `hdd-off.png` and `hdd-on.png`, **48 x 40 RGBA**, at
**(276, 1061)** in the left HD20 module. Use only with that module installed.
See [configuration assets](../CONFIGURATIONS.md). `placement.json` includes
this indicator and the current front hash.

Six original **48 x 48 RGBA PNG** patches matching `../pc1512-front.png`
cabinet (1254 x 1254). Created 2026-11-14. Red power and green floppy
activity indicators each have an on and an off state. Each drive has its own
patches to preserve its slightly different lens size and surrounding recess.

The photographic power revision replaces **both red power states** with the
same translucent ruby epoxy lens, retaining reflections and visible internal
detail. OFF uses `power-off-v3.png`; the brighter ON uses `power-on-v4.png`.
Both use the same lens mask, without the previous broad glow.
The 2026-11-16 geometry revision makes both power lenses approximately 25%
smaller and slightly taller than wide, shifting their centers a little left
and down to match the supplied photograph relative to the drive face.
Within the unchanged power patch, center is (17, 27), radii (7.2, 7.8).
The master now includes the smaller OFF lens and the moved, smaller POWER
lettering. Old lens and lettering footprints are restored to grey panel.
Green drive and HDD patches and all runtime placement coordinates are unchanged.

| Indicator | Off | On | Top-left x, y |
| --- | --- | --- | --- |
| Power | `power-off.png` | `power-on.png` | 208, 960 |
| Drive A (left) | `drive-a-off.png` | `drive-a-on.png` | 511, 1019 |
| Drive B (right) | `drive-b-off.png` | `drive-b-on.png` | 969, 1019 |

Draw the cabinet first, then alpha-composite **one state per indicator** at
the listed position. All coordinates use the cabinet's top-left origin.
Apply the same scale/translation as the cabinet, including any letterboxing.
The transparent padding is part of the 48 x 48 placement rectangle: do not
trim it without adjusting the coordinates. These are standard straight-alpha
PNG files. For a renderer requiring premultiplied alpha, let its image loader
perform the conversion.

Always start each frame with the cabinet and draw the selected patches;
repeatedly blending states over the previous frame will leave traces.
Even off states must be drawn, because the master contains coloured LEDs.
The drive states are independent. No screen, cabinet or badge pixels need
to be replaced. The runtime (`src/qt/qt_amstradscene.hpp`, `paintLeds`)
loads these patches from this folder; the coordinates are duplicated there.

`placement.json` contains the coordinates, filenames, canvas dimensions and
SHA-256 of the exact front used. Recheck alignment if the front changes.
`preview.png` shows all off above all on, with enlarged lens details.
`power-states-preview.png` compares just the current red power states.

The lenses were edited with the built-in image_gen tool using enlarged crops
of this cabinet, then resampled and masked into the original lens geometry.
The power patches draw the smaller lens with feathered edges over the updated
master, preserving the repositioned POWER lettering in both electrical states.
These are photographic-style AI edits, not newly
sourced photographs. Later v19/v20 front corrections affect only floppy
finger-well rails and the case bevel; LED placement is unchanged.

Current geometry and backplate prompt: [front-power-led-geometry-v5.md](../../../docs/front-power-led-geometry-v5.md).
Power lens prompts: [front-power-led-v3-prompts.md](../../../docs/front-power-led-v3-prompts.md).
Earlier and drive prompts: [front-led-prompts.md](../../../docs/front-led-prompts.md).
Generated source images and full-front composites are preserved under
`local/artwork/led-states/`. Rebuild the patches with
`rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File scripts/assemble-led-assets.ps1`
from the project root; this requires those local generated source images.
