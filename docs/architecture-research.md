# Architecture research — PC1512 experience

Research date: 2026-11-13. This is a proposed design, not a working integration. No emulator was built or boot-tested during this research.

## Recommendation

Preserve 86Box's PC1512 machine implementation. First test whether IBMulator's presentation can be separated behind a small backend interface. Use a modified 86Box child process for the first integration spike: frames, input, commands, device events, and eventually audio cross an explicit boundary. Keep the existing PS/1 scene and its mechanical sounds during that spike. Replace the scene with the accepted Amstrad artwork only after the backend behaves correctly.

This is a conditional choice, not a claim that 86Box is an embeddable library. If detaching the IBMulator shell proves too invasive, retain 86Box's Qt application and implement the realistic scene there, adapting selected rendering/audio code. Do not port the PC1512 hardware into IBMulator or write an 8086 emulator from scratch for the first release.

The immediate visual prototype should be independent of both engines. Its output is a reviewable static image and layout measurements, not a commitment to a GUI framework.

## What the source establishes

IBMulator targets PS/1 2011/2121 machines with 286/386 CPUs, VGA, an AT-style keyboard controller, and PS/1-specific devices. It offers a realistic scene, OpenGL/slang rendering, and mechanical drive/system sounds. These are useful presentation components, but changing a BIOS cannot turn that hardware into a PC1512. Its README declares GPL-3.0-or-later. [IBMulator README](https://github.com/barotto/IBMulator/blob/master/README.md)

86Box's `src/machine/m_amstrad.c` implements PC1512 video, custom keyboard/mouse interfaces, and machine initialization. The video extends CGA with planar 640×200×16. `machine_pc1512_init` loads BIOS halves `40044` and `40043`, and requires `40078`. The source explicitly documents simplified video wait states and a mouse-driver 7.04 problem. Reusing this implementation is a strong starting point, not proof of perfect hardware fidelity. [Amstrad implementation](https://github.com/86Box/86Box/blob/master/src/machine/m_amstrad.c)

86Box declares GPL-2.0-or-later and provides the `--vmpath` / `-P` option for isolated VM configurations. That is suitable for a baseline VM, but does not itself provide a framebuffer or device-event API. [86Box README](https://github.com/86Box/86Box/blob/master/README.md)

Source references observed during research:

- IBMulator tree: `48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27`. The detailed IBMulator files below were fetched at this exact revision.
- 86Box current branch head reported by GitHub: `978030cd0dc626bab794e74c8ddaa512c1a9fcc9`. Browser-rendered source may be cached at earlier revisions; agents must fetch this pinned revision and reconfirm signatures before editing.
- GitHub connector calls were unavailable; research used primary GitHub/raw source and direct public-source reads. No local 86Box executable version is inferred from upstream master.

## Exact integration seams

### IBMulator shell

| Source | Observed behavior | Proposed adaptation |
|---|---|---|
| [`src/gui/screen_renderer.h`](https://github.com/barotto/IBMulator/blob/48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27/src/gui/screen_renderer.h) | `store_vga_framebuffer(FrameBuffer&, const VideoModeInfo&)`; distinct VGA and CRT passes; includes the VGA device header | Introduce a neutral frame description, then translate to existing renderer types at one boundary. |
| [`src/gui/windows/interface_screen.cpp`](https://github.com/barotto/IBMulator/blob/48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27/src/gui/windows/interface_screen.cpp) | `sync_with_device()` reads `g_machine`, waits on display synchronization, locks/copies frames | Replace its producer/synchronization dependency with backend snapshots; preserve render-thread OpenGL ownership. |
| [`src/gui/windows/interface.cpp`](https://github.com/barotto/IBMulator/blob/48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27/src/gui/windows/interface.cpp) | Constructor accepts `Machine*` and `Mixer*`; configures `FloppyCtrl` directly; registers motor/activity callbacks | Route power, media, and status through backend commands/events; do not emulate an entire fake IBM `Machine`. |
| [`src/gui/windows/realistic_interface.cpp`](https://github.com/barotto/IBMulator/blob/48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27/src/gui/windows/realistic_interface.cpp) | `RealisticScreen::render()` drives the screen/CRT passes; `RealisticInterface` loads RML and monitor geometry | Keep this PS/1 scene for the integration milestone; add an Amstrad skin later. |
| [`src/audio/soundfx.h`](https://github.com/barotto/IBMulator/blob/48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27/src/audio/soundfx.h) | Timed effect playback reads `g_machine.get_virt_time_us_mt()` | Inject backend emulation time; preserve event order across pause, reset, and power transitions. |

This is significant coupling. The table identifies concrete places to begin a spike, not a complete dependency audit. Also inspect `program.cpp`, `gui.cpp`, `mixer.cpp`, and configuration/state dialogs before making a final fork decision.

### 86Box producer

| Source | Observed behavior | Proposed adaptation |
|---|---|---|
| [`src/qt/qt_rendererstack.cpp`](https://github.com/86Box/86Box/blob/master/src/qt/qt_rendererstack.cpp) | `RendererStack::blit(x,y,w,h)` runs on the blitter thread, copies the monitor target buffer, signals completion, then queues a renderer update | Add a frame sink at the copy boundary. Always release the upstream blitter even if the shell is slow or disconnected. |
| [`src/include/86box/video.h`](https://github.com/86Box/86Box/blob/master/src/include/86box/video.h) | Monitor buffers and geometry are explicit | Carry width, height, pitch, pixel format, visible rectangle, aspect, sequence, and time. Do not assume a fixed 640×200 tightly packed image. |
| [`src/qt/qt_main.cpp`](https://github.com/86Box/86Box/blob/master/src/qt/qt_main.cpp) | Host key translation ultimately calls `keyboard_input` | Queue normalized key transitions into the emulator context; clear held input on focus loss/disconnect. |
| [`src/include/86box/fdd.h`](https://github.com/86Box/86Box/blob/master/src/include/86box/fdd.h) | Motor/seek functions and drive-type accessors exist | Instrument actual motor, step, and media transitions. UI click sounds alone are insufficient. |
| [`src/include/86box/sound.h`](https://github.com/86Box/86Box/blob/master/src/include/86box/sound.h) | `sound_backend_t` exposes source creation and buffer callbacks | Start with backend guest audio played normally; later add a PCM sink when a unified volume/filter pipeline is needed. |

Retaining the upstream machine/device model means preserving its CPU, bus, timers, DMA, FDC, and video behavior together. Extracting only `m_amstrad.c` would drag in those dependencies and create a new hardware-porting project.

## Shaders and audio

The screen effect can be reused independently of the CPU. The existing PS/1 preset is not just a generic CRT filter: it includes reflection, CRT, and monitor passes, artwork textures, LED coordinates, monitor dimensions, and IBMulator-specific `ibmu_*` settings. Keep it intact for the PS/1 intermediate milestone; create a new Amstrad preset and geometry later. [PS/1 preset](https://github.com/barotto/IBMulator/blob/48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27/share/ibmulator/shaders/ps1/monitor.slangp)

86Box's inspected OpenGL renderer uses GLSL shader/preset structures and uniforms. IBMulator's slang preset should therefore not be treated as a drop-in 86Box shader. Keeping IBMulator's shader pipeline is one reason to try its shell first. The alternative is a deliberate translation with comparison captures of geometry, color, gamma, and sampling. [86Box renderer](https://github.com/86Box/86Box/blob/master/src/qt/qt_openglrenderer.cpp)

IBMulator's tree contains both 3.5-inch and 5.25-inch insert/eject, motor and seek WAVs under `share/ibmulator/sounds/floppy`, plus system-power sounds. They are useful placeholders; their existence does not establish that they were recorded from PC1512 drives. Keep mechanical effects distinct from guest PC-speaker audio and prevent duplicate effects from both applications. [Sound assets](https://github.com/barotto/IBMulator/tree/48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27/share/ibmulator/sounds)

Project declarations suggest a GPLv3-or-later combined source release is a plausible route because 86Box permits later GPL versions. Before redistribution, retain notices and audit the actual selected code, shader, texture, font, and sound files and dependencies; the top-level declaration is not a substitute for individual asset provenance. Keep user ROMs and commercial system disks outside source/packages. No asset-license audit was completed here.

## Options and decision gate

| Route | Benefit | Main cost | Decision |
|---|---|---|---|
| IBMulator presentation + modified 86Box child process | Preserves PS/1 appearance first; separates engine/build lifetimes | Shell coupling, IPC and timing | Preferred bounded experiment |
| 86Box fork + realistic scene in Qt/OpenGL | Lowest risk to machine behavior; existing input/media support | More work to reproduce IBMulator's presentation | Fallback if shell extraction expands |
| Single-process IBMulator/86Box hybrid | Avoids IPC copies | Global state, build/toolkit coupling, shutdown/thread ownership | Reconsider only after interface proven |
| New frontend + 86Box backend | Small purpose-built scene | Rebuilds useful shell features | Reasonable later simplification, not first choice |
| PC1512 port into IBMulator/new emulation core | Maximum control | CPU, board, CGA, keyboard and timing work | Exclude from initial scope |

Do not use desktop screenshot capture or window reparenting as the production video interface. They can demonstrate a concept but do not provide dependable timing, focus, media control, or drive events.

## Agent-ready technical spikes

1. **Reproducible baseline.** Pin sources; record local executable version and ROM hashes; use a project-owned VM directory. Configure PC1512, 8086 at its documented speed, 512 KiB, internal video and two 360 KiB 5.25-inch drives. Boot user-owned media; capture POST, DOS, text/CGA and the Amstrad planar mode. Output build/config instructions and baseline captures. Pass: both drives independently usable and reboot repeatable. Keep original installation/media untouched.
2. **Fake backend in IBMulator shell.** Build the unmodified shell first, then feed test patterns through a neutral frame source, simulated power state and timed A/B motor/seek events. Disable unsupported save/debug features visibly. Pass: PS/1 scene and effects remain, no IBM guest CPU runs, resizing and close work. Stop after two focused implementation attempts if changes sprawl through unrelated device classes; record blockers and select the 86Box scene fallback.
3. **86Box bridge.** Add a minimal frame sink and command queue to a pinned 86Box fork. Start with versioned named-pipe commands and shared-memory frame slots. Use one instance per backend process. Pass: live PC1512 POST reaches the shell with correct pitch/colors/aspect; the producer never blocks indefinitely; clean shutdown leaves no child process.
4. **Input and media.** Connect reset/pause, keyboard transitions, mouse movement/buttons, A/B insert/eject and write-protection. Acknowledgements update UI state only when commands actually succeed. Pass: DOS input, GEM mouse if suitable user media exists, A-to-B copy and deliberate write-protection failure; failed mounts do not show a disk as inserted. Use disposable disk copies for write tests.
5. **Timing and sound.** Add emulation timestamps to motor/seek/power events and bring PCM through the mixer only if needed. Pass: no duplicated noise, pause/resume does not leave looping motors, resets clear stale events, guest speaker tone matches baseline, slow rendering does not alter guest time. Disable artificial floppy acceleration for fidelity comparisons.
6. **Amstrad skin.** Consume the approved static artwork as separate case, monitor, display mask, two drive controls and LEDs. Replace geometry rather than stretching the PS/1 monitor. Pass: every hit region matches the art at normal and high DPI; independent A/B states agree with backend; screenshot comparison retains approved proportions.

Each spike must return changed files, exact commands, logs/captures, pass/fail against its acceptance criteria, and unresolved limitations. One integrator owns the backend protocol and shared headers; agents own separate renderer, backend, art, or validation areas. Freeze protocol version 1 before implementing both ends.

## Proposed protocol boundary (design, not existing API)

Commands: start/stop, power/reset, pause/resume, key down/up, relative mouse/buttons, insert/eject by drive, write-protect. Replies: command ID, success/error and resulting state. Events: frame-ready, power state, drive motor/seek/media changes, timestamp and sequence. Optional PCM: sample rate, channels, format, frame count and emulation time.

Use bounded queues, explicit maximum frame sizes, latest-complete-frame consumption, producer-owned buffer lifetimes, and reconnect/crash handling. Never call device internals from the frontend thread. Backend owns guest clocks and disk state; frontend owns presentation. Mechanical samples follow backend events, not frame rate. Treat savestates as a later feature requiring a separate complete implementation; IBMulator's PS/1 state files do not transfer to 86Box.

## Windows build consideration

IBMulator's Windows build instructions use MSYS2/MinGW, RmlUi, SDL2 and an autotools build, and explicitly advise paths without spaces. This workspace contains spaces. A build agent must use a documented short build path or verified path mapping while preserving the project checkout; it must not move the user's project or globally alter PATH. 86Box has its own build toolchain. A process bridge permits independent builds. [IBMulator Windows build](https://github.com/barotto/IBMulator/blob/48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27/docs/BUILD_WINDOWS.md)
