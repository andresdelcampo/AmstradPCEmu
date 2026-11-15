# Drive geometry correction — 2026-11-15

Built-in image_gen edits. Final generated sources retained in `local/artwork/drive-geometry-v2/{closed,open}.png`; original runtime patches in `local/artwork/drive-geometry-v2/before/`.

## Closed mechanism

Use case: precise-object-edit. Edit target Image 1 is our emulator drive crop 450x180. Images 2 and 3 are real Amstrad drive mechanical references only (open then closed). Correct Image 1, showing CLOSED lever. Preserve its exact composition, beige plastic palette, lighting, frame, slit, green LED, gray surround. Output one same 5:2 aspect crop with matching coordinates, no labels.
Three precise changes to the LEFT/CENTER mechanism only:
1. Restore the missing LOWER LEFT recessed finger pocket immediately beneath slot and lever: instead of flat face from x85 to175, create a shaded inward stepped pocket from approximately x95 to300, y75 to118, continuous with the existing lower right finger well. Its left portion has a shallow ledge and its right portion a deeper rounded inset, like reference 3. No invented vertical bright rails.
2. Move pivot and left boundary of lever/recess assembly RIGHT about 15 pixels on original 450px canvas (pivot currently x110 y32, should x125 y32). Clear old lever position naturally. Upper recess begins about x100, not x80. Keep right edge of central recess near x300.
3. Shorten the lever arm by about 15 percent, preserving dogleg and round pivot. Closed tip approximately x106 y115 (not x90 y125), entirely within lower pocket above bottom bezel. No horizontal arm extension when closed.
Pixel registration matters. Keep EVERYTHING at x>=310 unchanged. Do not move or change LED, right face, slit right endpoint, outer rectangular frame, drive bottom edge, gray background. Slot center remains y66. Source photo references supply accurate mold recess shape only; do not copy their yellow-green tint, wear or camera angle. Photographic precision, not illustration.

## Shorten closed arm

Use case: precise-object-edit. Image 1 is the edit target, the just-corrected closed drive. Preserve entire image and its framing exactly. Make ONLY the closed lever 15% shorter: keep the round pivot and the top dogleg fixed, shorten the straight vertical section at the bottom so its rounded tip stops about 10 original-canvas pixels higher (equivalently 44px in this 1983x793 image). Reconstruct the exposed lower recess behind that shortened tip. The tip must clearly stop above the bottom of the finger pocket with visible clearance. Keep the recess contours, beige color, slot and right side unchanged. One image same aspect ratio.

## Open mechanism

Use case: precise-object-edit. Image 1 is the corrected CLOSED drive edit target. Image 2 is the real OPEN mechanism reference. Change ONLY the lever state in image 1: rotate the dogleg lever to point horizontally RIGHT from the same round pivot (around x129 y33 in a 450x180 canvas). Its tip should end near x212 y48, a short rightward dogleg arm. Match reference 2's open pose: diagonal section down-right from pivot then short horizontal section to right. Remove the old vertical arm and its shadow; reveal continuous LOWER LEFT recessed finger pocket underneath. Preserve that lower pocket's new stepped geometry, bounds and shading. No flat infill over the lower left pocket! Preserve exact pivot, all mold recess boundaries, beige palette, slot y66, frame, LED and entire right side. Insertion slit is empty black. No disk or label. One image same 5:2 aspect ratio as image 1, pixel registered. Open lever should not extend past the shelf's right end.

## Register open pivot

Edit this exact image. Move ONLY the open lever, its round pivot, and its small contact shadow 9 pixels to the RIGHT in original 450x180 canvas units (40 pixels to the right at current resolution). Keep lever size, pose, recesses, all pocket boundaries, slot, everything else exactly unchanged. Repair where the pivot used to be. No other change.


