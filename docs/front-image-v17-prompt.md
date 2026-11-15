# v17 upper cylinder candidate

Source: approved `assets/front/pc1512-front-v16.png`.
Shape reference: `assets/front/pc1512-front-v15.png`, upper cylinder only.
Brightness reference: user-supplied real photo, `codex-clipboard-6c68384a-6b5c-4778-b111-d5bd747adb4b.png`.
Output: `assets/front/pc1512-front-v17.png`.
Method: built-in image_gen edit. A first pass was discarded because its upper cylinder was too large and bright.
Status: review candidate; runtime asset selection unchanged.

The generated support was composited onto the approved v16 source using a small feathered mask around x439..813, y830..850. This retains the original dome and seamless base connection. Verification: 1254x1254 PNG; 7,137 changed pixels inside the upper-support region and zero changed pixels outside it. Close-up: `assets/front/pc1512-pedestal-v17-detail.png`. Assembly and source copy are retained under `local/artwork/v17/`.

## Final prompt

Precise local edit. Image 1 (pc1512-front-v16.png) is the APPROVED BASE AND EDIT TARGET. Image 2 (pc1512-front-v15.png) is the SHAPE REFERENCE ONLY. Image 3 is the real hardware BRIGHTNESS reference.
Transfer ONLY the small dark UPPER CYLINDER from Image 2 to the exact same position in Image 1. This is the narrow, short support immediately below the monitor, ABOVE AND OVERLAPPING the rear of the lower beige dome. Copy its shape, width, height and shallow curved lower outline exactly from Image 2. Its top directly touches the monitor underside. It must have the same barely-visible height as Image 2, approximately 15 pixels at the middle, spanning approximately x450 to802, y831 to848 in this 1254x1254 composition. It is SHORT and NARROWER THAN THE LOWER DOME. No large sagging oval, no tall drum. The lower edge is almost parallel to the monitor underside with only a very slight downward bow.
Make ONLY THIS UPPER CYLINDER slightly dimmer than Image 2 to match Image 3: nearly black warm brown-grey deep shadow, faintly visible matte side wall. The cylinder should be hard to see as in the real photograph, with subtle light just sufficient to reveal its short wall. No bright beige band.
Keep the approved Image 1 lower dome, bottom cylinder, seamless connection with plastic base, colors and illumination EXACTLY AS THEY ARE. The cylinder simply occludes the very top/rear of this existing dome. Do not bring Image 2's lower foot or its lighting into Image 1.
All pixels outside the small upper-support region must retain Image 1's appearance. Preserve every other detail: complete monitor, display, labels, drives, power LED, cabinet, panel, background, original framing and 1254x1254 dimensions. Do not change lower dome geometry or shading. Output only the full edited Image 1.
