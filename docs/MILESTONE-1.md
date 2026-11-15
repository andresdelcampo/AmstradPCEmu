# First runnable milestone

Implemented 2026-11-14. The local Windows build boots the real 86Box PC1512 core and displays POST/DOS inside the unchanged approved cabinet. This is a small 86Box Qt fork, not an IBMulator hardware replacement.

## Architecture

The focused local check found `screen_renderer.h` depends on IBMulator's VGA types; `screen_renderer_opengl.cpp` depends on `VGADisplay`, `gui_opengl.h`, `program.h` and `g_program.config().find_shader_asset`. Extracting that renderer would require configuration/shader infrastructure and a second shell. The handoff's Qt fallback preserves the complete existing PC1512 machine and upstream controls with fewer moving parts. No fake IBM devices, child backend, window reparenting, screenshot-based video source or custom IPC were added.

`RendererStack::blit` still copies the core RGB32 buffer into bounded upstream staging buffers and releases the blitter. `SoftwareRenderer` uses its existing scaling worker and double-buffer ownership. The cabinet image is immutable. The GUI publishes layouts; the worker scales/composes frames. Input and disks retain upstream paths. The authenticated automation interface is enabled only for explicit test launches.

The default presentation now applies the actual [IBMulator CRT shader port](IBMULATOR-CRT.md) before cabinet composition. The GUI creates the native OpenGL context and moves it to the worker; shader/FBO work and cleanup stay on the worker. This remains an in-process presentation path using the live guest buffer. The menu is retained; the optional toolbar is hidden initially.

The 1254-square master is unchanged. Glass aperture: **(258,159), 738x540**, rounded by 18 master pixels. The live 4:3 picture: **(303,186), 648x486**, with 45-pixel horizontal and 27-pixel vertical dark margins, increased following the user's PC-CM photo. Both use one uniform scale and centered square layout. Baked reflection is replaced inside the glass opening, avoiding doubled glass layers.

## Exact inputs

| Item | Identity |
| --- | --- |
| 86Box source | `978030cd0dc626bab794e74c8ddaa512c1a9fcc9`, reports 7.0 development |
| Installed baseline | `C:\Emulators\86Box\86Box.exe`, 6.0 build 9001 observed in title |
| IBMulator reference | `48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27` |
| Toolchain | MinGW64 GCC 15.2, Qt 5.15.17, SDL2, OpenAL, Release x64 |
| Final executable SHA256 | `5472121e95abd676cd8e2b12ec409226b0bb1f51a17fe5de70e676b42784a4bf` |
| Machine | `pc1512`, 8086, 8,000,000 Hz, 512 KiB, internal video/mouse, dual `525_2dd`, no HD/CD/expansion sound |
| Firmware | External `C:\Emulators\86Box\roms\machines\pc1512\40043`, `40044`, `40078` |
| A: | `PC1512 A1 - MSDOS.img`, SHA256 `a151f5c35958341955374c3c5fdb790d7ecaa247dbd65c3d25ac944f5bde9f2f` |
| B: | `PC1512 A2 - GEM1.img`, SHA256 `9376a894ed7f3c8114d011d5b5b8cd2339e820e2f044b604b2b1bb0c4f1c9bc1` |

`prepare-vm.ps1` checks ROM/media presence and sizes, copies disks only if absent, records original/copy hashes and preserves existing configs. Both images are 368640 bytes, mounted through `wp://` after config normalization. Firmware hashes are in [the inventory](local-86box-inventory.md). ROMs are not copied into source/deployment.

VMs: `local/amstrad` for normal use, `local/baseline` for installed 6.0, `local/verify-vm` and `local/verify-pattern-vm` for tests. Each has separate config/NVR/media and explicit `-O .../global.cfg`. No original disk was mounted writable.

## Acceptance

Installed **6.0** visibly booted Amstrad POST and DOS with mouse V5.00 at `A>`. Host SendInput did not reach its native keyboard hook, so input/drive commands remain unverified in that version. Desktop control stopped when the user requested it; subsequent checks ran in the background.

Modified **7.0** passed through `QT_QPA_PLATFORM=offscreen` and authenticated loopback automation. `screenshot-ui` captures the actual Qt composite; `screenshot` captures the core frame. Neither is used as the running video's source.

| Check | Evidence |
| --- | --- |
| POST/DOS | Real `AMSTRAD PC 512k (V1)` and `A>` after mouse V5.00 startup |
| Keyboard | Set-1 make/break events issue `DIR A:`, `DIR B:`, `DIR A:` again, `ECHO KEYBOARD OK` |
| Drives independent | A: 42 files / 3072 bytes free; B: 8 files / 9216 bytes free, GEM directories; A reads again |
| Focus-loss release | Hold left Shift, observe BIOS flag at 0x417, invoke existing app-deactivation connection, advance time, verify both Shift bits clear |
| Geometry/pixels | Padded 2048-pixel pitch, nonzero source origin, RGB checks, margins, square cabinet and 4:3 video in landscape/portrait/HiDPI-sized buffers |
| App resizing | Captures at 950x1030, 1500x850, 650x1050, including test-pattern mode |
| Exit | `quit` exits 0, token removed, no child backend exists |
| Missing inputs | Preparation reports exact missing ROM/media path and corrective instruction; exercised with absent/mock fixtures |
| Originals | Source disk hashes unchanged before/after tests |

Reports include exact executable SHA256, machine replies, config snapshots, guest text, paths and logs: `local/verification/report.json` and `local/verification-pattern/report.json`. They stay local because they include user paths/inventory. `local/milestone-86Box.exe` preserves the first passing pre-shader executable. Selected screenshots are in `docs/evidence/`.

The final binary also passed the complete suite with the **native Windows Qt platform**, first with CRT disabled (`local/verification-windows`) and then with the **IBMulator GPU shader active on the RX 7900 XTX** (`local/verification-shader`). Both runs used `AMSTRAD_HEADLESS=1`, an unshown main window, explicit scancode input and no desktop input/capture. Native Windows captures exercise the host's 1.75 device-pixel ratio as well as window resizing. GPU activation is asserted from the durable log, so these results cannot silently pass on the software fallback.

The first integrated shader attempt crashed in system `opengl32.dll` (C0000005) during worker-thread native context creation and displayed Windows' crash dialog. Creating that native context on the GUI thread before moving it to the worker fixed the reproduced failure; the full GPU suite then passed, including clean shutdown. Test processes now suppress fault UI and write optional native stack diagnostics, preventing another background-test dialog. The regular launcher enables the verified shader by default; `-NoCRT` retains the software fallback. Its shader log is `local/amstrad/crt.log`.

The user's readability follow-up is implemented: default sampling is now interpolating Catmull-Rom with zero RGB convergence, preserving thin 640x200 CGA glyph strokes while retaining CRT curvature and the existing margins. The original B-spline/0.5 convergence softened even texel-centered strokes and added colored fringes. The focused GPU regression increased alternating one-pixel monochrome contrast from 0.3046 to 1.0000 with zero measured RGB fringe. Actual DOS before/after captures use the same source and output size: [before](evidence/text-before.png), [after](evidence/text-after.png). Original soft settings remain optional; see the shader guide.

**F11** and **Alt+Enter** now toggle cabinet fullscreen in either direction; Ctrl+Alt+PageUp remains available. On a real focused window, Qt first delivers key presses to the application filter with the `QWidgetWindow` as receiver, where the guest keyboard path swallowed them; the shortcut check now matches that receiver too (the earlier hidden-window test sent events straight to a widget and missed this). Verified on a 175%-scaled desktop with physical key input, both from a maximized window and back. F11 is reserved from the Windows native guest keyboard path, and auto-repeat cannot repeatedly toggle the window. The latest full hidden Windows acceptance run also passed Qt F11 event dispatch, fullscreen state/menu hiding, repeat suppression, return to the previous geometry, native F11 reservation, both drives, focus loss and clean exit. Hidden tests never capture the host mouse. Fullscreen state/rendering was verified using an unshown window; the user's physical desktop hotkey interaction was left undisturbed. [Application capture while in fullscreen state](evidence/fullscreen.png).

Evidence: [POST](evidence/post.png), [DOS with shader and margins](evidence/dos-shader.png), [drive B](evidence/dir-b.png), [landscape resize](evidence/resize-wide.png), [known pattern](evidence/pattern.png).

The glass follow-up now preserves the prepared artwork beneath live video,
including black pixels, and compresses the upper-left reflection for readability.
The original artwork is unchanged. Scene checks passed for reflection reduction,
unchanged cabinet pixels, additive color channels, repeated frames without light
buildup, clipped clearing back to unlit glass, and four resize layouts. Full
background acceptance passed again with the IBMulator shader active and with CRT
disabled: POST/DOS, both drives, keyboard/focus release, fullscreen, clean exit,
token cleanup and unchanged original media. Verification now uses the current
`pc1512-front.png` instead of the retired v2 path. Captures: [live DOS behind
glass](evidence/glass-dos.png), [prepared unlit surface](evidence/glass-off.png).

## Reproduce

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-scene.ps1
rtk proxy python scripts/verify-milestone.py --pattern
rtk proxy python scripts/verify-milestone.py
rtk proxy python scripts/verify-milestone.py --windows
rtk proxy python scripts/verify-milestone.py --shader
```

The desktop network sandbox blocks localhost with WinError 10013; verification ran outside that network sandbox. It uses an ephemeral loopback port and generated authentication token, closes at exit and never activates the desktop. Ordinary local PowerShell does not need a Codex sandbox exception.

`Launch-Amstrad.cmd` starts the desktop build without automation flags. Media selects disks; Ctrl+End releases capture. `scripts/export-patch.py` updates the reviewable patch without staging the upstream checkout.

## Limits

Physical keyboard/mouse with the new desktop build was not retested after the request for uninterrupted PC use. Guest keyboard handling and focus release are tested; the preserved Windows native input path has source review. Exit was tested through automation's power-off path, not a final desktop click. GEM interaction, planar-mode compatibility, speaker listening, write tests, multimonitor/DPI transitions and long-running performance remain unverified. The installed toolchain lacks QtSvg, so optional toolbar SVG icons are unavailable in this local minimum-dependency build; labeled menus remain functional. Mechanical sound/animations, animated media controls and savestates are deferred. Upstream notes simplified wait states and mouse-driver 7.04 limitations; no hardware-exact claim.
