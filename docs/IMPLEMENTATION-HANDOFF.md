# Implementation handoff

Updated 2026-11-14. This is the current entry point and overrides obsolete pending-approval text in the original research/plan.

## User decisions

- The user explicitly approved `assets/front/pc1512-front-v2.png` on 2026-11-13.
- Proceed with PC1512 internals replacing IBMulator's emulated machine, using the approved Amstrad image if practical.
- Mechanical sounds (fan, floppy mechanisms, etc.), cabinet animations and animated disk interactions are **later work**. Guest PC-speaker output is a separate emulation concern.
- The user wants to lower implementation costs and hand this stage to Sol. Do not spend another broad research/planning pass. Do not launch a large agent team by default; use narrowly scoped delegation only where it saves work.
- Do not ask for visual approval again. No new chat, model switch, or implementation run has been started by this handoff.

## Verified workspace state

Both source checkouts are clean as of this handoff:

| Checkout | Exact HEAD |
| --- | --- |
| `upstream/IBMulator` | `48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27` |
| `upstream/86Box` | `978030cd0dc626bab794e74c8ddaa512c1a9fcc9` |

No implementation patches, executable builds, baseline VM or boot verification have been completed. Earlier agent work stopped after cloning/inspection when the agents reported a usage limit. Do not mistake source availability or research checklists for tested functionality.

Available toolchain observed: `C:\msys64\mingw64\bin` has GCC 15.2, CMake and Qt5; Git, Ninja, Python and .NET are installed. Full dependency availability is untested. IBMulator documents a no-spaces Windows build path requirement; this project path has spaces. Use a verified short build path/mapping if necessary without moving the user's project or changing global PATH.

Follow `C:\Users\adelc\.codex\RTK.md`: prefix shell commands with `rtk`. `rg` was unavailable; use `git grep` in source checkouts or PowerShell/Python where appropriate. Network fetches needed escalation; Git worked with per-command `-c http.sslBackend=schannel`. Do not disable TLS verification. Sources are already fetched, so do not reclone them unnecessarily.

## Architecture: resolved facts and one bounded decision

86Box already implements the complete PC1512 machine. Keep its CPU, memory, timing, video, keyboard/mouse and floppy controller together. A BIOS swap in IBMulator cannot replace its 286/386 PS/1 hardware with a PC1512.

The initial plan preferred IBMulator presentation plus a modified 86Box child process. Actual local inspection revealed substantial full-shell coupling: machine/ROM setup in `Program`, system board/CPU access in GUI setup, keyboard and floppy device dependencies in input/interface code, and machine virtual time in `SoundFX`. See `docs/architecture-research.md` for exact renderer entry points and links. That investigation is not a completed extraction/build attempt.

**Remaining decision belongs to the implementer, not to another user planning session:** select the smallest maintainable presentation integration after a focused local source/build check:

1. Prefer a thin SDL/OpenGL presentation executable using IBMulator's renderer/pipeline, with a modified 86Box backend, if that renderer subset can be built without pulling the IBM machine into the runtime. Feed it neutral frames and put the approved cabinet around the live CRT region.
2. If the renderer subset still drags in broad IBM machine dependencies, use the documented fallback: a realistic cabinet scene in a 86Box Qt fork. This preserves the PC1512 core and gets the approved image/live screen/input working with fewer moving parts. Record and explain that this route is 86Box-based rather than claiming IBMulator's internals were literally replaced. IBMulator shader reuse can follow later if it delays the working baseline.

Do not spend days making fake IBM devices to satisfy GUI dependencies. Do not implement both production paths. Do not add IPC if the selected route stays inside 86Box. Do not use desktop screenshot capture or window reparenting as the emulator video source.

## First implementation milestone

Deliver a runnable local Windows build showing **real PC1512 POST/DOS output inside the approved Amstrad monitor**, accepting keyboard input, with two configured 360K 5.25-inch drives. Preserve upstream input and disk configuration paths before inventing new controls. A normal menu/shortcut for media selection is sufficient now; animated front-panel interactions are deferred.

Implement in this order:

1. Establish isolated baseline using installed `C:\Emulators\86Box\86Box.exe` version 6.0. Use `local/baseline` and working copies of the user's disks; ROMs stay external. Read the inventory for exact files and proposed settings. Boot DOS and read both drives. This validates fixtures independently of new code.
2. Build the selected pinned source baseline. The cloned 86Box source identifies itself as 7.0 development, whereas the installed executable is 6.0; record that distinction and any behavioral differences. Disable unrelated optional integrations as needed, without silently changing the PC1512 machine model.
3. Resolve the bounded presentation decision above. Prove a known framebuffer test pattern renders with correct channel order, pitch, aspect and resizing before connecting the guest. If using two processes, define the minimal shared contract first; if using one, keep direct ownership/thread boundaries explicit.
4. Connect the live framebuffer and input. Preserve the approved cabinet proportions. Define the screen aperture/coordinates explicitly; clip live video to the CRT opening. The current image includes baked screen reflection, so avoid accidentally displaying two glass/reflection layers. No image regeneration is required to place live output over the existing glass.
5. Supply reproducible build/launch scripts and perform the acceptance checks below. Update the README with the actual architecture and launch location. Keep source patches reviewable and retain upstream notices.

## Minimum acceptance evidence

- Actual POST and DOS prompt visible within the approved image; save an application screenshot as evidence, not as the video implementation.
- Keyboard can issue a simple DOS command; focus loss does not leave keys held.
- `DIR A:` and `DIR B:` succeed with the selected disposable media; the drives are independent. Preserve originals and test writes only on expendable copies.
- Resizing keeps the cabinet and CRT aperture aligned; guest aspect is deliberate, not an arbitrary stretch of 640x200 pixels.
- Close exits cleanly; if a child backend is used, no orphan process remains. Failure to load ROM/media produces an actionable error.
- Record exact executable/source revision, config, media copies and commands used. State clearly which checks remain unverified. No claim of hardware-exact fidelity: upstream documents wait-state and mouse-driver limitations.

If GUI automation is needed, read the currently installed computer-use skill and its current API rather than reusing stale handles or documentation from the earlier attempt. Build and filesystem tools can be used directly.

## Inputs and scope boundaries

- Approved cabinet: `assets/front/pc1512-front-v2.png` (1254 x 1254). Keep this unchanged as the master.
- Firmware: `C:\Emulators\86Box\roms\machines\pc1512\40043`, `40044`, `40078`.
- Media: `C:\Emulators\86Box\Disks\PC1512 A1 - MSDOS.img`, `PC1512 A2 - GEM1.img`, plus the other system disks listed in the inventory.
- Target baseline: PC1512, 8086 at 8 MHz, 512 KiB, internal video and mouse, dual 360K 5.25-inch floppy drives, no hard disk or expansion sound card.
- No original installation/media modification, ROM redistribution, broad new emulator framework, savestates, mechanical audio work, or disk animations in this milestone.
- This milestone is not the complete future product. Finish its runnable deliverable and verification before broadening scope.

## Read only what is needed

Start here, then `docs/local-86box-inventory.md` and the relevant source-seam sections of `docs/architecture-research.md`. `docs/PLAN.md` contains larger future-stage work orders. Visual-reference research need not be repeated: appearance is approved.
