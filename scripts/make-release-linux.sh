#!/usr/bin/env bash
# Linux counterpart of make-release.ps1: builds the runnable Linux release under
# local/release/: a folder with the launcher, the emulator, artwork, licence
# texts and notices, and a .tar.gz of it (which keeps the executable bits) to
# attach to the GitHub release next to the Windows zip.
#
#   scripts/make-release-linux.sh [--version V] [--dist DIR]
#
# Run scripts/build-linux.sh first (on the oldest distribution to support: a
# binary built on Ubuntu 22.04 runs on 22.04 and later), and commit and tag, so
# the source GitHub publishes matches. --dist takes a local/dist-linux built
# elsewhere, such as a WSL copy of the tree. No ROMs, disks or VM state are
# included.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(date +%Y.%m.%d)"
dist="$root/local/dist-linux"
while [ $# -gt 0 ]; do
    case "$1" in
        --version) version="$2"; shift 2 ;;
        --dist) dist="$2"; shift 2 ;;
        -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done
[ -x "$dist/86Box" ] || { echo "Build first: $dist/86Box is missing (scripts/build-linux.sh)." >&2; exit 1; }
[ -f "$dist/assets/sounds/fdd/fdd_audio_profiles.cfg" ] || echo "WARNING: $dist has no drive sounds; the release drives will be silent." >&2

name="AmstradPCEmu-$version-linux-x86_64"
release="$root/local/release"
# Assemble on the Linux filesystem: a Windows drive in WSL marks every file
# executable, and the tarball must carry real permissions.
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
out="$stage/$name"
mkdir -p "$out/local" "$out/scripts" "$out/docs"

# Binaries, mirroring the repo layout the launcher expects.
cp -r "$dist" "$out/local/dist-linux"
cp "$root/amstrad-pc1512.sh" "$out/"
cp "$root/scripts/prepare-vm.sh" "$out/scripts/"

# The cabinet artwork the emulator reads at run time: tracked files only,
# without source masters, archived art, previews, notes, layout JSON or icons
# (the same selection as make-release.ps1).
git -C "$root" ls-files assets/front | grep -vE '/(archive|masters|previews)/|\.(md|json|ico)$' |
while IFS= read -r file; do
    mkdir -p "$out/$(dirname "$file")"
    cp "$root/$file" "$out/$file"
done

# Empty ROM folders for the user's own firmware.
mkdir -p "$out/roms/machines/pc1512" "$out/roms/machines/pc1640" "$out/roms/hdd/st506"
cat > "$out/roms/README.txt" <<'EOF'
Put your own ROMs here; they are not included. They are the same files, with
the same names and folders, as in 86Box's ROM set (https://github.com/86Box/roms);
copying the whole roms folder of an 86Box installation also works.

  machines/pc1512/  40043, 40044, 40078                 (8 KB each)
  machines/pc1640/  40043.v3, 40044.v3 (16 KB each), 40100 (32 KB)
  hdd/st506/        wd1002a_wx1-62-000094-032.bin       (8 KB, HD20 hard disk controller)

Only the PC1512 ROMs are needed to start. The PC1640 and HD20 ROMs are only
needed to run those configurations.
EOF

# Licences and notices, and the README's screenshots and linked guides.
for f in LICENSE README.md UPSTREAM.md CHANGES.md THIRD-PARTY-NOTICES.md; do cp "$root/$f" "$out/"; done
cp -r "$root/docs/screenshots" "$out/docs/"
for f in CABINET-MENUS.md IBMULATOR-CRT.md PC1640.md POWER-BUTTON.md front-artwork.md \
         power-art-prompts.txt front-transparency-prompt.txt visual-reference-review.md; do
    cp "$root/docs/$f" "$out/docs/"
done
cp "$dist/COPYING-86Box" "$out/COPYING-86Box"
cp "$root/assets/shaders/COPYING-IBMulator" "$root/assets/shaders/NOTICE-IBMulator.md" "$out/"

# Only the launcher, the setup script and the emulator are executable.
chmod -R u=rwX,go=rX "$out"
find "$out" -type f -exec chmod a-x {} +
chmod 755 "$out/amstrad-pc1512.sh" "$out/scripts/prepare-vm.sh" "$out/local/dist-linux/86Box"

mkdir -p "$release"
tarball="$release/$name.tar.gz"
rm -rf "$release/$name" "$tarball"
tar -C "$stage" --owner=0 --group=0 -czf "$tarball" "$name"
cp -r "$out" "$release/"
echo "Release folder:  $release/$name"
echo "Release tarball: $tarball"
echo "Reminder: commit and tag first, so the source GitHub publishes matches. ROMs, disks and VM state are not included."
