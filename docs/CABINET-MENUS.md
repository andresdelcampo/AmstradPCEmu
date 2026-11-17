# Cabinet controls

Updated 2026-11-17. Hover over either drive bay, the model badge, the monitor badge or the system unit's AMSTRAD plate for 450 ms, or left-click for immediate access. Right-click remains available. The live screen still captures the guest mouse; cabinet menus are unavailable while it is captured.

The pointer changes to a hand over each part. Briefly passing over a part cancels the pending hover. Panels open above the part where space allows, stay inside the current screen, and leave a corridor for moving into the panel. Moving away dismisses them after 400 ms. Escape and outside clicks also dismiss them. Closing a panel does not immediately reopen it under a stationary pointer.

## Design

All application menus and the custom power popup use **F4 / strong untinted frost**, selected on 2026-11-15. Material, blur strength, fallback colour and label contrast are centralized in `qt_amstradpopup.hpp` (`PopupTheme`). The earlier N6 blue is retained only as the opaque fallback.

The monitor, machine configuration and drive panels are all picture choices over the shared frosted backdrop.

The monitor selector uses the complete existing monitor photograph (casing, glass and pedestal) above the shared frosted backdrop. Colour shows the original `IMAGES/HOUSE.IMG` from the installed A5 HDUTILS disk inside the supplied GEM Paint frame, with the title changed to `HOUSE.IMG`. Monochrome shows the supplied tiger capture with its original `TIGER.IMG` title and the entire interface converted to greyscale. Source screen pixels are mapped to the PC1512's CGA/RGBI palette before CRT light falloff, scan lines and glass reflections are added. Content geometry remains flat, with straight edges and square corners. Labels, a rounded box and a tick indicate the fitted monitor. No generated monitor artwork is used. A four-colour sample using the CGA character ROM remains as a missing-asset fallback. On a PC1640 the same panel offers its three monitors, PC-MD, PC-CD and PC-ECD, each with a test picture at its own line count and a magnified detail of the scan lines; choosing one restarts the PC ([details](PC1640.md)).

Each floppy drive opens a **disk box**. The heading card shows the bay as it is, the disk in it (drawn bare, with its label) and an **Eject disk** pill; the whole card ejects, and under the pointer the bay previews the lever up. Below it:

- **System discs**: the four Amstrad discs in their sleeves. One click inserts a disc, always write-protected. Images are matched by file name (`amstrad::diskColour`) in the VM's `media` folder, the last folder an image was opened from and the folders of recent disks; the VM's own copies win, then 360K images named for the PC1512. A disc with no image is pale and asks for the file on the first click. Right-click a disc to forget its image; it then stays unlinked until one is chosen. A disc already in A: or B: is pale and labelled with its drive. On HD20 machines a fifth, purple disc joins the set: the hard disc utilities, which only came with hard disc models. The row is then five across, and the drive slot shows purple. Without a hard disc the same image is an ordinary black disk among your own.
- **Your disks**: up to eight recently used images as black disks, the file name handwritten on the label, newest first. One box serves both drives; disks in a drive are left out. Right-click takes a disk out of the box (the image file is untouched).
- **Another disk**: **Open** picks an image file, **New** creates a blank one (upstream dialog).

Write protection is the disk's own notch: a gold tab over it means protected. Click the notch (or press P on the focused disk) to fit or peel the tab without closing the panel. On a disk in the box this is remembered for its next insertion; on the disk in the drive it re-inserts the disk with the new setting; on **Open** it sets whether picked images go in protected (on by default: a refused write is obvious, a silently altered original is not). System discs keep their foil tabs. The box lives in the VM's `amstrad.ini` under `[disks]` (`recent`, `protected`, `open_protected`, `system1`-`system5`) and starts from the drives' upstream histories. Mounts made from the menu bar's Media menu are recorded too. Export to 86F remains in the Media menu.

The model badge opens **Machine configuration**, two separate choices in one panel (since 2026-11-16; before, every drive layout was listed once per computer). **Computer** is a row of two cards, **PC1512** (512K, CGA) and **PC1640** (640K, EGA), each shown by its nameplate: red "PC" and pale numerals on the grey strip in the cream casing, drawn in code (`drawNameplate`) because the lettering in the cabinet artwork is too small to enlarge. Neither machine had a logo of its own beyond that lettering. **Drives** is one vertical list of DD, SD, SD with factory sticker and HD20, named for the computer fitted (PC1640 DD, ...). Each entry shows the system unit's front cut out of the cabinet artwork (no picture well) beside its name, and the fitted one is marked like the monitor selector, with a rounded box and a tick (`drawChoiceBox` in `qt_amstradpopup.hpp`). The panel is `addMachinePanel` in `qt_amstradmenu.hpp` (`MachineChoice`, `ConfigChoice`); `scripts/preview-config.ps1` renders that same panel for each computer to `local/config-preview/`. Each choice is applied on its own, with its own restart confirmation: changing the computer keeps the drives, and the reverse. Disks, drives and the hard disk image carry over, and the badge numerals follow the machine. Arrow keys move through both groups, passing over the headings. The left bay also links to that panel. See [PC1640](PC1640.md). A disk collection box beside the computer remains an exploratory future idea.

The system unit's **AMSTRAD** plate opens **About**: the program's name and author, the 86Box version it is built on, the IBMulator release the CRT shader comes from, and the licence. The cabinet has no menu bar and so no About box; until 2026-11-17 these lines were a card shown with the parts overlay. The panel is `addAboutPanel` in `qt_amstradmenu.hpp`, the area `masterMakerBadge()` in `qt_amstradscene.hpp`.

## Finding the controls

Nothing on the cabinet says its parts are live. A small, muted **?** mark sits in the bottom-right corner of the scene. While the pointer rests on it, every live part is boxed like a hovered choice in the menus (thin light border, translucent lift; a soft dark edge keeps it readable on the cream casing) and tagged with its name and a few words on what it opens (**DRIVE A** / **DRIVE B** Insert or eject a disk, **MACHINE** Choose the drives fitted, **MONITOR** Colour or mono, **AMSTRAD** About this emulator). Drive tags follow the fit: with two drives A is left and B right; with one, the right bay is **DRIVE A** and the left reads **HARD DISK** or **DRIVE BAY**. The rear power close-up comes into view too, boxed the same way and tagged "Switch on or off" above its own POWER caption. The overlay is static: nothing moves or plays unasked. It lingers 0.6 s after the pointer leaves, then fades.

The mark scales with the cabinet, takes no clicks, and is hidden while the guest has the mouse. `AMSTRAD_HINTS=0` removes it; automated (`AMSTRAD_HEADLESS=1`) runs have it off unless `AMSTRAD_HINTS=1`. It stays in the bottom corner, apart from the window controls at the top right: it explains the machine, not the window.

The corner controls (the mark, zoom, fullscreen and exit) fade out 2.5 s after the mouse last moved anywhere over the window, leaving only the cabinet, and come back as soon as it moves. They stay while one is under the pointer or the parts are shown. `AMSTRAD_FADE_CONTROLS=0` keeps them shown; automated runs keep them unless `AMSTRAD_FADE_CONTROLS=1`. `AmstradChromeFade` in `qt_amstradhints.hpp`.

An earlier trial, timed highlights passing over each unused part, was dropped on 2026-11-16: several areas asking for attention at once for a second each was too much to take in.

`qt_amstradhints.hpp` holds the mark (`AmstradHints`), the input-transparent overlay (`AmstradHintAreas`) and the tag geometry (`hintAreas`). `scripts/test-hints.ps1` saves the scene at rest and with the parts shown to `local/hints-test/` and checks hover, linger, fade, the captured-mouse case and the corner controls' idle fade.

## Code

All source paths below are under `upstream/86Box/src/qt/`.

| Responsibility | Source |
| --- | --- |
| Hover timer, click dispatch, guest capture guard | `qt_rendererstack.cpp` / `.hpp` |
| Part geometry in master-image pixels | `qt_amstradscene.hpp`: `hotspot()` |
| Corner mark and the overlay naming each live part | `qt_amstradhints.hpp`: `AmstradHints`, `paintHintAreas` |
| Menu contents and applying configuration | `qt_mainwindow.cpp`: `showAmstradMenu`, `setAmstradModel`, `setAmstradMonochrome` |
| Shared popup theme, backdrop capture/blur, native menus and text shadows | qt_amstradpopup.hpp |
| Popup placement/dismissal, cards, grids, disk drawing | `qt_amstradmenu.hpp` |
| Photographic monitor selector and CGA sample | `qt_amstradmonitor.hpp` |
| Disk box: system disc matching, recent disks, write-protect tabs | `qt_amstraddiskbox.hpp`: `DiskBox`; recorded in `MediaMenu::floppyMount` |
| Drive panel: disk pictures, tiles, drive card | `qt_amstradmenu.hpp`: `addDrivePanel`, `DiskTile`, `DriveCard` |
| Cabinet preview crops | `SoftwareRenderer::frontPreview` |

Widgets use logical pixels and render artwork at the display pixel ratio. Cards expose accessible names and descriptions. Tab navigates focus; arrow keys move within a card grid; Enter and Space activate. Handlers close popups before running on the next event-loop pass, allowing file dialogs and confirmations to open safely.

The machine family is real emulator state (`machine`, memory, firmware), kept separate from its drive-layout variants: `amstrad::Front::pc1640` comes from the configured machine, never from a badge or bay choice. To add another family, give it the same: configuration, artwork, then a row in the grid.

## Verification

`python scripts/verify-milestone.py` runs `ui-cabinet-test` on the authenticated offscreen test socket. It opens all five hotspots through the real renderer delegate, checks delayed hover and cancellation, dismissal/reopen suppression and captured-mouse exclusion, and saves menu PNGs under `local/verification/`. Existing screen mouse-capture checks dismiss cabinet popups before inspecting button release.

`scripts/preview-disks.ps1` renders the drive panel in three states to `local/disk-preview/` and checks the disk box's bookkeeping (matching, ordering, tabs, unlinking) on a throwaway VM folder.

`scripts/preview-monitor.ps1` renders the actual monitor selector in isolation to `local/monitor-preview/monitor.png` (and the PC1640's three monitors to `monitor-1640.png` when its video ROM is installed), allowing fast visual review without deploying the emulator. It also checks fallback palette and square swatches. `scripts/extract-gem-preview.py` decodes original GEM samples from the installed DOS and HDUTILS floppies and verifies the disks remain unchanged; source/output hashes are recorded under `assets/front/monitor/`. The decoder's PC1512 sample output was checked pixel-for-pixel against FFmpeg's independent GEM decoder.

Native Windows pointer feel and multi-monitor/DPI transitions still benefit from an interactive check. Local restore points and a checksum-verified restore script are in `backups/menus-2026-11-14/`; neither restore point has been applied.

## Shared frost implementation

`installPopupTheme()` attaches the shared painter to ordinary Qt menus, including the menu bar, context menus and submenus. Custom monitor/drive/configuration panels and the power photograph frame/pill use the same theme. Pictures and control geometry stay sharp. White labels and native menu glyphs receive a small dark shadow for contrast over the light casing.

The backdrop is captured from the owning application widget tree, strongly blurred at reduced resolution, then cached while the popup is open. It refreshes when a menu opens, moves or resizes; the power surface refreshes on placement/view/power changes. It is an application-backdrop effect, not a desktop compositor effect: it does not capture other applications or continuously blur live video behind an open menu. Menus overhanging the application extend the edge pixels of its backdrop.

The implementation uses Qt Widgets painting and image effects, with no Windows Acrylic/DWM dependency. Windows is the tested build; other desktop platforms still require their normal build/runtime verification. Setting `PopupTheme::Frosted` false selects the shared solid fallback. Existing cabinet geometry and power-switch behaviour are preserved.

Run `scripts/test-popup-theme.ps1` for tint-free capture, strong diffusion, native text/action and submenu inheritance checks. Existing power inset, cabinet event and emulator smoke tests cover interaction regressions.
