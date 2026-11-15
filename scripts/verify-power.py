"""Exercise real Qt rear-button clicks and guest CAD on a disposable PC1512 VM."""
import argparse
import json
import os
import re
from pathlib import Path
import socket
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--windows', action='store_true')
    parser.add_argument('--fullscreen', action='store_true')
    parser.add_argument('--toggle-before-power', action='store_true')
    parser.add_argument('--executable', type=Path, default=ROOT/'local/dist/86Box.exe')
    args = parser.parse_args()
    args.executable = args.executable.resolve()
    variant = ('-windows' if args.windows else '') + ('-fullscreen' if args.fullscreen else '') + ('-toggle' if args.toggle_before_power else '')
    OUT = ROOT / ('local/verification-power' + variant)
    VM = ROOT / ('local/verify-power' + variant + '-vm')
    OUT.mkdir(exist_ok=True)
    subprocess.run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                    str(ROOT/'scripts/prepare-vm.ps1'), '-Name', VM.name], check=True)
    config = VM / '86box.cfg'
    settings = re.sub(r'(?m)^start_in_fullscreen\s*=.*\n?', '', config.read_text())
    config.write_text(settings.replace('[General]',
                      f'[General]\nstart_in_fullscreen = {int(args.fullscreen)}', 1))
    env = os.environ.copy()
    env.update(QT_QPA_PLATFORM='windows' if args.windows else 'offscreen', AMSTRAD_HEADLESS='1', AMSTRAD_CRT='0',
               AMSTRAD_CABINET=str(ROOT/'assets/front/pc1512-front.png'))
    env.pop('AMSTRAD_POWER_ON', None)
    env['QT_QPA_FONTDIR'] = str(Path(os.environ.get('SystemRoot', 'C:/Windows'))/'Fonts')
    with socket.socket() as listener:
        listener.bind(('127.0.0.1', 0))
        port = listener.getsockname()[1]
    token = OUT/'automation.token'
    token.unlink(missing_ok=True)
    command = [str(args.executable), '-P', str(VM), '-R', 'C:/Emulators/86Box/roms',
               '-O', str(VM/'global.cfg'), '-L', str(OUT/'86box.log'), '--automation', f'tcp:{port}',
               '--automation-token-file', str(token), '--automation-hold']
    report = {'checks': {}, 'responses': []}
    sock = stream = process = None
    with (OUT/'process.log').open('w') as log:
        try:
            process = subprocess.Popen(command, cwd=args.executable.parent, env=env,
                                       stdout=log, stderr=subprocess.STDOUT,
                                       creationflags=subprocess.CREATE_NO_WINDOW)
            for _ in range(150):
                if process.poll() is not None: raise RuntimeError('Emulator exited during startup')
                if token.exists():
                    try:
                        sock = socket.create_connection(('127.0.0.1', port), timeout=1)
                        break
                    except OSError: pass
                time.sleep(.1)
            if sock is None: raise RuntimeError('Automation socket did not start')
            sock.settimeout(60)
            stream = sock.makefile('rwb')
            def request(command, record=True):
                stream.write((command+'\n').encode()); stream.flush()
                reply = json.loads(stream.readline())
                if record: report['responses'].append({'command': command, 'reply': reply})
                if not reply.get('ok'): raise AssertionError((command, reply))
                return reply
            request('auth '+token.read_text().strip(), False)
            def action(op):
                request('ui-power '+op)
                time.sleep(.3)
                return request('ui-power state')
            def capture(name, w=950, h=1030):
                # The screenshot helper resizes the window, which clears Qt's
                # fullscreen flag. Keep native fullscreen runs observational;
                # windowed runs retain the image/resize checks below.
                if args.fullscreen and not args.toggle_before_power:
                    return
                request(f'screenshot-ui {w} {h} {OUT/(name+".png")}')
            def text():
                return '\n'.join(bytes.fromhex(row).decode('cp437') for row in request('text')['chars'])
            def prompt():
                for _ in range(90):
                    request('step 500')
                    reply = request('text')
                    row = bytes.fromhex(reply['chars'][reply['cursor'][0]]).decode('cp437')
                    if row.rstrip() == 'A>' and reply['cursor'][1] == 2: return
                raise AssertionError('DOS prompt missing')
            state = request('ui-power state')
            assert state['fullscreen'] == args.fullscreen, ('Startup mode was deferred until guest power-on', state)
            assert not state['captured'], ('Startup captured the mouse', state)
            report['checks']['window_mode_restored_while_off'] = True
            if args.toggle_before_power:
                state = action('fullscreen')
                assert state['fullscreen'] != args.fullscreen and not state['captured'], state
            mode = {key: state[key] for key in ('fullscreen', 'maximized', 'mode_changes')}
            def check_mode():
                state = request('ui-power state')
                assert {key: state[key] for key in mode} == mode, ('Power changed window mode', mode, state)
                assert not state['captured'], ('Power captured the mouse', state)
            assert not state['on'] and state['pause_reasons'] & 512 and state['reset_hidden'], state
            assert state['peek'], 'Off cabinet did not show its power button at startup'
            action('leave'); time.sleep(1.3)
            assert request('ui-power state')['peek'], 'Off power button disappeared after leaving it'
            report['checks']['off_button_visible_without_hover'] = True
            report['checks']['starts_off_no_reset'] = True
            capture('off')
            assert not action('close-view')['cable_view']
            assert action('peek')['peek']
            capture('off-peek')
            for w, h, label in [(1500, 850, 'wide'), (650, 1050, 'tall')]:
                capture('off-peek-'+label, w, h)
            capture('off-peek', 950, 1030)
            assert action('bay-view')['cable_view']
            capture('off-bay-peek')
            action('close-view')
            report['checks']['both_views_available'] = True
            check_mode()
            assert action('press')['on'], 'Button did not switch on'
            time.sleep(1.3)
            assert not request('ui-power state')['peek'], 'On power button did not auto-hide'
            report['checks']['on_button_auto_hides'] = True
            assert request('wait text 20000 AMSTRAD')['matched'], 'Power-on POST missing'
            capture('post')
            assert request('wait text 40000 V5.00')['matched']
            prompt()
            check_mode()
            report['checks']['first_power_on_preserves_mode_and_free_mouse'] = True
            report['checks']['button_boots_post_and_dos'] = True
            action('peek'); capture('on-peek')
            action('bay-view'); capture('on-bay-peek')
            request('memw 0x60000 deadbeef')
            assert request('memr 0x60000 4')['data'].lower() == 'deadbeef'
            assert not action('press')['on']
            action('leave'); time.sleep(1.3)
            assert request('ui-power state')['peek'], 'Power-off did not keep the button visible'
            capture('off-after-dos')
            report['checks']['power_off_restores_visible_button'] = True
            request('release')
            before = request('status')['ms']; time.sleep(.6)
            after = request('status')['ms']
            assert before == after, 'CPU ran while switched off'
            request('hold')
            report['checks']['off_keeps_window_and_stops_cpu'] = True
            check_mode()
            assert action('press')['on']
            assert request('memr 0x60000 4')['data'].lower() != 'deadbeef', 'Power-on resumed old RAM'
            assert request('wait text 20000 AMSTRAD')['matched']
            assert request('wait text 40000 V5.00')['matched']
            prompt()
            check_mode()
            report['checks']['later_power_cycle_preserves_mode_and_free_mouse'] = True
            report['checks']['off_on_is_a_cold_boot'] = True
            # Clear the display through DOS before checking that Ctrl+F12 caused a reboot.
            for scan in (0x2e, 0x26, 0x1f, 0x1c):  # CLS + Return
                request(f'key down {scan}'); request(f'key up {scan}'); request('step 30')
            prompt()
            assert 'AMSTRAD' not in text()
            action('cad')
            assert request('wait text 20000 AMSTRAD')['matched'], 'Guest Ctrl+Alt+Del did not reboot'
            capture('cad-reboot')
            assert request('wait text 40000 V5.00')['matched']
            prompt()
            report['checks']['ctrl_f12_sends_guest_cad'] = True
            check_mode()
            assert not int(request('memr 0x417 1')['data'], 16) & 0x0c, 'Ctrl/Alt stuck after CAD'
            report['checks']['cad_releases_modifiers'] = True
            action('close-view')
            assert not action('press')['on']
            request('quit'); process.wait(timeout=15)
            assert process.returncode == 0
            report['checks']['clean_exit_while_off'] = True
        except Exception as error:
            report['failure'] = str(error)
            raise
        finally:
            if stream: stream.close()
            if sock: sock.close()
            if process and process.poll() is None:
                process.terminate(); process.wait(timeout=10)
            (OUT/'report.json').write_text(json.dumps(report, indent=2))
    print(json.dumps({'result': 'PASS', 'checks': report['checks'], 'evidence': str(OUT)}, indent=2))

if __name__ == '__main__': main()
