# SD / HD20 cabinet component prompts

Built-in image_gen edits, 2026-11-14. Exact prompt set follows.
Generated sources and supplied reference copies are retained under
`local/artwork/configurations/`. Runtime assets are under `assets/front/`.
HDD OFF is extracted directly from the generated HDD master, without a second
independent generation; ON changes only that lens. Sticker small print is an
AI reconstruction of the supplied photo, not a verified verbatim transcription.

## bay-hdd

Use case: precise-object-edit
Asset type: photorealistic emulator cabinet replacement patch.
Input images: Image 1 is the CURRENT artwork crop, exact edit target. Image 2 is supplied real-hardware reference.
Primary request: Replace ONLY the rectangular floppy bay face with the Amstrad PC1512 HD20 hard disk module shown on the LEFT in Image 2. Retain exactly the existing bay footprint, black perimeter and flush straight-on rectangle. The module is a solid subtly warm neutral-grey plate, slightly lighter than the surrounding dark grey fascia, with two rows of seven short horizontal black ventilation slots in its lower middle, and one small DARK RED horizontal rectangular activity LED just above the left part of the vents. LED window centered at approximately 30% of plate width, 55% of plate height; keep a physical translucent dark-red lens, switched OFF. Match the reference vent/indicator layout, no invented brand mark or text. Remove ALL floppy hardware: lever, pivot, slot, finger recesses, green LED and old lever shadow below the bay. Whole plate must have softly photographic matte texture, subtle highlights at edges, and a perfectly STRAIGHT bottom border; no ledges. Image 2 supplies structure only, not its low resolution, age or tint. Image 1 supplies cabinet palette and lighting.
Constraints: single edited image; retain Image 1 exact aspect ratio and all physical alignment, dimensions, studio lighting and original surface colours outside the specified edit. No surrounding cabinet redesign, extra control, new seam, glow, watermark or annotation. Do not enlarge or offset the bay/badge. Photographic matching, not an illustration.

## bay-blank

Use case: precise-object-edit
Asset type: photorealistic emulator cabinet replacement patch.
Input images: Image 1 is the CURRENT artwork crop, exact edit target. Image 2 is supplied real-hardware reference.
Primary request: Replace ONLY the existing floppy drive with a factory blank bay cover, like Image 2 but WITHOUT the sticker. One plain uninterrupted subtly warm neutral-grey rectangular blanking plate, slightly lighter than surrounding darker grey fascia, within the EXACT existing drive footprint and original straight black perimeter. Match its clean matte molded material and same soft cabinet studio light. Remove ALL floppy details: lever, pivot, slot, finger recesses, green LED AND the old lever's shadow beneath the bay. No vents, holes, logo, text, label, stains or adhesive residue. Perfectly straight bottom border. Image 2 is the shape reference ONLY; Image 1 is strict alignment/colour/lighting reference.
Constraints: single edited image; retain Image 1 exact aspect ratio and all physical alignment, dimensions, studio lighting and original surface colours outside the specified edit. No surrounding cabinet redesign, extra control, new seam, glow, watermark or annotation. Do not enlarge or offset the bay/badge. Photographic matching, not an illustration.

## model-sd

Use case: precise-object-edit
Asset type: photorealistic emulator cabinet replacement patch.
Input images: Image 1 is the CURRENT artwork crop, exact edit target. Image 2 is supplied real-hardware reference.
Primary request: Change ONLY the red suffix DD on the existing bottom model badge to SD, so it reads exactly "PC 1512 SD". Preserve the existing PC and 1512 letters pixel-positionally, their spacing, the grey metal strip, body and shadows. SD uses the SAME red ink hue, letter height, bold plain sans serif style and baseline as the original DD; leave its first letter at the original DD start. Reference Image 2 confirms SD model designation, not a palette/style change. No extra text. Keep identical crop/framing.
Constraints: single edited image; retain Image 1 exact aspect ratio and all physical alignment, dimensions, studio lighting and original surface colours outside the specified edit. No surrounding cabinet redesign, extra control, new seam, glow, watermark or annotation. Do not enlarge or offset the bay/badge. Photographic matching, not an illustration.

## model-hd20

Use case: precise-object-edit
Asset type: photorealistic emulator cabinet replacement patch.
Input images: Image 1 is the CURRENT artwork crop, exact edit target. Image 2 is supplied real-hardware reference.
Primary request: Change ONLY the red suffix DD on the bottom model badge to HD20, reading exactly "PC 1512 HD20". H D 2 0, no punctuation. Preserve existing PC and 1512 letters, positions, spacing and grey badge strip. HD20 must use the same red ink, same plain bold sans serif style, SAME letter height and baseline as the existing DD, using slightly narrower character spacing to fit the available grey strip to its right. Start HD20 where DD originally starts and finish before the badge's rounded right edge. Do not move PC or 1512. Reference Image 2 confirms HD20 designation but do NOT change the current red/grey styling to the black text in that photograph. Identical framing, no extra marks.
Constraints: single edited image; retain Image 1 exact aspect ratio and all physical alignment, dimensions, studio lighting and original surface colours outside the specified edit. No surrounding cabinet redesign, extra control, new seam, glow, watermark or annotation. Do not enlarge or offset the bay/badge. Photographic matching, not an illustration.

## bay-blank-sticker

Use case: precise-object-edit
Asset type: vintage computer blank bay cover sticker variant.
Image 1 is the exact APPROVED PLAIN COVER edit target; Image 2 is the user's original sticker photo.
Add ONLY the off-white rectangular factory instruction sticker with dense burgundy multilingual small print shown in Image 2, neatly applied within the plain cover in Image 1. Transfer the reference's actual visual print pattern/line rhythm, no new logo, no prominent invented heading, no handwriting. Sticker occupies about 91% of the plate width and 80% of plate height, centered, with subtle paper thickness and realistic matte ink. Do not add age stains or tears. Preserve the exact cover outline, all uncovered original cover pixels, original surrounding grey fascia, matching studio illumination, framing and 2.5:1 crop. Do not move, recolour or remodel the cover. One edited image. The cover must remain the SAME master as Image 1.

## hdd-led-on

Use case: precise-object-edit
Asset type: HDD activity LED ON photorealistic replacement crop.
Input image is the exact OFF LED in the new HD20 module, strict edit target.
Change ONLY the small horizontal dark-red rectangular lens to a clearly electrically LIT RED hard disk activity LED. Strong red emission through translucent resin with a small warm pale red/orange emitter hotspot and subtle natural diffusion, realistic rectangular window and glossy top-edge reflection. It must read as ON even at a final 20x10-pixel lens size. A faint close red spill immediately outside the lens is allowed, no huge bloom or starburst. KEEP THE EXACT LENS RECTANGLE/BEVEL/BORDER AND POSITION, existing grey plate tone and grain, ventilation slot underneath, all lighting, and same 768:640 crop aspect ratio. Do not modify or enlarge the vents. Do not create a round light. No new components or text. One edited image.

## Floppy aperture correction

Use case: precise-object-edit
Asset type: local aperture repair for existing photorealistic vintage computer drive artwork.
Image 1 is the EXACT CURRENT drive crop, edit target. Image 2 is the real hardware cavity reference only.
Remove ONLY the false BRIGHT WHITE HORIZONTAL SUPPORT/RAIL at the top of the LOWER central finger recess, immediately below the black disk insertion slit. In Image 1 this is the thin white line running approximately x525..906 y210..224 (1350x450 image). In real hardware there is NO shelf or support crossing this central opening: the inserted flexible disk bridges open air there. Replace the false rail with a dark recessed OPEN CAVITY / shadow smoothly joining the black slot to the existing lower finger well. No horizontal white edge across the unsupported middle. The left and right beige front-panel shoulders must still end naturally at the two sides of this finger well. Preserve the outside lower bevel/lip at the very BOTTOM of the finger well; it is not the erroneous line.
STRICT INVARIANTS: keep the complete lowered latch, pivot, black insertion slit geometry, drive dimensions, LED, upper finger pocket, outer frame, all beige tones and native shading everywhere else. Do not change the disk edge inside the black slot. Do not add a disk or support. Do not darken the whole recess; only replace the erroneous top rail and blend its immediate few pixels into the existing cavity shadow. Same 3:1 framing, exact alignment. One edited image.

