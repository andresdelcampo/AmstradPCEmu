# Local 86Box baseline

Inspected read-only on 2026-11-13. No emulator was launched; no installed configuration, disk, or ROM was changed or copied. This is availability evidence, not a successful boot report.

## Installation

- Executable: `C:\Emulators\86Box\86Box.exe`.
- Windows file/product version resources both report **6.0**; executable size is 73,324,648 bytes. A source commit/build identity has not been established.
- Installation contains `roms`, `Disks`, sound assets, and GLSL shader directories.
- No machine `.cfg`, `.ini`, or `.json` files were found under this installation; the only `.cfg` files found were floppy/hard-disk sound profiles. Configurations elsewhere, including manager/AppData storage, were not inspected.
- Workspace was empty at the start of this task. Follow the user-provided `C:\Users\adelc\.codex\RTK.md`: prefix shell commands with `rtk`. `rg` was unavailable in this shell, so PowerShell enumeration was used.

## PC1512 ROMs

Directory: `C:\Emulators\86Box\roms\machines\pc1512`.

| Filename | Bytes | SHA-256 |
| --- | ---: | --- |
| `40043` | 8,192 | `f6ab06bb1159877b8fc8e10d680b58ba519d4b50064cc49f8755fdd5931dccc9` |
| `40044` | 8,192 | `b8b8b9d9ca82959f341dc9bb6e3c73f24576f60b8bd207f8b18c47af47973ea3` |
| `40078` | 8,192 | `2e5988193cb6e299c155ef672627f14e2d76c31f4a073376c45f45124c1d3cbc` |

Hashes were calculated with Windows `certutil -hashfile ... SHA256`. These identify the local files; they were not compared against an independent known-good dump database.

Upstream `machine_pc1512_init` interleaves `40044` and `40043` into a 16 KiB BIOS at `0xFC000`, and requires `40078`. Internal video initialization loads `40078` as the PC1512 character font. Keep these as external user-supplied inputs; do not add them to the project distribution. [86Box Amstrad implementation](https://github.com/86Box/86Box/blob/master/src/machine/m_amstrad.c)

## Available system media

The following files exist directly in `C:\Emulators\86Box\Disks`; each is **368,640 bytes (360 KiB)**:

- `PC1512 A1 - MSDOS.img`
- `PC1512 A2 - GEM1.img`
- `PC1512 A3 - GEM2.img`
- `PC1512 A4 - DOSPLUS.img`
- `PC1512 A5 - HDUTILS.img`

Several PC1512-labelled game images also exist, including a Flight Simulator v2.12 image; these can later serve as compatibility fixtures. File labels and sizes were inspected, not contents, bootability, or authenticity. The separate `dos_boot_disk.img` is 1,474,560 bytes and should not be the first dual-360K-drive fixture.

## Proposed isolated baseline configuration

Use `[8086] Amstrad PC1512`, internal machine ID `pc1512`, 8086 at 8 MHz, initially 512 KiB RAM, fixed internal PC1512 video, internal mouse, and two 5.25-inch 360K drives. Leave hard disk, CD-ROM, and expansion sound hardware absent for the first baseline. Configure these in a new project-owned VM directory rather than altering an existing VM.

The current upstream machine table constrains PC1512 to the 8086 family and 8 MHz, allows 512 or 640 KiB, and marks video as fixed. These facts were read from current `master`; confirm against the source revision selected for development. [86Box machine table](https://github.com/86Box/86Box/blob/master/src/machine/machine_table.c)

86Box initializes the PC1512 with its XT floppy controller and custom Amstrad keyboard/mouse implementation. Its source explicitly records imperfect mouse-driver 7.04 compatibility and a simplified video wait-state model. Reusing 86Box is a strong starting point, not proof of exact hardware fidelity. [Amstrad implementation and known limitations](https://github.com/86Box/86Box/blob/master/src/machine/m_amstrad.c)

Use `-P`/`--vmpath` for the isolated VM and `-R`/`--rompath` to reference the existing ROM directory. Verify the installed binary's supported arguments when this stage starts. [VM selection](https://86box.readthedocs.io/en/v5.2/usage/manager.html), [ROM lookup](https://86box.readthedocs.io/en/v5.3/usage/roms.html)

## Boot-baseline acceptance checklist for a future agent

1. Record the actual executable/build identity and exact VM settings in a project-owned report; preserve the source installation.
2. Create working copies of the selected disk fixtures in an ignored project directory, record hashes, and initially mount them write-protected. Never experiment on the originals.
3. Boot A1 MSDOS in A:, with B: empty. Capture POST and DOS prompt, record timing and any warnings. Check keyboard input and PC speaker output.
4. Insert a working copy of GEM1 into B:, run `DIR B:`, and verify A: still reads independently. Confirm eject/reinsert and empty-drive errors. Use expendable media only for a later write test.
5. Run GEM using the supplied media's actual instructions, swapping GEM disks as needed. Record mouse driver version, pointer movement/buttons, screen modes, and any known failures.
6. Exercise standard CGA and Amstrad 640x200 16-colour output with a suitable fixture; capture raw video before applying CRT effects. Compare with unmodified 86Box at the same settings.
7. Capture deterministic evidence for power/reset, floppy motor/seek/activity, speaker sound, and shutdown. Distinguish guest speaker audio from decorative mechanical sound.
8. Record passes and failures honestly. Do not label baseline or integration complete based on a static screenshot, file existence, or filenames alone.

This baseline is subsequent to the visual proof stage. No items above were executed in the present inventory task.
