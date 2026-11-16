# Changes to upstream software

GPL requires modified versions to carry prominent notice of the changes. This
project modifies **86Box** (https://github.com/86Box/86Box, pinned commit in
[UPSTREAM.md](UPSTREAM.md)). Changes were made by the project author between
2026-11 and the release date; the authoritative, complete record is
`patches/86box-pc1512.patch` (also applied in the source archive that ships with
each release). In summary:

- **Cabinet user interface**: new Qt files `qt_amstradscene.hpp`, `qt_amstradmenu.hpp`,
  `qt_amstradpopup.hpp`, `qt_amstradpower.hpp`, `qt_amstradmonitor.hpp`,
  `qt_amstraddiskbox.hpp`, `qt_amstradhints.hpp` and changes to
  `qt_mainwindow`, `qt_mediamenu`, `qt_rendererstack` and `qt_softwarerenderer`
  to draw the Amstrad PC1512 front panel, drive and power controls.
- **CRT filter**: `qt_ibmulatorcrt.hpp` and `assets/shaders/ibmulator-crt.frag`, a
  port of IBMulator's CRT shader (GPL-3.0-or-later, see
  `assets/shaders/NOTICE-IBMulator.md`).
- **Floppy audio** (`fdd_audio`) and ST-506 XT hard-disk controller (`hdc_st506_xt.c`)
  adjustments, and `m_amstrad.c` machine changes.
- **Automation socket** (`automation.c`, `runctl.h`) used by the verification scripts;
  disabled in normal launches.
- **Cassette support removed**: `device/cassette.c` and `include/86box/cassette.h`
  (PCE-derived, GPL-2.0-only) are replaced by an independent no-op stub. No Amstrad
  machine has a cassette port.
- Build and configuration changes in `CMakeLists.txt`, `config.c`, `qt_defs.hpp`,
  `qt_main.cpp`, resources.

The IBMulator-derived files are modified adaptations of IBMulator
(https://github.com/barotto/IBMulator, pinned in UPSTREAM.md).
