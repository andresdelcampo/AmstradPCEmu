# Amstrad PC1512 DD

A runnable Windows PC1512 emulator with the approved Amstrad cabinet around its live display. Uses a small **86Box Qt fork**, preserving its PC1512 CPU, timing, video, floppy controller and input devices. IBMulator's complete machine/shell was not transplanted.

Double-click **`Amstrad PC1512.exe`** in the project root. It starts `local/dist/86Box.exe` on the isolated `local/amstrad` VM with the external firmware, the cabinet and the CRT shader, without PowerShell or a console window. On the very first launch it creates the VM by running `scripts/prepare-vm.ps1` once, hidden; afterwards the VM and your settings are reused. Pin it to the taskbar or Start, or make a shortcut to it. `build.ps1` rebuilds it from `launcher/amstrad-launcher.c`; `scripts/launch.ps1` remains for the baseline and test-pattern modes. The cabinet opens switched off with the power close-up visible to the right of the monitor, joined by dashed lines to the button's place behind it. The window reserves space on the right for this inset; older saved windows widen once where screen space allows. Press its round rear power button to start it. Boot takes roughly 20 seconds of guest time. The supplied DOS disk installs mouse driver V5.00 and finishes at `A>`.

The executable and app window use `assets/front/pc1512-front.ico`, with transparency outside the cabinet and 16, 24, 32, 48, 64, 96, 128 and 256 pixel sizes. Its source is `assets/front/pc1512-icon-cutout.png`, extracted from the cabinet artwork using the built-in image tool ([prompt](docs/pc1512-icon-prompt.txt)). To regenerate the ICO, run `magick assets/front/pc1512-icon-cutout.png -define icon:auto-resize=256,128,96,64,48,32,24,16 assets/front/pc1512-front.ico` and rebuild.

- Type DOS commands normally. Click inside the live screen picture to capture the mouse; cabinet, glass borders and background clicks leave it free. **Ctrl+End** releases it.
- The rear power-button inset **stays visible while the PC is off**. While on, hover or click the **space to the right where the inset appears**, even while hidden, to peek behind it. The same round beige pushbutton switches the PC on and off; off leaves the cabinet open with dark glass and LEDs, and on starts a fresh boot. Right-click the inset to compare **Button close-up** and **Rear cable bay**; the choice is remembered per VM. [Power button details and references](docs/POWER-BUTTON.md).
- **Ctrl+F12** sends Ctrl+Alt+Del directly to the guest in windowed or fullscreen mode. It is also available as **Action → Send Ctrl+Alt+Del to the PC**. There is no reset-button control. Release the captured mouse with Ctrl+End before using the cabinet's power switch.
- On the PC1512, the modern ISO key between left Shift and Z sends the original key's `2Bh` scan code (including key release). The guest BIOS and DOS keyboard driver determine its character for the selected language; with `KEYBUK`, it types `\`, or `|` with Shift.
- Use the upstream **Media** menu to insert/eject disks independently in A: and B:.
- Hover briefly over the cabinet's drive bays, model badge or monitor badge to open graphical controls, or left-click to open them immediately. Right-click also works. Choose disks using labelled floppy cards; configuration and monitor choices show picture previews. Move away, click outside or press Escape to dismiss. [Menu details](docs/CABINET-MENUS.md).
- Resize freely: the cabinet stays square and the inset display stays 4:3.
- The front image is transparent outside the hardware. The whole rendering area uses the former backdrop's sampled charcoal (`#13131c`), including wide/tall margins and fullscreen.
- Press **F11** or **Alt+Enter** to switch between windowed and fullscreen. The existing Ctrl+Alt+PageUp shortcut also remains available.
- The first launch opens fullscreen. Later launches restore the last fullscreen, maximized or windowed state while the cabinet is still off. Power-on preserves the current window mode and leaves the mouse free. **Alt+F4** closes the app even while the mouse is captured. Keep **View → Remember size & position** enabled to restore window size and position.
- The **View** menu keeps only options that affect the cabinet: toolbar/status bar, remember size & position, and the filter method when the CRT shader is off. Upstream renderer, scale factor, stretch, aspect-ratio, HiDPI, composite and extra-monitor options are hidden; the window is always resizable and uses the software renderer.
- The IBMulator CRT port keeps curvature with sharper sampling for CGA text and no colour fringe by default. Add `-NoCRT` after the launcher in a shortcut's target to disable it. [Shader details](docs/IBMULATOR-CRT.md).
- The display preserves the cabinet's dark glass, reflection and edge shading beneath the live picture. The upper-left highlight is softened for readability; black video pixels retain the unlit glass surface, including with `-NoCRT`.
- The cabinet's front LEDs are live: the red **power** LED is lit while the machine runs, and each drive's green LED is lit while that drive's emulated motor runs, like a real drive. It stays on for the guest BIOS's motor-off delay after the last access (about 2 s, the same moment the spindle sound stops). 86Box's per-command activity flag is also included. Patches load from `assets/front/leds/` beside the cabinet image (override with `AMSTRAD_LEDS`); if missing, the photographed LEDs remain.
- Both drives are 5.25-inch 360K. Initially mounted disk copies are write-protected.
- Both drives use 86Box's **Panasonic JU-475-5 180K/360K, 40-track** motor and seek sounds. Change each drive's Audio profile in **Settings → Floppy & CD-ROM drives**; the upstream Mute control also silences them.
- The HD20's hard disk uses 86Box's **Miniscribe 8425, 3600 RPM, 1987** spindle and seek sounds: a 20 MB MFM drive of the same era and class as the HD20's. Fitting the HD20 from the cabinet menu selects it; change it in **Settings → Hard disks**. Head seeks click while DOS reads and writes C:. Upstream's XT MFM controller never set up its drive's seek geometry and only moved the head for DMA transfers, so the fork fixes both; the HD20 BIOS uses PIO, whose timing is unchanged.
- Firmware stays under `C:\Emulators\86Box\roms`; original disks stay under `C:\Emulators\86Box\Disks`. Working copies and VM state are ignored under `local/`.

Build and launch with the installed MSYS2 MinGW64 toolchain:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/launch.ps1 -Wait
```

Requires `C:\msys64\mingw64` with GCC, CMake, Ninja, Qt5, SDL2, OpenAL, and the libraries resolved by CMake. Paths with spaces were built successfully. Scripts change PATH only for their own process. Optional MIDI engines, dynarec, disassembler, Discord and translations are disabled; the PC1512 model is unchanged. Runtime DLLs are deployed beside the executable.

Deployment also copies the installed 86Box floppy sound profiles, recordings and attribution from `C:\Emulators\86Box\assets\sounds\fdd` into `local/dist/assets/sounds/fdd`. Hard disk profiles and recordings are copied likewise from `C:\Emulators\86Boxssets\sounds\hdd` into `local/dist/assets/sounds/hdd`; the deployed table plays the Miniscribe's own spin-down recording (the upstream table reuses spin-up). For another installation, pass `-FloppySoundSource <path>` and `-HardDiskSoundSource <path>` to `scripts/build.ps1` or `scripts/deploy.ps1`. Fresh VMs select Panasonic audio for both drives; existing VM preferences are preserved. No sample synthesis or extra sound card is required.

For a fresh **pinned** source checkout, apply `patches/86box-pc1512.patch` with `scripts/apply-patch.ps1` before building. The patch and upstream notices are retained. No firmware/system disks are included.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-scene.ps1
python scripts/verify-milestone.py
python scripts/verify-milestone.py --shader
python scripts/verify-milestone.py --floppy-sounds
```

Verification boots a separate disposable VM offscreen, issues scancode keyboard input, reads both drives, tests focus-loss key release, saves application/raw captures and checks clean exit. Normal launches open no automation socket. [Milestone report](docs/MILESTONE-1.md) records exact revisions, results and limitations. [Implementation handoff](docs/IMPLEMENTATION-HANDOFF.md) records the initial scope; floppy sounds are now enabled, while other mechanical sounds, disk animations and full GEM/mouse compatibility work remain later stages.

The floppy sound check records the dedicated FDD stream during independent reads of A: and B:, checks that it returns to silence between reads, and verifies profile persistence. [Floppy sound verification](docs/FLOPPY-SOUNDS.md).

86Box source: `978030cd0dc626bab794e74c8ddaa512c1a9fcc9` (7.0 development). Installed comparison: 6.0 build 9001. See `upstream/86Box/COPYING` and [artwork provenance](docs/front-artwork.md). No claim of hardware-exact fidelity.

## Working with git

Read [UPSTREAM.md](UPSTREAM.md) first. `upstream/` (86Box, IBMulator) is not tracked, and 86Box is edited in place, so git only protects those edits through `patches/86box-pc1512.patch`.

- **Before every commit that follows changes under `upstream/86Box`, run `python scripts/export-patch.py` and commit the updated patch.**
- Do not commit ignored areas: `upstream/`, `local/` (ROMs, disks, VM state), `backups/`, `assets/reference/`, `assets/front/backups/`, built `*.exe`. Review any new large binary first.
- Do not change the pinned upstream commits in `UPSTREAM.md` without a reason; if they change, update the table and re-export the patch.
- Pushing needs `git config http.sslBackend schannel` (already set in this clone; antivirus HTTPS scanning breaks git's default certificate bundle).
- New files that go into 86Box carry a GPL-2.0-or-later header, like 86Box. Do not add GPL-2.0-only or GPL-incompatible code to the build.

## License

Original code, scripts and documentation in this repository are licensed under
the [GNU GPL, version 3 or later](LICENSE).

Third-party and derived parts keep their own terms:

- `patches/86box-pc1512.patch` modifies [86Box](https://github.com/86Box/86Box)
  (GPL-2.0; see `upstream/86Box/COPYING`) and remains subject to 86Box's licensing for the files it touches.
- `assets/shaders/` contains a port of IBMulator's CRT shader (GPL-3.0-or-later);
  see `assets/shaders/NOTICE-IBMulator.md`.
- Front-panel artwork is not covered by the licence above; see
  [artwork provenance](docs/front-artwork.md).
- Amstrad and PC1512/PC1640 are trademarks of their respective owners. ROMs and
  software are not included and remain the user's own.
