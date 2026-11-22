#!/usr/bin/env bash
# Amstrad PC1512 launcher for Linux: the counterpart of "Amstrad PC1512.exe".
# Starts local/dist-linux/86Box on the local/amstrad VM with the cabinet and
# CRT settings. On the first launch it creates the VM (scripts/prepare-vm.sh).
#
#   ./amstrad-pc1512.sh                    start the emulator
#   ./amstrad-pc1512.sh -NoCRT             without the CRT shader
#   ./amstrad-pc1512.sh --install-desktop  add it to the desktop's app menu
#
# Launched from the app menu (or a file manager with "Run"), no terminal
# window appears. Errors are shown in a dialog when zenity or kdialog exists.
set -u

root="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
exe="$root/local/dist-linux/86Box"
vm="$root/local/amstrad"
roms="$root/roms"
cabinet="$root/assets/front/pc1512-front.png"

fail() {
    local text="$1"$'\n\n'"$2"
    if command -v zenity >/dev/null 2>&1; then
        zenity --error --no-markup --title="Amstrad PC1512" --text="$text" 2>/dev/null
    elif command -v kdialog >/dev/null 2>&1; then
        kdialog --title "Amstrad PC1512" --error "$text" 2>/dev/null
    fi
    printf '%s\n' "$text" >&2
    exit 1
}

crt=1
for arg in "$@"; do
    case "$arg" in
        -NoCRT|--no-crt) crt=0 ;;
        --install-desktop)
            apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
            mkdir -p "$apps"
            cat > "$apps/amstrad-pc1512.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Amstrad PC1512
Comment=Amstrad PC1512 and PC1640 emulator
Exec="$root/amstrad-pc1512.sh"
Icon=$root/assets/front/pc1512-front.png
Terminal=false
Categories=Game;Emulator;
EOF
            echo "Added $apps/amstrad-pc1512.desktop"
            exit 0 ;;
    esac
done

[ -x "$exe" ] || fail "The emulator is not built yet." "Run scripts/build-linux.sh first."
[ -f "$cabinet" ] || fail "The cabinet image is missing." "$cabinet"
if [ ! -f "$vm/86box.cfg" ]; then
    if ! out="$("$root/scripts/prepare-vm.sh" --name amstrad 2>&1)"; then
        fail "The first-launch VM setup failed. Check that the PC1512 ROMs (40043, 40044, 40078) are in roms/machines/pc1512 beside amstrad-pc1512.sh." "$out"
    fi
fi

# On a Wayland desktop, run Qt as a native Wayland client when its plugin is
# installed (package qtwayland5): 86Box then captures the mouse with Wayland's
# pointer lock. Through XWayland its X11 grab gets no mouse motion.
# QT_QPA_PLATFORM=xcb forces X11.
if [ -z "${QT_QPA_PLATFORM:-}" ] && [ "${XDG_SESSION_TYPE:-}" = wayland ] && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    for dir in /usr/lib/*/qt5/plugins/platforms /usr/lib/qt5/plugins/platforms /usr/lib64/qt5/plugins/platforms; do
        if [ -f "$dir/libqwayland-generic.so" ] || [ -f "$dir/libqwayland-egl.so" ]; then
            export QT_QPA_PLATFORM=wayland
            break
        fi
    done
fi

export AMSTRAD_CABINET="$cabinet"
export AMSTRAD_CRT="$crt"
export AMSTRAD_CRT_LOG="$vm/crt.log"
unset AMSTRAD_TEST_PATTERN
cd "$root/local/dist-linux" || exit 1
exec "$exe" -P "$vm" -R "$roms" -O "$vm/global.cfg" -L "$vm/86box.log"
