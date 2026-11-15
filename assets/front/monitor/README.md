# GEM Paint monitor preview

`gem-house-original.png` is decoded directly from `IMAGES/HOUSE.IMG` on the
installed `PC1512 A5 - HDUTILS.img`: 480×159, four bitplanes. It supplies the
colour monitor. The monochrome monitor uses the tiger GEM Paint capture below,
including greyscale toolbox and palette controls.

For the colour preview, `gemPaintHouse()` reuses the GEM Paint menu, tools,
palette and scrollbars from that capture, replaces the canvas with the decoded
house, and redraws the document title as `C:\GEM\IMG\HOUSE.IMG` using the
emulator character ROM. This is a composed preview, not a captured running house
session. The tiger preview retains its original `TIGER.IMG` title.

`scripts/extract-gem-preview.py` reads the installed floppy images without
modifying them and converts GEM run-length/planar pixels to PNG. It also exports
the original one-plane tiger and the separate PC1512 promotional sample.
`original-samples.json` records original and converted hashes, dimensions and
pixel aspect metadata, plus before/after disk hash verification.

`gem-paint-tiger.png` is the exact PNG supplied by the user in this chat on
2026-11-14. It is a GEM Paint screen capture showing the original tiger artwork,
toolbox and colour/pattern choices. It was copied without resizing, retouching,
AI reconstruction or colour changes. Copyright remains with its original owners;
no new licence is asserted.

Source provided by the user:
https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTlig0Io9lIYYod-wKJ2Vl0diPU2KTmuDuzNTo8JlPedw&s=10

The selector maps the supplied screen capture to the PC1512's sixteen-colour
CGA/RGBI palette at render time (the thumbnail contains extra interpolation
colours). The source PNG itself is unchanged. It adds that image to the existing
cabinet photograph, keeping the content flat and converting the same image to luminance for PC-MM. The
original monitor artwork is unchanged. If the image is missing, a four-colour
CGA sample using the emulator character ROM is used instead.

The original `IMAGES/TIGER.IMG` (384×152, one bitplane) and `TIGER.GEM` were also
found by read-only inspection of the installed `PC1512 A1 - MSDOS.img`. Extracted
working copies are under `local/gem-tiger-source/`; the original floppy image
was not modified. The supplied full screen capture was selected because its
colour palette and pattern controls illustrate the colour/monochrome difference.
