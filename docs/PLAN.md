# Staged delivery plan

> Update 2026-11-14: The user approved front v2 on 2026-11-13 and authorized PC1512 internals with that image if practical. Mechanical sounds and cabinet/disk animations come later. Read [IMPLEMENTATION-HANDOFF.md](IMPLEMENTATION-HANDOFF.md) first. It supersedes the pending-approval wording and the requirement to retain PS/1 sounds in this original plan. The work orders below remain useful technical background; do not repeat the research or request visual approval again.

## Objective and current stop point

Recreate the experience of a dual-5.25-inch-drive Amstrad PC1512 DD with the convincing physical presence that IBMulator provides for the IBM PS/1. Preserve the user-requested sequence: actual static front image first; PC1512 internals under the PS/1 presentation next; Amstrad controls, media interactions and sounds later.

The user explicitly made the static image the go/no-go decision. **Do not start emulator implementation until the user accepts the visual direction.** Research and the plan are complete enough to support that decision; no source fork, dependency installation, emulator launch or hardware implementation was done.

The initial artwork target is the later Amstrad red/grey-badged DD system with PC-CM colour monitor. This is an assumption for the first candidate, not a locked preference. Keep revision details consistent if the user requests the earlier brown-badged machine or PC-MM monitor.

## Architecture decision

Keep the complete 86Box PC1512 machine model. Attempt a bounded extraction of IBMulator's presentation behind a neutral backend interface, then connect a modified 86Box child process. Retain the PS/1 artwork, shader pipeline and placeholder mechanical sounds during integration. Do not port an 8086 or individual Amstrad devices into IBMulator.

This is a proposed adapter, not an existing interchangeable core API. IBMulator's GUI and effects currently depend on its own machine. If extraction spreads through unrelated emulated devices, use a realistic scene within a 86Box Qt fork instead. The original installed executable alone cannot supply the proposed frame/event interface.

See [architecture evidence and source seams](architecture-research.md) before making code changes. The renderer/backend split is the experiment; it is not yet a final framework commitment.

## Milestones

| Stage | Deliverable | Required evidence and exit gate |
| --- | --- | --- |
| 0. Static front | The actual proposed front image, independently viewable, with source references and explicit inaccuracies/limits | User judges recognisable hardware, proportions, materials, typography and full-size quality. Candidate v2 exists; approval pending. No motion, sounds or emulator required. |
| 1. Reproducible baseline | Pinned source revisions/build instructions and isolated PC1512 VM | Boot POST and DOS; independently read A: and B:; record input, video and speaker evidence. Use copies of local disks. Compare against installed 86Box. |
| 2. Presentation separation | IBMulator PS/1 scene running a deterministic fake backend | Show known framebuffer test pattern, correct aspect/pitch/colours, mock drive events, power/pause, resize and clean exit. No IBM guest CPU running. Architecture decision recorded. |
| 3. Real PC1512 behind PS/1 | Modified 86Box process feeding IBMulator shell | Live POST/DOS frames, usable keyboard, correct A/B media state, failure acknowledgement, guest audio and clean child-process shutdown. Preserve existing PS/1 appearance and effect sounds. |
| 4. Behaviour and fidelity | Repeatable compatibility evidence under that temporary shell | GEM mouse, text/CGA/Amstrad planar output, reset, pause, focus loss, write-protection, disk swaps, guest speaker and mechanical event timing. Compare with baseline; document 86Box limitations. |
| 5. Amstrad scene | Approved image converted into layered working skin | Screen aperture, drive A/B levers and media, power/activity indicators and correctly located controls. High-DPI hit regions; same approved cabinet proportions; state comes from backend acknowledgements. |
| 6. Finish and package | Reproducible Windows package and user setup | Clean-machine launch, user-supplied ROM/media lookup, no orphan processes, notices/asset provenance, documented limitations and regression captures. |

Stage 0 passes only through user review. Do not infer approval from silence or a successful image-generation call. If rejected, stay at Stage 0 and revise the specific offending geometry/material/detail. A measured 3D model rendered to static sprites or a licensed rectified photograph are alternatives if generated imagery cannot reach the required fidelity.

## Work orders for implementation agents

Each work order is narrow enough for a less capable implementation agent. Assign only its files and gate. The orchestrator owns shared interfaces and integration; agents must not independently redesign them.

### A. Baseline and build agent — Stage 1

Read the inventory and architecture documents. Reconfirm pinned sources, all repository instructions, build tools and local state. Create project-owned checkouts/build directories only after visual approval. IBMulator's documented Windows build dislikes spaces: use a verified short path/mapping without moving this project or globally changing PATH. Build unmodified upstream components before editing. Configure 8086 at 8 MHz, 512 KiB, internal PC1512 video/mouse, two 360 KiB 5.25-inch drives, no extra hardware. Boot disposable copies of A1 MSDOS and GEM media from the inventoried installation.

Deliver `docs/baseline-results.md`, exact build/launch commands, selected revisions/configuration, hashes and captures. Fail the gate if boot or independent A/B access is unproven. Do not modify original media or distribute it.

### B. Protocol owner — before Stages 2 and 3

The orchestrator defines version 1 in a small shared contract: frame dimensions/pitch/pixel format/visible region/aspect, sequence and emulation time; input transitions; power/reset/pause; insert/eject/write-protect; replies with command IDs and resulting state; drive motor/seek/media events. Add a version handshake and bounded payload sizes. Backend owns guest clocks and media state. Frontend owns rendering. Specify shutdown, slow consumer, stale events and disconnect behavior before either endpoint is implemented.

Deliver `docs/backend-contract.md` and shared declarations. Do not invent a generic emulator framework, remote networking service, or savestate format.

### C. Presentation agent — Stage 2

Own frontend files only. Start at the verified IBMulator framebuffer and interface seams in the research document. Feed a test pattern through a fake backend; replace machine-time access for effects. Retain PS/1 RML, shader pipeline and sounds. Explicitly disable unsupported PS/1 save/debug/config functions. Do not create fake PC1512 subclasses of unrelated IBM devices just to satisfy coupling.

Deliver a runnable fake-backend shell and captures. Verify resize, colour channels, frame pitch, aspect, pause and exit. After two focused attempts that reveal broad device coupling, return the blocking dependency list to the orchestrator; decide the 86Box-scene fallback rather than continuing an uncontrolled rewrite.

### D. Backend agent — Stage 3

Own 86Box adapter files only. Keep machine/device code intact where possible. Add a frame sink at the renderer copy boundary, queue commands into the emulation context, and emit actual device events. Use the protocol owner's contract. Release upstream blitter resources even when the frontend is slow; consume latest complete frames. Begin with normal 86Box guest audio output and ensure only one component supplies mechanical effects.

Deliver real POST/DOS to the shell, keyboard input, acknowledged A/B mounting, and reliable stop/disconnect. Use a modified backend build; do not use desktop screenshot capture or window embedding as the production interface.

### E. Validation agent — Stage 4

Own fixtures and results, not core architecture. Run the same disk/config/video scenarios against unmodified baseline and integrated backend. Verify GEM mouse if compatible media/driver, independent A/B access, disposable-disk copy/write protection, raw text/CGA/planar images, speaker output, reset, pause, focus loss and orderly exit. Exercise slow frontend and backend crash. Add focused automated checks for actual protocol/ownership failures; visual accuracy still needs captures and human review.

Deliver a reproducible pass/fail table with exact inputs and logs. Do not call parity or fidelity proven by a single DOS screenshot. Report inherited wait-state/mouse limitations separately from integration regressions.

### F. Art and interaction agent — Stage 5

Consume the user-approved image/revision. Preserve it as a versioned master. Prepare separate chassis, CRT aperture/reflection treatment, drive states and indicators with one coordinate manifest. Avoid baking guest text into the artwork. Map controls only where the real hardware provides them; the front POWER dot is an indicator, not a switch. Implement A/B interactions from acknowledged backend state and route actual activity to LEDs/sounds. Keep placeholder PS/1 recordings labelled until authentic replacements are available.

Deliver before/after static captures, DPI/hit-region checks, media interaction captures, and per-asset provenance. The present 1254-pixel generated candidate is not a layered production master; higher-resolution and layer preparation remain explicit work.

## Orchestration rules

1. Read existing state and report changed files before editing. Follow the user-supplied RTK instruction for shell commands.
2. Stages are sequential gates. Stage 1 baseline and Stage 2 fake-shell work may run in parallel only after Stage 0 approval; their integration waits for both.
3. Limit concurrent implementers to disjoint frontend/backend/validation ownership. One owner changes the protocol. Avoid simultaneous edits to shared build files.
4. Every agent returns: changes, exact commands, evidence, acceptance results, known limits and next dependency. Never report work as complete solely because code compiled.
5. Keep ROMs, system disks, mutable VM files, build products and private reference photos out of distributable source. Audit reused shader/sound/texture licences before packaging.
6. Ask the user at the explicit visual go/no-go gate. Routine approved implementation details belong to the orchestrator. Do not promise hardware-exact emulation merely because 86Box is reused.

## Current result

Three research agents completed architecture, local inventory and visual-reference work. The primary agent generated and inspected two static image versions; v2 repairs the obvious cutout boundary problem by presenting the machine on dark charcoal. No emulator tests were run. The next action is the user's judgement of the saved front image.
