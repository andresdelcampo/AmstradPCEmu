#!/usr/bin/env bash
# Linux counterpart of prepare-vm.ps1: creates local/<name> (configuration,
# media folder) for a new VM after checking the user's firmware. An existing
# VM keeps its configuration and media.
#
#   scripts/prepare-vm.sh [--name amstrad] [--roms DIR] [--machine pc1512|pc1640]
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
name=amstrad
roms="$root/roms"
machine=pc1512
while [ $# -gt 0 ]; do
    case "$1" in
        --name) name="$2"; shift 2 ;;
        --roms) roms="$2"; shift 2 ;;
        --machine) machine="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done
[[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid VM name: $name" >&2; exit 2; }
case "$machine" in
    pc1512) firmware=("40043:8192" "40044:8192" "40078:8192"); mem=512 ;;
    pc1640) firmware=("40043.v3:16384" "40044.v3:16384" "40100:32768"); mem=640 ;;
    *) echo "Unknown machine: $machine" >&2; exit 2 ;;
esac

label="${machine^^}"
for entry in "${firmware[@]}"; do
    rom="${entry%%:*}"; size="${entry##*:}"
    path="$roms/machines/$machine/$rom"
    if [ ! -f "$path" ]; then
        echo "Missing $label ROM $rom. Supply your firmware under $roms/machines/$machine." >&2
        exit 1
    fi
    if [ "$(stat -c %s "$path")" != "$size" ]; then
        echo "Invalid $label ROM size: $path. Expected $size bytes." >&2
        exit 1
    fi
done

vm="$root/local/$name"
mkdir -p "$vm/media"
if [ ! -f "$vm/86box.cfg" ]; then
    cat > "$vm/86box.cfg" <<EOF
[General]
vid_renderer = qt_software
vid_resize = 1
force_43 = 1
confirm_exit = 0
confirm_reset = 0
window_remember = 1
hide_tool_bar = 1

[Monitor #1]
window_coordinates = 100, 50, 900, 950

[Machine]
machine = $machine
cpu_family = 8086
cpu_speed = 8000000
cpu_multi = 1
mem_size = $mem
cpu_use_dynarec = 0
time_sync = disabled

[Video]
gfxcard = internal

[Input devices]
mouse_type = internal

[Sound]
sndcard = none

[Floppy and CD-ROM drives]
fdd_01_type = 525_2dd
fdd_02_type = 525_2dd
fdd_01_audio = panasonic_ju4755_40t
fdd_02_audio = panasonic_ju4755_40t
EOF
fi
if [ ! -f "$vm/global.cfg" ]; then
    printf '[Emulator]\nconfirm_exit = 0\nconfirm_reset = 0\nconfirm_save = 0\n' > "$vm/global.cfg"
fi
echo "VM ready: $vm (existing config/media preserved). ROMs remain external: $roms"
