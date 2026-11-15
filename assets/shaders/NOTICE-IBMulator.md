This directory contains a port of the actual CRT shader used by IBMulator's
`realistic_mode/stock.slangp`, not a generic CRT effect labelled as IBMulator.

Upstream: https://github.com/barotto/IBMulator
Pinned revision: `48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27`.
IBMulator is by Marco Bortolin and licensed under GPL version 3 or later;
the license text is retained as `COPYING-IBMulator`.

`ibmulator-crt.frag` incorporates `ps1/crt.slang`, `ps1/functions.glsl`,
`common/filter_bicubic.glsl`, and `common/color_functions.glsl` from
`share/ibmulator/shaders`. Original helper comments and credits are retained.
`scripts/port-ibmulator-shader.py` reproduces the adaptation from those sources.

The port retains curvature (radius 8), optional RGB convergence, original
B-spline sampling, and linear/sRGB color transfer. An Amstrad-specific
interpolating Catmull-Rom sampler is now the default, with convergence zero,
to keep thin 640x200 CGA glyphs readable. Set `AMSTRAD_CRT_SAMPLING=soft` and
`AMSTRAD_CRT_CONVERGENCE=0.5` for the prior upstream-style sampling/convergence.
The added sampling kernel is an adaptation, not original IBMulator code.
The port replaces IBMulator's uniform blocks with
standalone uniforms and fixes color controls to neutral values. Display scale
is 1, because the Amstrad cabinet supplies the aperture and aspect. The PS/1
monitor frame, environment map, ambient lighting and reflection passes are
omitted so no second monitor/glass layer covers the approved artwork.

The new offscreen filter glue is also GPL-3.0-or-later. Builds incorporating
this GPL-3.0-or-later component must be distributed under compatible GPLv3
terms; upstream 86Box notices and its GPL-2.0-or-later license remain retained.
