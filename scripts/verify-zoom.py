"""Exercise the monitor close-up (Ctrl+F11) on a disposable PC1512 VM, off and on."""
import json
import os
from pathlib import Path
import socket
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'local/verification-zoom'
VM = ROOT / 'local/verify-zoom-vm'

def main():
    executable = (ROOT/'local/dist/86Box.exe').resolve()
    OUT.mkdir(exist_ok=True)
    subprocess.run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                    str(ROOT/'scripts/prepare-vm.ps1'), '-Name', VM.name], check=True)
    (VM/'amstrad.ini').unlink(missing_ok=True)  # start on the whole computer
    env = os.environ.copy()
    env.update(QT_QPA_PLATFORM='offscreen', AMSTRAD_HEADLESS='1', AMSTRAD_CRT='0',
               AMSTRAD_CABINET=str(ROOT/'assets/front/pc1512-front.png'))
    env.pop('AMSTRAD_POWER_ON', None)
    env['QT_QPA_FONTDIR'] = str(Path(os.environ.get('SystemRoot', 'C:/Windows'))/'Fonts')
    with socket.socket() as listener:
        listener.bind(('127.0.0.1', 0))
        port = listener.getsockname()[1]
    token = OUT/'automation.token'
    token.unlink(missing_ok=True)
    command = [str(executable), '-P', str(VM), '-R', str(ROOT / 'roms'),
               '-O', str(VM/'global.cfg'), '-L', str(OUT/'86box.log'), '--automation', f'tcp:{port}',
               '--automation-token-file', str(token), '--automation-hold']
    report = {'checks': {}}
    sock = stream = process = None
    with (OUT/'process.log').open('w') as log:
        try:
            process = subprocess.Popen(command, cwd=executable.parent, env=env, stdout=log,
                                       stderr=subprocess.STDOUT, creationflags=subprocess.CREATE_NO_WINDOW)
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
            def request(command):
                stream.write((command+'\n').encode()); stream.flush()
                reply = json.loads(stream.readline())
                if not reply.get('ok'): raise AssertionError((command, reply))
                return reply
            request('auth '+token.read_text().strip())
            def zoom():
                request('ui-power zoom')
                time.sleep(.9)  # the view travels for 0.42 s
                return request('ui-power state')['zoomed']
            def capture(name, w=1280, h=800):
                request(f'screenshot-ui {w} {h} {OUT/(name+".png")}')
            assert not request('ui-power state')['zoomed'], 'Started on the close-up'
            capture('off-whole')
            assert zoom(), 'Ctrl+F11 did not close in'
            capture('off-zoom')
            capture('off-zoom-square', 950, 1030)
            report['checks']['zooms_while_off'] = True
            assert 'monitor_zoom=true' in (VM/'amstrad.ini').read_text(), 'Close-up not remembered'
            report['checks']['choice_remembered'] = True
            request('ui-power press'); time.sleep(.3)
            assert request('ui-power state')['on']
            assert request('wait text 20000 AMSTRAD')['matched'], 'Power-on POST missing'
            assert request('wait text 40000 V5.00')['matched']
            request('step 1500')
            capture('on-zoom')
            capture('on-zoom-square', 950, 1030)
            assert not zoom(), 'Ctrl+F11 did not step back'
            request('step 200')
            capture('on-whole')
            # Halfway: the travelling view is drawn like any other.
            request('ui-power zoom'); time.sleep(.18)
            capture('on-travelling')
            time.sleep(.8)
            assert request('ui-power state')['zoomed']
            report['checks']['zooms_while_on_and_back'] = True
            assert zoom() is False
            request('ui-power press'); time.sleep(.3)
            request('quit'); process.wait(timeout=15)
            assert process.returncode == 0
            report['checks']['clean_exit'] = True
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
