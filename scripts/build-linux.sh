#!/usr/bin/env bash
# Linux build: configures and builds upstream/86Box (with the patch applied)
# into local/build-linux, then deploys the emulator, shaders and sounds into
# local/dist-linux, where amstrad-pc1512.sh runs it from.
#
#   scripts/build-linux.sh [--sounds DIR] [--jobs N] [--configure-only] [--skip-deploy]
#
# --sounds DIR  Drive sounds: either an already deployed assets/sounds folder
#               (local/dist/assets/sounds from a Windows build or release), or
#               an 86Box installation's assets/sounds folder (fdd/ and hdd/).
#               Default: local/dist/assets/sounds when present.
#
# Packages (Debian/Ubuntu): build-essential cmake ninja-build pkg-config
#   qtbase5-dev qtbase5-private-dev qttools5-dev libqt5opengl5-dev
#   libsdl2-dev libopenal-dev libfreetype-dev libsndfile1-dev libslirp-dev
#   libpng-dev zlib1g-dev libzstd-dev libevdev-dev libxkbcommon-x11-dev
#   libxi-dev libx11-dev libwayland-dev extra-cmake-modules libserialport-dev
#   libvdeplug-dev
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build="$root/local/build-linux"
dist="$root/local/dist-linux"
sounds=""
jobs="$(nproc 2>/dev/null || echo 4)"
configure_only=0
skip_deploy=0
while [ $# -gt 0 ]; do
    case "$1" in
        --sounds) sounds="$2"; shift 2 ;;
        --jobs) jobs="$2"; shift 2 ;;
        --configure-only) configure_only=1; shift ;;
        --skip-deploy) skip_deploy=1; shift ;;
        -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

src="$root/upstream/86Box"
if [ ! -f "$src/CMakeLists.txt" ]; then
    echo "Missing $src. Fetch the pinned upstream commits (UPSTREAM.md) and apply patches/86box-pc1512.patch." >&2
    exit 1
fi
if [ ! -f "$src/src/qt/qt_amstradscene.hpp" ]; then
    echo "upstream/86Box has no Amstrad patch. Apply it: git -C upstream/86Box apply ../../patches/86box-pc1512.patch" >&2
    exit 1
fi

options=(
    -S "$src" -B "$build" -G Ninja
    -DCMAKE_BUILD_TYPE=Release -DSTATIC_BUILD=OFF -DUSE_QT6=OFF -DSDL2=ON -DOPENAL=ON
    -DRTMIDI=OFF -DFLUIDSYNTH=OFF -DMUNT=OFF -DSOUNDCANVAS=OFF
    -DDISASM=OFF -DDISCORD=OFF -DDYNAREC=OFF -DBUILD_TRANSLATIONS=OFF
    -DAUTOMATION=ON
)
# The optional Rage 128 GPU backend (not used by the PC1512) needs Vulkan
# headers with VK_KHR_portability_enumeration (1.3.216+). Older ones, such as
# Ubuntu 22.04's, fail to compile it, so leave it out there.
vk=/usr/include/vulkan/vulkan_core.h
if [ ! -f "$vk" ] || ! grep -q VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME "$vk"; then
    options+=(-DR128_VULKAN_INCLUDE_DIR=R128_VULKAN_INCLUDE_DIR-NOTFOUND)
fi
cmake "${options[@]}"
[ "$configure_only" = 1 ] && exit 0
cmake --build "$build" --parallel "$jobs"
[ "$skip_deploy" = 1 ] && exit 0

# --- Deploy -----------------------------------------------------------------
mkdir -p "$dist/shaders"
cp -f "$build/src/86Box" "$dist/86Box"
cp -f "$src/COPYING" "$dist/COPYING-86Box"
for name in ibmulator-crt.frag NOTICE-IBMulator.md COPYING-IBMulator; do
    cp -f "$root/assets/shaders/$name" "$dist/shaders/"
done

# Start from an empty sounds folder so drives dropped from the set do not linger.
target="$dist/assets/sounds"
rm -rf "$target"
mkdir -p "$target/fdd" "$target/hdd"
[ -z "$sounds" ] && [ -d "$root/local/dist/assets/sounds/fdd" ] && sounds="$root/local/dist/assets/sounds"
if [ -n "$sounds" ] && [ -f "$sounds/fdd/fdd_audio_profiles.cfg" ]; then
    # A deployed set is already trimmed to the Panasonic floppy and Miniscribe
    # hard disk; a full 86Box set is copied whole (larger, same behaviour).
    cp -rf "$sounds/fdd/." "$target/fdd/"
    [ -d "$sounds/hdd" ] && cp -rf "$sounds/hdd/." "$target/hdd/"
    echo "Drive sounds from $sounds"
else
    echo "WARNING: no drive sounds (pass --sounds DIR). The emulator runs, but the drives are silent." >&2
fi
# Project-owned sounds: disk insert/eject, and the power button click (played
# through the same mixer on Linux; Windows plays it from assets/front/power).
mkdir -p "$target/fdd/amstrad"
cp -f "$root/assets/sounds/fdd/amstrad/"*.wav "$target/fdd/amstrad/"
cp -f "$root/assets/front/power/button-click.wav" "$target/fdd/amstrad/power_click.wav"

echo "Deployed to $dist. Start it with ./amstrad-pc1512.sh"
