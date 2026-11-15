# Additional cabinet assets

Saved 2026-11-14. `configurations.json` contains placement, filenames, canvas
size, front SHA-256 and component selection mappings for later app use.
This asset task does not wire the new SD/HD20/MM selections into the emulator.

| Component | Files | Top-left | PNG size |
| --- | --- | --- | --- |
| HDD, left bay | `drives/bay-left-hdd.png` | 174, 1006 | 450 x 180 |
| Blank, plain/sticker, left | `drives/bay-left-blank.png`, `bay-left-blank-sticker.png` | 174, 1006 | 450 x 180 |
| Blank, plain/sticker, right | `drives/bay-right-blank.png`, `bay-right-blank-sticker.png` | 632, 1006 | 450 x 180 |
| Model suffix DD/SD/HD20 | `badges/model-dd.png`, `model-sd.png`, `model-hd20.png` | 870, 1164 | 216 x 76 |
| Monitor CM/MM | `badges/monitor-cm.png`, `monitor-mm.png` | 923, 743 | 140 x 60 |
| HDD activity OFF/ON | `leds/hdd-off.png`, `hdd-on.png` | 276, 1056 | 48 x 40 |

All files are straight-alpha RGBA. Keep transparent padding. Draw the cabinet,
selected bay/floppy patches, selected badges, then installed devices' LEDs.
Restore the cabinet each frame; apply the same scale and translation to all
patches. Do not draw a floppy activity LED over a blank or HDD bay.

The current master has a transparent exterior with cleaned antialiased edges.
Its canvas and all component coordinates are unchanged. The previous opaque
master is `backups/pc1512-front-before-transparency.png`; rebuild alpha with
`scripts/make-front-transparent.ps1`. The emulator fills its whole rendering
area with sampled charcoal `#13131c`. See the
[edit prompt](../../docs/front-transparency-prompt.txt). The icon is unchanged.

**DD:** floppy A left/B right, DD suffix. **SD:** blank left, single floppy A
right, SD suffix. **HD20:** HDD left, floppy A right, HD20 suffix. Right blank
variants also allow other layouts, including both bays blank; no unsupported
factory model designation is invented for a no-drive arrangement.

Existing floppy filenames `drive-a`/`drive-b` describe LEFT/RIGHT visual
positions. In SD/HD20 the right-hand floppy is logically A: despite the
`drive-b` image filenames. The configuration mapping records that distinction.

Badge patches change only the model suffix or first white monitor letter;
the existing PC/1512, hyphen, trailing monitor M and housings are retained.
HDD OFF is extracted from the assembled module; ON matches the same window.
The plain and sticker blank plates share one master.

The current front/v19 removed the false bright supports across the two
floppy finger wells. Current front/v20 additionally softens only the bright
case bevel above the drives, preserving the original pixels' geometry and
texture. Ten inserted-disk overlay PNGs remain byte-identical to before the
aperture repair. Earlier masters remain available.

Built-in image_gen supplied the new module, sticker, suffix glyphs, lit lens
and lighting reference. Sticker print is a visual AI reconstruction of the
supplied photograph, not a verified verbatim transcription. Prompts are in
[front-configuration-prompts.md](../../docs/front-configuration-prompts.md)
and [front-final-detail-prompts.md](../../docs/front-final-detail-prompts.md).
Generated sources/reference copies are under `local/artwork/configurations/`;
case brightness sources are under `local/artwork/case-edge/`.

Rebuild new components with `scripts/assemble-configuration-assets.ps1`
after rebuilding the existing drive states. It refreshes HDD LED metadata.
`configurations-preview.png` is a compositing preview of SD plain/sticker
and HD20 idle/active. `badges/monitor-preview.png` compares CM/MM.
`case-highlight-comparison.png` shows the final brightness correction.
