# Cabinet controls

Updated 2026-11-14. Hover over either drive bay, the model badge or the monitor badge for 450 ms, or left-click for immediate access. Right-click remains available. The live screen still captures the guest mouse; cabinet menus are unavailable while it is captured.

The pointer changes to a hand over each part. Briefly passing over a part cancels the pending hover. Panels open above the part where space allows, stay inside the current screen, and leave a corridor for moving into the panel. Moving away dismisses them after 400 ms. Escape and outside clicks also dismiss them. Closing a panel does not immediately reopen it under a stationary pointer.

## Design

All application menus and the custom power popup use **F4 / strong untinted frost**, selected on 2026-11-15. Material, blur strength, fallback colour and label contrast are centralized in `qt_amstradpopup.hpp` (`PopupTheme`). The earlier N6 blue is retained only as the opaque fallback.

The first-pass configuration and disk menus remain available for evaluation: card layouts, picture wells and selection ticks. Disk controls use drawn 5.25-inch floppies with paper labels, plus an open-drive preview for eject. Empty drives disable eject. Their visual direction has not been approved; further work is focused on the monitor selector.

The monitor selector uses the complete existing monitor photograph (casing, glass and pedestal) above the shared frosted backdrop. Colour shows the original `IMAGES/HOUSE.IMG` from the installed A5 HDUTILS disk inside the supplied GEM Paint frame, with the title changed to `HOUSE.IMG`. Monochrome shows the supplied tiger capture with its original `TIGER.IMG` title and the entire interface converted to greyscale. Source screen pixels are mapped to the PC1512's CGA/RGBI palette before CRT light falloff, scan lines and glass reflections are added. Content geometry remains flat, with straight edges and square corners. Labels and a simple underline indicate the fitted monitor. No generated monitor artwork is used. A four-colour sample using the CGA character ROM remains as a missing-asset fallback.

Each drive offers **Choose disk**, **Choose protected disk**, **New disk** and **Eject disk**. Recent disks appear in a submenu as labelled floppy cards (the first four), followed by any further history entries. Each drive keeps its independent upstream MediaMenu history. The file chooser works without configuring a collection folder. Export to 86F remains in the menu bar Media menu.

The model badge opens **Machine configuration**, with DD, SD, SD with factory sticker, and HD20. The left bay also links to that panel. Hardware changes retain the existing restart confirmation. The generic grid and cards can accommodate future PC1640 configurations; PC1640 emulation is not implemented by this change. A disk collection box beside the computer remains an exploratory future idea.

## Code

All source paths below are under `upstream/86Box/src/qt/`.

| Responsibility | Source |
| --- | --- |
| Hover timer, click dispatch, guest capture guard | `qt_rendererstack.cpp` / `.hpp` |
| Part geometry in master-image pixels | `qt_amstradscene.hpp`: `hotspot()` |
| Menu contents and applying configuration | `qt_mainwindow.cpp`: `showAmstradMenu`, `setAmstradLeftBay`, `setAmstradMonochrome` |
| Shared popup theme, backdrop capture/blur, native menus and text shadows | qt_amstradpopup.hpp |
| Popup placement/dismissal, cards, grids, disk drawing | `qt_amstradmenu.hpp` |
| Photographic monitor selector and CGA sample | `qt_amstradmonitor.hpp` |
| Actual disk history actions | `qt_mediamenu.hpp`: `floppyHistoryActions` |
| Cabinet preview crops | `SoftwareRenderer::frontPreview` |

Widgets use logical pixels and render artwork at the display pixel ratio. Cards expose accessible names and descriptions. Tab navigates focus; arrow keys move within a card grid; Enter and Space activate. Handlers close popups before running on the next event-loop pass, allowing file dialogs and confirmations to open safely.

To add a machine family later, give it real emulator configuration/state and artwork, then populate the same configuration grid. Keep the machine family separate from its drive-layout variants. Do not infer PC1640 hardware from a PC1512 badge or bay choice.

## Verification

`python scripts/verify-milestone.py` runs `ui-cabinet-test` on the authenticated offscreen test socket. It opens all four hotspots through the real renderer delegate, checks delayed hover and cancellation, dismissal/reopen suppression and captured-mouse exclusion, and saves menu PNGs under `local/verification/`. Existing screen mouse-capture checks dismiss cabinet popups before inspecting button release.

`scripts/preview-monitor.ps1` renders the actual monitor selector in isolation to `local/monitor-preview/monitor.png`, allowing fast visual review without deploying the emulator. It also checks fallback palette and square swatches. `scripts/extract-gem-preview.py` decodes original GEM samples from the installed DOS and HDUTILS floppies and verifies the disks remain unchanged; source/output hashes are recorded under `assets/front/monitor/`. The decoder's PC1512 sample output was checked pixel-for-pixel against FFmpeg's independent GEM decoder.

Native Windows pointer feel and multi-monitor/DPI transitions still benefit from an interactive check. Local restore points and a checksum-verified restore script are in `backups/menus-2026-11-14/`; neither restore point has been applied.

## Shared frost implementation

`installPopupTheme()` attaches the shared painter to ordinary Qt menus, including the menu bar, context menus and submenus. Custom monitor/drive/configuration panels and the power photograph frame/pill use the same theme. Pictures and control geometry stay sharp. White labels and native menu glyphs receive a small dark shadow for contrast over the light casing.

The backdrop is captured from the owning application widget tree, strongly blurred at reduced resolution, then cached while the popup is open. It refreshes when a menu opens, moves or resizes; the power surface refreshes on placement/view/power changes. It is an application-backdrop effect, not a desktop compositor effect: it does not capture other applications or continuously blur live video behind an open menu. Menus overhanging the application extend the edge pixels of its backdrop.

The implementation uses Qt Widgets painting and image effects, with no Windows Acrylic/DWM dependency. Windows is the tested build; other desktop platforms still require their normal build/runtime verification. Setting `PopupTheme::Frosted` false selects the shared solid fallback. Existing cabinet geometry and power-switch behaviour are preserved.

Run `scripts/test-popup-theme.ps1` for tint-free capture, strong diffusion, native text/action and submenu inheritance checks. Existing power inset, cabinet event and emulator smoke tests cover interaction regressions.
