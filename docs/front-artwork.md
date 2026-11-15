# Static front artwork — review candidate

Current asset update, 2026-11-14: `assets/front/pc1512-front.png` now has a
transparent exterior and cleaned antialiased silhouette. Its 1254 x 1254
canvas, cabinet interior and overlay coordinates are preserved. The emulator
paints sampled charcoal `#13131c` across its whole rendering area. The icon
was already transparent and is unchanged. The preceding opaque master is
`assets/front/backups/pc1512-front-before-transparency.png`; see the
[edit prompt and refinement notes](front-transparency-prompt.txt).
The review history below describes the earlier v1/v2 assets, now in
`assets/front/backups/`.

Date: 2026-11-13. Status: **appearance of v2 explicitly approved by the user; production layering remains unfinished**.

## Delivered files

- `assets/front/pc1512-front-v2.png`: main static review image, **1254 x 1254 pixels**, opaque charcoal background. Generated with the built-in image tool, then inspected visually. No functionality or motion.
- `assets/front/pc1512-front-v1.png`: earlier transparent cutout. Retained for traceability; visible edge contamination makes it unsuitable as the accepted cutout master.
- `docs/front-image-prompt.txt`: exact initial generation prompt.
- `docs/front-image-cleanup-prompt.txt`: exact v2 editing prompt.

The tool produced 1254 x 1254 despite requesting higher resolution. This is the actual native output, not a 2K/4K master. A simple upscale would not establish extra historical detail.

## Reference and transformation

The inspected source photograph is [DOS Days PC1512 CM2](https://www.dosdays.co.uk/topics/images/Amstrad_PC1512_CM2.jpg), linked on its [PC1512 picture page](https://www.dosdays.co.uk/computers/Amstrad%20PC1000/pics.php). A local research copy is `assets/reference/amstrad-pc1512-cm-dosdays.jpg`. Its redistribution provenance is unresolved; keep it out of any published package. See the [reference review](visual-reference-review.md) for a potentially corresponding Marcin Wichary CC BY 2.0 original that was not retrieved successfully.

The initial generation used this photograph as its identity reference. It reconstructed a centered front view of monitor and base, removed the keyboard/mouse/room, cleaned the materials, and blanked the CRT. The second generation kept the machine and replaced the defective transparent exterior with dark charcoal. These are AI reconstructions, not photographs, calibrated photogrammetry or measured CAD renders. No claim that AI generation resolves source-photo rights is made.

## Visual review

The main visible identity cues are retained: PC-CM bezel/badge, circular pedestal, two side-by-side 5.25-inch mechanisms with left-side latches, recessed grey base fascia, red power light, and the later red/grey PC1512 DD markings. V2 has a clean silhouette and readable labels at its native size.

The rendering is still idealised: surfaces are cleaner than the reference, small drive recesses/latches and typography have been reconstructed, and proportions have not been calibrated against a measured frontal photograph. The first prompt's physical-size wording was a target, not a measurement of the result. Do not certify exact hardware fidelity from visual resemblance.

The blank CRT contains baked lighting; a later live screen needs an aperture mask and separated reflection treatment. The power LED is baked on while the screen is blank. The image represents a static presentation state, not a verified power-off state. No layered controls, alpha-clean production cutout or screen mask is supplied yet.

The user accepted the appearance and authorized the internals stage with this image if practical. Do not regenerate or redesign it without a specific need. Layer preparation and accuracy validation remain separate from that approval.
