# Front LED replacement assets

HDD additions: `hdd-off.png` and `hdd-on.png`, **48 x 40 RGBA**, at
**(276, 1061)** in the left HD20 module. Use only with that module installed.
See [configuration assets](../CONFIGURATIONS.md). `placement.json` includes
this indicator and the current front hash.

Six original **48 x 48 RGBA PNG** patches matching `../pc1512-front.png`
cabinet (1254 x 1254). Created 2026-11-14. Red power and green floppy
activity indicators each have an on and an off state. Each drive has its own
patches to preserve its slightly different lens size and surrounding recess.

The current power states follow the improved lens in the front master. Its
center is (232, 986), or (24, 26) inside the unchanged 48 x 48 patch at
(208, 960). Both states keep that lens's circular outline, dark seating
shadow, pale lower rim and surrounding POWER lettering. `power-off-master.png`
supplies a deep ruby interior; `power-on-master.png` supplies a restrained
warm luminous core. The overlay affects only the lens interior, leaving the
front master's mounting details intact. These two compact source crops are
tracked here so the power patches can be rebuilt with `-PowerOnly`.
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

`placement.json` contains the coordinates, filenames and canvas dimensions.
Recheck alignment if the front changes.
`preview.png` shows all off above all on, with enlarged lens details.
`power-states-preview.png` compares just the current red power states.

The current power source crops were edited with the built-in image_gen tool
using the improved lens from the front master, then resampled and feathered
into its original interior geometry. These are photographic-style AI edits,
not newly sourced photographs. Earlier power geometry is documented in
`front-power-led-geometry-v5.md`; the current front image takes precedence.

Earlier geometry and backplate prompt: [front-power-led-geometry-v5.md](../../../docs/front-power-led-geometry-v5.md).
Earlier power lens prompts: [front-power-led-v3-prompts.md](../../../docs/front-power-led-v3-prompts.md).
Earlier and drive prompts: [front-led-prompts.md](../../../docs/front-led-prompts.md).
Full-size generated source images and full-front composites are preserved under
`local/artwork/led-states/`. Rebuild the power patches with
`rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File scripts/assemble-led-assets.ps1 -PowerOnly`.
Rebuild all patches with
`rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File scripts/assemble-led-assets.ps1`
from the project root; the full rebuild requires local generated drive sources.
