# IBMulator CRT shader port

The default cabinet presentation applies an offscreen GPU port of IBMulator's
actual PS/1 CRT shader. The pinned source is IBMulator
`48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27`, specifically
`share/ibmulator/shaders/ps1/crt.slang`, the shader selected by its
`realistic_mode/stock.slangp` preset. The PS/1 monitor frame and glass/environment
passes are not included. The approved Amstrad cabinet supplies its own geometry.

The port retains the original radius-8 curved coordinate transform, optional
convergence, original B-spline texture filter and linear/sRGB transfer functions.
The default now uses interpolating Catmull-Rom sampling with zero convergence
to preserve thin CGA strokes. This sampling change is Amstrad-specific; the
original IBMulator filter remains available. Color controls
are neutral, VGA scale is 1, and reflection/ambient passes are disabled. The
scene supplies the smaller 4:3 display area inside the existing glass, so the
shader does not shrink it a second time. This shader does not add scanlines;
IBMulator's separate Lottes shader is a different effect.

The Amstrad compositor now keeps the artwork's glass beneath the video instead
of replacing the aperture with solid black. At load time it compresses reflected
luminance with `48 * (1 - exp(-luminance / 100))`, preserving the photographed
texture and edge shading while strongly reducing the upper-left studio glare.
The source PNG remains unchanged. Each repaint restores this prepared surface
before adding phosphor light with Qt's Plus composition at 90% opacity. Black
guest pixels therefore retain the same glass as the unlit screen, without a
rectangular black patch or accumulated light from earlier frames. This applies
after the CRT shader and also to the software fallback / `-NoCRT` path.

`scripts/port-ibmulator-shader.py` reproduces
`assets/shaders/ibmulator-crt.frag` from the pinned files. Original helper comments
and credits are retained. See `assets/shaders/NOTICE-IBMulator.md` and its copy
of the GPLv3 license for attribution and distribution terms. Upstream 86Box's
notices remain retained.

## Runtime

The regular launcher uses the shader by default when the Amstrad cabinet is
active. Use `"Amstrad PC1512.exe" -NoCRT` for the original software filter
(direct executable launches also honor `AMSTRAD_CRT=0`).
Set `AMSTRAD_CRT_SHADER` to an absolute fragment-shader path to override the
deployed `local/dist/shaders/ibmulator-crt.frag`. OpenGL context, shader or FBO
failure falls back to the software cabinet and logs one diagnostic; it does not
block startup with a dialog.

`AMSTRAD_CRT_SAMPLING=soft` selects the original IBMulator B-spline sampler.
`AMSTRAD_CRT_CONVERGENCE` accepts 0 through 1 (default 0); set it to `0.5`
alongside soft sampling to reproduce the previous port. Curvature is unchanged.
The source is 640x200, and the original approximating B-spline softens even
texel-aligned one-pixel strokes. At convergence 0.5 the RGB channels also shift
by up to 0.32 source pixels. The sharper interpolating sampler preserves source
texel centers; disabling convergence removes colored fringes from white text.

The GUI thread creates and destroys the `QOffscreenSurface` and creates the
native OpenGL context. It moves the context to the existing software-scaling
worker before the first `makeCurrent`; the worker then owns its context,
program, texture, VAO, VBO and FBO. It uploads a crop from the producer's real 2048-pixel-pitch
RGB32 framebuffer, renders at the inset screen's output resolution, reads an
opaque image back, and composites that image into the cabinet. Curvature makes
damage nonrectangular, so changed source frames redraw the entire video area.
Unchanged frames keep the existing buffer. Resize rebuilds the output FBO.
Shutdown closes GL resources on the worker before stopping it; only then is the
GUI-owned surface destroyed. Input and emulated hardware paths are unchanged.

The GUI-side native-context creation is deliberate. Creating that context on
the scaling worker passed the standalone test but caused an access violation
(`C0000005` in the system `opengl32.dll`) in the integrated Windows application.
Creating it on the GUI thread and moving it before first use fixed that
integration failure. The corrected full application passed the Windows GPU
acceptance run on 2026-11-14, including POST/DOS, `DIR A:`, `DIR B:`, a repeat
read of A:, focus-loss key release, resize and clean exit with token cleanup.

Successful initialization prints `Amstrad CRT active: IBMulator PS/1` followed
by parameters and the OpenGL renderer name. Failure prints
`Amstrad CRT fallback:` followed by the cause. The local Qt5 `offscreen` platform
cannot create a WGL 3.3 context, so it exercises the fallback. Background GPU
tests use the Windows platform with an offscreen surface and no shown window.
The emulator's explicit `AMSTRAD_HEADLESS=1` test mode also prevents its main
window from being shown; ordinary launches remain visible.

## Focused validation

From the repository root:

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-crt.ps1 -Platform windows
```

This standalone test uses no shown windows, desktop capture, focus changes or
host input injection. It runs GL on a worker thread, checks channel order and
top/bottom orientation with a nonzero-X crop and 2048-pixel source pitch, saves
`local/ibmulator-crt-test.png`, resizes the FBO, and closes its context on the
worker. It passed on the AMD Radeon RX 7900 XTX with exact red, blue and green
interior samples. The same test with `-Platform offscreen` reports the known
missing WGL context; this demonstrates the platform limitation, not the normal
Windows rendering path.

The sharpness regression adds one-pixel monochrome stripes at a deliberate 640
pixel output width: average adjacent contrast increased from 0.3046 with the
previous soft/convergence-0.5 settings to 1.0000 with the defaults, with zero RGB
fringe. When the captured live guest `dir-a-raw.png` exists, the test also renders
that actual 640x200 DOS frame through both settings at 492x369, matching a small
4:3 cabinet display. Compare `local/ibmulator-crt-dos-soft.png` and
`local/ibmulator-crt-dos-sharp.png`; stripe images are saved alongside them.

The application-level command is:

```powershell
rtk proxy python scripts/verify-milestone.py --shader
```

Its background test checks that the actual live guest follows the shader path,
alongside POST, DOS commands, independent floppy reads, resize, focus-loss key
release and clean exit. See `local/verification-shader/report.json` and captures
for the results of the latest run; the existence of this command is not itself
a claim that a particular run passed.
