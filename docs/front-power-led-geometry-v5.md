# Power LED geometry revision 5

2026-11-16. The user supplied a real PC1512 front-panel photograph and a crop of the emulator for size/position comparison.

Relative to the drive face, the photographic reference suggests a lens approximately 25% smaller than the previous one, with a slightly upright oval outline. This is a visual alignment estimate from differently framed/perspective photographs, not a measured physical dimension.

The power patch remains 48 x 48 at (208, 960), so runtime placement and executable are unchanged. Inside it, both approved photographic lens sources are resampled with center (17, 27) and radii (7.2, 7.8), giving cabinet center (225, 987) and nominal lens size 14.4 x 15.6. Previous center was (232, 983.5), radii (9.6, 10). The bright ON source remains power-on-v4.png; OFF remains power-off-v3.png.

The old larger lens is erased by a clean panel backplate before the smaller lens is composited into the master. This prevents the old lens or rim showing around or beside the new one. Backplates were generated with the built-in image_gen tool and color-matched during final compositing; source/working assets are retained in local/artwork/led-states/geometry-v5/. Lens resampling, masking and compositing use the existing System.Drawing asset pipeline, identically for both states. Runtime patches cover only the new lens.

The user also requested moving the POWER label. Its original letter shapes are extracted as ink, reduced to 75%, and placed alongside the new lens: source rectangle (248, 978, 48, 14), destination (238, 982, 36, 10.5). Visible ink begins near (240, 984), centered vertically on the lens. The master contains the moved lettering and a matching smaller OFF lens. Only the 96 x 48 rectangle at (208, 960) changes; source pixels outside it are verified unchanged. The old label footprint is repaired against the surrounding grey panel.

Rebuild: rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File scripts/assemble-led-assets.ps1 -PowerOnly

The power-only operation preserves the current drive/HDD PNGs and their current placement coordinates. Preview assembly now draws the shared closed drive mechanism before its disk-only layer, matching the runtime. No executable rebuild is required.

Previous assets and assembly script are preserved locally in local/artwork/led-states/geometry-v5/before/. Current comparison: assets/front/leds/power-states-preview.png.

## Backplate image edit prompt

Use case: precise-object-edit
Asset type: clean grey metal front-panel background plate for an existing LED sprite.
Input image 1 is the EDIT TARGET, an enlarged 48-pixel-square crop of the vintage computer front panel.
Remove the round red LED completely, including its thin bright mounting edge, dark seating shadow and all red reflections. Fill its entire footprint with a seamless continuation of the surrounding plain grey panel, retaining the panel's very subtle top-to-bottom lighting gradient and soft photographic surface. The result must have NO LED, no circle, no indentation or halo: just the original grey panel with the existing partial black P at the far right unchanged. Do not add surface texture or sharpen the enlarged bitmap.
Constraints: keep EXACT square crop, panel color, brightness, smooth gradient, slight image softness and partial P position/letter shape unchanged. Only remove the indicator and reconstruct the panel under it. One image, no labels, no new hardware. This is a hidden compositing backplate; do not redesign anything.


## Label cleanup prompt

Use case: precise-object-edit
Asset type: clean vintage computer grey panel backplate for moving its label.
Input image is the edit target. Remove ONLY the black word POWER completely, including the faint pale fringe around the letters. Reconstruct seamless plain grey panel underneath. Preserve exactly the existing red LED, its position/size, lighting gradient, panel shade and softness and all framing. No new label, no new hardware, no remaining letter outlines. This will be used as a compositing backplate; the original lettering will be repositioned separately. One image matching the wide input composition.
