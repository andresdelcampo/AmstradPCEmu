# Final badge and case-lighting prompts

Built-in image_gen, 2026-11-14. The case edit uses only a bounded brightness
gain from the generated lighting reference, multiplying original RGB pixels
to preserve their geometry/detail; all pixels outside the small bevel mask
are unchanged. The earlier apparent blur was clarified by the user as an
over-bright highlight, so no backup texture or geometry was pasted.

## Monitor MM

Use case: text-localization
Asset type: photorealistic monochrome monitor identity badge patch.
Input is the exact existing PC-CM badge, strict edit target.
Change ONLY the light-grey C to a light-grey M, so the badge reads exactly "PC-MM". Preserve the original trailing M, original red PC, hyphen, grey badge background, rounded rectangle, mounting position, letter height and baseline, existing bold plain sans-serif styling and photographic softness. Fit the new first M inside the C's original letter cell, slightly condensed if needed; do not widen or move the badge or other characters. Preserve the original beige monitor housing and lighting exactly. One edited image, SAME 7:3 framing as input. No extra text, logo or watermark.

## Case bevel exposure

Use case: lighting-weather
Image 1 exact current approved PC1512 cabinet is the EDIT TARGET. Image 2 older backup is ONLY the brightness reference for the narrow case bevel between monitor and drive fascia.
Reduce ONLY the overly bright white horizontal bevel on the SYSTEM UNIT immediately above the recessed drive fascia (approximately x110..1145, y924..938 of this 1254x1254 image). Make this broad white reflection a softer warm ivory highlight, roughly 15 to 20 RGB levels dimmer in its brightest area, consistent with the older backup. It should read as the same molded beige plastic, not a white painted stripe. Preserve every contour, strip height, edge position, microtexture and physical section, including current pedestal and all drive artwork. No added texture, blur, sharpening, new geometry or changed panel boundaries. All other pixels/lighting remain unchanged. Output same full square composition.
