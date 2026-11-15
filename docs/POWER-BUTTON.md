# Rear monitor power button

The cabinet opens switched off with the rear-button close-up already visible to
the right of the monitor, outside the cabinet. Two dashed leader lines run from
its rounded upper-left corner and bottom frame edge to two separate points
low on the monitor's right edge, marking the approximate rear casing section
being enlarged. Fine dashed leaders match the close-up's subtle outline and
end without dots. A narrow feather softens only the outer plastic edge, while
the switch and recessed ring stay sharp. The cable-bay
comparison retains its raised frame. The original POWER pill and icon below
remain its only caption. Press the round beige button to switch on or
off. The app stays open when off, with dark glass and all front LEDs off.
The close-up uses pronounced rounded corners while retaining its original
width, button scale and POWER pill. A small strip (about 5%) of lower plastic
is cropped to balance the space around the button. The upper dashed leader is a
single straight line ending on the rounded corner; the lower leader continues
to meet the bottom edge. Their monitor-side endpoints are 64 master pixels
apart, following the casing edge rather than converging on one point.
The hover/click reveal target is the inset's current on-screen footprint,
including its POWER caption, even while hidden. The monitor edge and badge
do not reveal it. While open, the popup and the tapered passage between its
leaders keep it visible; the former broad monitor hotspot and invisible
bounding rectangle no longer do.
Powering on boots the PC again rather than resuming the previous CPU/RAM state.
Release mouse capture with Ctrl+End before interacting with the cabinet.

Right-click the inset to compare **Button close-up** and **Rear cable bay**.
Hovering over the inset also reveals muted ellipsis dots at the bottom-right,
beside the POWER caption, with a faint backing only on direct hover.
Its **Change power view** tooltip identifies the control; clicking it
opens the same two-view menu. The button disappears when the pointer leaves.
The rear-bay photograph grows up to twice its original scale where the window
has room; in narrower windows it uses the available strip beside the monitor.
Its frame padding, border stroke and POWER caption retain the close-up's scale.
Power transitions keep the previous frosted backing until the next capture, so
the rear-bay frame and caption never show the popup's blue fallback.
Both have the same on/off behavior; the view is saved as `power/view` in the
VM's `amstrad.ini`. The inset stays visible while off, including after leaving
it. While on, hover over the inset's on-screen position to the right of the monitor,
even while hidden, to fade it in. It closes after leaving it or operating the
button. Its position and hit regions use the cabinet's proportional layout at
every window size. The scene reserves space on the right for the inset and its
leader lines. Old saved windows request extra width once, within the available
screen, preserving the cabinet size where possible; subsequent manual window
sizes are remembered. Narrow windows scale the composition instead of covering
the monitor. The lower dashed leader meets the bottom edge of the inset frame.
The button stays latched from mouse release until the core acknowledges power-on;
it does not briefly return to the off image during the cold-boot transition.

There is no front reset button or Hard Reset menu/toolbar control. Ctrl+F12,
or Action → Send Ctrl+Alt+Del to the PC, sends the guest's reboot key sequence
without issuing Windows' Ctrl+Alt+Del. It is ignored while switched off.

## Evidence and artwork limits

The user remembered a round beige button and a recessed rear area. Verified
against [MCbx's photograph of a Schneider/Amstrad monochrome monitor](https://oldcomputer.info/pictures/gal/Museum/PC/Amstrad_PC1512/009.jpg)
and [Amstrad's service manual](https://ctrl-alt-rees.com/downloads/amstrad/Amstrad_PC1512_PC-MM_PC-CM_Service_Manual.pdf#page=29).
The PC-MM parts diagram, printed page 29, identifies the pushbutton as part 63,
171469, near the cable exits. The pair of side knobs are part 64, 171362;
they must not be mistaken for the power button. The PC-CM drawing on page 28
likewise separates pushbutton 38 from the side knobs 39.

In the photograph, the button is low in the recessed cable bay: below/between
the black mains connection and the first grey connector. The bay is on the
left in a rear view, hence toward the user's right when facing the screen.

The two app views are AI reconstructions, not original photographs or measured
models. The close-up omits cables and lettering. The wider version follows the
reference's connector/button arrangement, with the German EIN/AUS sticker
removed at the user's suggestion. Cable curvature, material and depth remain
illustrative. Neither contains the earlier invented four-screw mounting plate.
The MM reference informs the shared inset for both front monitor selections;
it is not a separately verified reconstruction of every PC-CM rear detail.

Final project assets, generated using the built-in image tool:

- `assets/front/power/rear-button-atlas.png`: two square frames side by side,
  off then on.
- `assets/front/power/rear-bay-atlas.png`: two landscape frames stacked,
  off then on.
- [Generation/edit prompts](power-art-prompts.txt).

The original MCbx photograph is by MCbx, whose gallery identifies a CC BY-NC-SA
3.0 licence. It and the downloaded service manual are local research references
under ignored `local/power-reference`, not redistributed photographs in the app.
The generated artwork's reference history is retained here; no claim that AI
generation removes source-related obligations is made.

The switch click is a short attenuated transient from the project's existing
`assets/sounds/fdd/amstrad/disk_insert.wav`, saved as `button-click.wav` beside
the images. It is a stand-in mechanical click, not a recording of an original
PC1512 power switch. Windows plays it on both transitions, respecting Mute.

## Implementation and verification

`qt_amstradpower.hpp` owns the GUI inset, comparison menu and hit targets.
`SoftwareRenderer` paints the unpowered cabinet independently of guest frames.
`MainWindow` owns power state. A dedicated `RUN_PAUSE_POWER` reason parks the
CPU/audio while off, so a focus/dialog/Pause change cannot resume it. On power-on,
the core's existing safe-point hard-cycle path recreates the machine before that
reason is cleared. Device objects remain allocated while off until this cycle
or normal app exit; this is a presentation-level power switch, not electrical
power-supply simulation. Media originals remain untouched.

Diagnostic boot runs can set `AMSTRAD_POWER_ON=1`; normal launches start off.
`verify-milestone.py` opts into automatic power-on. `verify-power.py` uses a
disposable VM and the authenticated automation socket to exercise actual Qt
hover/click events, both views, POST/DOS, CPU inactivity while off, cold RAM on
power-on, Ctrl+F12 reboot, released modifiers, and clean exit while off. UI test
commands require an explicitly headless automation run; ordinary launches open
no test socket. Evidence is saved under `local/verification-power/`.
`scripts/test-power-peek.ps1` also renders both actual inset views with a delayed
acknowledgement, comparing the pressed/released/acknowledged images to catch
button bounce or flicker and checking off-state visibility and on-state hiding.

Verified 2026-11-14: the build, both-view power tests and the native Windows
CRT/fullscreen milestone regression passed. The latter also exercised keyboard
input, focus-loss key release, independent A:/B: reads and unchanged original
media. Its reused disposable VM is explicitly set to start windowed before
testing F11; a remembered fullscreen flag had invalidated that test's initial
assumption on the first runs. Native regression evidence is under
`local/verification-shader/`. The short switch-click recording was checked as
a deployed asset; perceived sound/feel remains for interactive review.

Verified 2026-11-15: the compositor and both-view inset tests cover narrow,
default and wide layouts, including the lower-right anchor, containment,
off-state visibility and delayed-acknowledgement button latching.
The hidden native Windows power-cycle and CRT milestone checks also passed,
including mouse hit regions, fullscreen restoration and unchanged original disks.
A separate two-launch check confirmed that a saved 900px-wide window becomes
1048px once, then restores at 1048px on the next launch. Built and deployed to
`local/dist`.
