"""Run the real PC1512 offscreen using 86Box's authenticated local test socket.

No desktop screenshots or injected host input. Firmware and disks stay external.
Run prepare-vm.ps1 first. Captures come from the application and its video core.
"""
import argparse
import hashlib
import json
import os
import re
from pathlib import Path
import socket
import subprocess
import time
import wave
from array import array

ROOT = Path(__file__).resolve().parents[1]
SCANS = dict(zip('abcdefghijklmnopqrstuvwxyz',
    [0x1e,0x30,0x2e,0x20,0x12,0x21,0x22,0x23,0x17,0x24,0x25,0x26,
     0x32,0x31,0x18,0x19,0x10,0x13,0x1f,0x14,0x16,0x2f,0x11,0x2d,0x15,0x2c]))
SCANS.update({' ':0x39, ':':0x27, '\n':0x1c})

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--installation', type=Path, default=Path('C:/Emulators/86Box'))
    parser.add_argument('--executable', type=Path, default=ROOT/'local/dist/86Box.exe')
    parser.add_argument('--pattern', action='store_true')
    parser.add_argument('--shader', action='store_true', help='Use WGL with an unshown application window')
    parser.add_argument('--windows', action='store_true', help='Test native Windows platform without the CRT filter')
    parser.add_argument('--floppy-sounds', action='store_true', help='Record and verify Panasonic audio independently for A: and B:')
    args = parser.parse_args()
    args.installation = args.installation.resolve()
    name = 'verify-shader-vm' if args.shader else ('verify-windows-vm' if args.windows else ('verify-pattern-vm' if args.pattern else 'verify-vm'))
    if args.floppy_sounds:
        name = 'verify-floppy-vm'
    subprocess.run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                    str(ROOT/'scripts/prepare-vm.ps1'), '-Name', name,
                    '-Installation', str(args.installation)], check=True)
    vm = ROOT / 'local' / name
    # A reused disposable VM can remember fullscreen from a previous run.
    # The F11 regression below deliberately starts in a normal window.
    config = vm / '86box.cfg'
    config.write_text(re.sub(r'(?m)^start_in_fullscreen\s*=.*$', 'start_in_fullscreen = 0', config.read_text()))
    out = ROOT / ('local/verification-shader' if args.shader else ('local/verification-windows' if args.windows else ('local/verification-pattern' if args.pattern else 'local/verification')))
    if args.floppy_sounds:
        out = ROOT / 'local/verification-floppy'
    out.mkdir(parents=True, exist_ok=True)
    exe = args.executable.resolve()
    env = os.environ.copy()
    env['QT_QPA_PLATFORM'] = 'windows' if args.shader or args.windows else 'offscreen'
    env['AMSTRAD_HEADLESS'] = '1'
    env['AMSTRAD_POWER_ON'] = '1'
    env['AMSTRAD_CRT'] = '1' if args.shader else '0'
    for override in ['AMSTRAD_CRT_SAMPLING', 'AMSTRAD_CRT_CONVERGENCE', 'AMSTRAD_CRT_SHADER']:
        env.pop(override, None)
    env['AMSTRAD_CRT_LOG'] = str(out/'crt.log')
    env['AMSTRAD_TEST_LOG'] = str(out/'native.log')
    for diagnostic in ['crt.log', 'native.log']:
        (out/diagnostic).unlink(missing_ok=True)
    env['QT_QPA_FONTDIR'] = str(Path(os.environ.get('SystemRoot', 'C:/Windows')) / 'Fonts')
    env['AMSTRAD_CABINET'] = str(ROOT / 'assets/front/pc1512-front.png')
    if args.pattern:
        env['AMSTRAD_TEST_PATTERN'] = '1'
    else:
        env.pop('AMSTRAD_TEST_PATTERN', None)
    # Reserve an available local port. Only the authenticated emulator will use it.
    with socket.socket() as listener:
        listener.bind(('127.0.0.1', 0))
        port = listener.getsockname()[1]
    token = out / 'automation.token'
    token.unlink(missing_ok=True)
    command = [str(exe), '-P', str(vm), '-R', str(args.installation / 'roms'),
               '-O', str(vm / 'global.cfg'), '-L', str(out / '86box.log'),
               '--automation', f'tcp:{port}', '--automation-token-file', str(token),
               '--automation-hold', '--automation-seed', '1512']
    report = {'command':command, 'platform':env['QT_QPA_PLATFORM'], 'headless':True, 'shader_requested':args.shader, 'executable_sha256':digest(exe),
              'source_revision':subprocess.check_output(['git','-C',str(ROOT/'upstream/86Box'),
                                                       'rev-parse','HEAD'], text=True).strip(),
              'pattern':args.pattern, 'checks':{}, 'responses':[]}
    if args.shader:
        report['crt_shader_sha256'] = digest(exe.parent/'shaders/ibmulator-crt.frag')
    original_paths = [args.installation/'Disks/PC1512 A1 - MSDOS.img',
                      args.installation/'Disks/PC1512 A2 - GEM1.img']
    before = {str(p):digest(p) for p in original_paths}
    report['original_media_before'] = before
    (out/'config-before.cfg').write_bytes((vm/'86box.cfg').read_bytes())
    process = None
    stream = None
    sock = None
    with (out/'process.log').open('w', encoding='utf-8') as log:
        try:
            process = subprocess.Popen(command, cwd=exe.parent, env=env,
                                       stdout=log, stderr=subprocess.STDOUT,
                                       creationflags=subprocess.CREATE_NO_WINDOW)
            deadline = time.monotonic() + 15
            connection_error = 'token file not created'
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise RuntimeError(f'86Box exited at startup: {process.returncode}; see {out}/process.log')
                if token.exists():
                    try:
                        sock = socket.create_connection(('127.0.0.1',port), timeout=1)
                        sock.settimeout(50)
                        break
                    except OSError as error:
                        connection_error = str(error)
                time.sleep(.1)
            if sock is None:
                raise RuntimeError(f'Automation connection failed: {connection_error}')
            stream = sock.makefile('rwb')
            def request(cmd, record=True):
                stream.write((cmd+'\n').encode('utf-8'))
                stream.flush()
                line = stream.readline()
                if not line:
                    raise RuntimeError(f'Emulator disconnected on {cmd}')
                reply = json.loads(line)
                if record:
                    report['responses'].append({'command':cmd, 'reply':reply})
                if not reply.get('ok'):
                    raise RuntimeError(f'{cmd}: {reply}')
                return reply
            request('auth '+token.read_text().strip(), record=False)
            report['info'] = request('info')
            def screen(name):
                reply = request('text')
                text = '\n'.join(bytes.fromhex(r).decode('cp437') for r in reply['chars'])
                (out/f'{name}.txt').write_text(text, encoding='utf-8')
                return text
            def capture(name, w=950, h=1030):
                request(f'screenshot-ui {w} {h} {out / (name+".png")}')
                request(f'screenshot {out / (name+"-raw.png")}')
            def key(scan, down=True):
                request(f'key {"down" if down else "up"} {scan}')
            def wait_prompt():
                for _ in range(80):
                    request('step 500')
                    reply = request('text')
                    row = bytes.fromhex(reply['chars'][reply['cursor'][0]]).decode('cp437')
                    if row.rstrip() == 'A>' and reply['cursor'][1] == 2:
                        return
                raise AssertionError('DOS did not return to an idle A> prompt')
            def enter(text):
                for ch in text.lower()+'\n':
                    if ch == ':': key(0x2a)
                    key(SCANS[ch]); key(SCANS[ch], False)
                    if ch == ':': key(0x2a, False)
                    request('step 20')
                wait_prompt()
            def drive_audio_begin(drive):
                # Expire the previous drive's motor timeout and let its physical
                # playback thread finish the stop sample before recording.
                request('step 6000')
                time.sleep(2)
                idle = request('audio level 500')['streams']['fdd']
                assert idle['peak_db'] < -80, f'Previous drive still audible: {idle}'
                folder = out / ('drive-' + drive)
                folder.mkdir(exist_ok=True)
                request(f'audio start {folder}')
                return folder
            def drive_audio_end(drive, folder):
                # Mechanical audio is generated on a wall-clock thread, unlike
                # the guest CPU stepped by this test. Capture that actual output.
                time.sleep(1)
                request('audio stop')
                with wave.open(str(folder / 'fdd.wav'), 'rb') as recording:
                    assert recording.getframerate() == 48000
                    assert recording.getsampwidth() == 2
                    samples = array('h', recording.readframes(recording.getnframes()))
                peak = max(map(abs, samples), default=0)
                assert peak > 100, f'Drive {drive.upper()}: produced silent floppy audio'
                report.setdefault('floppy_audio', {})[drive] = {
                    'peak_pcm16': peak, 'samples': len(samples), 'recording': str(folder / 'fdd.wav')}
                report['checks'][f'panasonic_audio_{drive}'] = True
            result = request('wait text 20000 AMSTRAD')
            assert result['matched'], 'POST banner missing'
            request('step 100')
            screen('post')
            capture('post')
            assert request('wait text 40000 V5.00')['matched'], 'DOS mouse driver startup missing'
            wait_prompt()
            text = screen('dos-boot')
            assert 'MOUSE' in text and 'A>' in text, text
            report['checks']['post_dos'] = True
            capture('dos-boot')
            if args.pattern:
                capture('pattern-wide', 1500, 850)
                capture('pattern-tall', 650, 1050)
            else:
                # Translate the modern ISO physical key to the PC1512 key,
                # including Shift and release; DOS's UK driver chooses glyphs.
                for scan, shifted in [(0x56, False), (0x56, True),
                                      (0x2b, False), (0x2b, True)]:
                    if shifted: key(0x2a)
                    key(scan); key(scan, False)
                    if shifted: key(0x2a, False)
                    request('step 100')
                reply = request('text')
                row = bytes.fromhex(reply['chars'][reply['cursor'][0]]).decode('cp437')
                assert row.rstrip() == 'A>\\|\\|', repr(row)
                assert not int(request('memr 0x417 1')['data'], 16) & 3, 'Shift stuck'
                for _ in range(4):
                    key(0x0e); key(0x0e, False)
                    request('step 20')
                wait_prompt()
                report['checks']['iso_key_uses_pc1512_guest_layout'] = True
                if args.floppy_sounds:
                    audio_a = drive_audio_begin('a')
                enter('dir a:')
                if args.floppy_sounds:
                    drive_audio_end('a', audio_a)
                text_a = screen('dir-a')
                assert 'XCOPY' in text_a and '42 File(s)' in text_a and 'free' in text_a.lower(), text_a
                capture('dir-a')
                if args.floppy_sounds:
                    audio_b = drive_audio_begin('b')
                enter('dir b:')
                if args.floppy_sounds:
                    drive_audio_end('b', audio_b)
                text_b = screen('dir-b')
                assert 'GEM' in text_b and 'free' in text_b.lower(), text_b
                capture('dir-b')
                enter('dir a:')
                assert 'XCOPY' in screen('dir-a-again'), 'A changed when B was read'
                report['checks']['keyboard_dir_a_b_independent'] = True
                # Hold Shift through the real application's existing deactivation
                # connection, then inspect the BIOS modifier flag after it runs.
                key(0x2a)
                request('step 100')
                held = int(request('memr 0x417 1')['data'],16)
                assert held & 2, f'Shift make not observed: {held}'
                request('ui-focusout')
                request('step 100')
                released = int(request('memr 0x417 1')['data'],16)
                assert not released & 3, f'Shift stuck after focus loss: {released}'
                report['checks']['focus_loss_releases_keys'] = True
                capture('dos-wide', 1500, 850)
                capture('dos-tall', 650, 1050)
                enter('echo keyboard ok')
                assert 'keyboard ok' in screen('keyboard'), 'DOS command echo missing'
                capture('keyboard')
                if not args.windows and not args.shader:
                    request(f'ui-cabinet-test {out}')
                    report['checks']['cabinet_click_hover_and_capture_guard'] = True
                request('ui-mouse-capture-test')
                report['checks']['mouse_capture_only_on_screen_clicks'] = True
                request(f'ui-fullscreen-test {out / "fullscreen.png"}')
                report['checks']['f11_fullscreen_toggle_restore'] = True
            request('quit')
            process.wait(timeout=15)
            assert process.returncode == 0, process.returncode
            report['checks']['clean_exit'] = True
            if args.floppy_sounds:
                saved = (vm / '86box.cfg').read_text()
                for drive in ['01', '02']:
                    assert f'fdd_{drive}_audio = panasonic_ju4755_40t' in saved, saved
                report['checks']['panasonic_profiles_persisted'] = True
            assert not token.exists(), 'Automation token not cleaned up'
            report['checks']['token_cleanup'] = True
            if args.shader:
                log.flush()
                runtime_log = '\n'.join((out/name).read_text(encoding='utf-8', errors='replace')
                                        for name in ['native.log','crt.log'] if (out/name).exists())
                assert 'Amstrad CRT active: IBMulator PS/1' in runtime_log, runtime_log
                assert 'Amstrad CRT fallback:' not in runtime_log, runtime_log
                assert 'convergence0.00 sampling=sharp' in runtime_log, runtime_log
                report['checks']['ibmulator_shader_active'] = True
        except Exception as error:
            report['failure'] = str(error)
            raise
        finally:
            if stream: stream.close()
            if sock: sock.close()
            if process and process.poll() is None:
                process.terminate()
                process.wait(timeout=10)
            report['original_media_after'] = {str(p):digest(p) for p in original_paths}
            report['checks']['original_media_unchanged'] = before == report['original_media_after']
            (out/'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps({'result':'PASS', 'checks':report['checks'], 'evidence':str(out)}, indent=2))

if __name__ == '__main__':
    main()
