# Panasonic floppy sounds

Enabled 2026-11-14 for both drives in `local/amstrad/86box.cfg` and for newly prepared VMs:

```ini
fdd_01_audio = panasonic_ju4755_40t
fdd_02_audio = panasonic_ju4755_40t
```

This is 86Box's **Panasonic JU-475-5 5.25-inch 180K/360K/40 tracks** profile, matching the user's existing 86Box selection. The upstream floppy controller triggers its original motor start, loop, stop and seek samples. No emulator core changes or additional sound card are needed. Existing cabinet and CRT source changes were preserved.

`scripts/deploy.ps1` copies the installed FDD profile table, recordings and `readme.txt` attribution together into `local/dist/assets/sounds/fdd`. It checks the Panasonic profile exists and every referenced recording is present before deployment. `scripts/build.ps1` forwards the optional `-FloppySoundSource` override. All 564 deployed files were verified byte-for-byte against the installed source assets. Those assets credit the Panasonic recordings to Andresdelcampo, with edits by Agetian and Domppari.

The current VM was backed up to `local/amstrad/86box-before-floppy-audio.cfg` before enabling audio. Preparation preserves existing preferences; it does not force audio back on after someone disables it in Settings. Preparation also permits shared read-only hashing of disks already mounted by the installed 86Box.

Verification command:

```powershell
python scripts/verify-milestone.py --floppy-sounds
```

The disposable test VM uses working disk copies. Results and WAV captures are under `local/verification-floppy`. The test checks nonzero FDD output for separate `DIR A:` and `DIR B:` commands, silence between operations, and both profile selections after a clean shutdown. DOS boot, independent drive contents, keyboard/focus handling and fullscreen checks are also exercised. Audio capture tests the emulator's dedicated FDD stream before host playback; physical speaker volume and subjective listening are not measured.
