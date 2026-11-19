import json
import subprocess
import sys


def visible_app(window, monitors, screen=''):
    monitor = next((m for m in monitors if m.get('name') == screen), None) if screen else None
    monitor = monitor or next((m for m in monitors if m.get('focused')), None)
    if not monitor or not window.get('class') or not window.get('mapped') or window.get('hidden'):
        return {}
    special = monitor.get('specialWorkspace', {}).get('id', 0)
    workspace = special or monitor.get('activeWorkspace', {}).get('id')
    if window.get('workspace', {}).get('id') != workspace and not window.get('pinned'):
        return {}
    if window.get('monitor') != monitor.get('id'):
        return {}
    return {k: window.get(k, '') for k in ('class', 'initialClass', 'title')}


def main():
    def query(command):
        return json.loads(subprocess.check_output(['hyprctl', '-j', command], timeout=2))
    try:
        result = visible_app(query('activewindow'), query('monitors'), sys.argv[1] if len(sys.argv) > 1 else '')
    except (OSError, ValueError, subprocess.SubprocessError):
        result = {}
    print(json.dumps(result, ensure_ascii=False))


if __name__ == '__main__':
    main()
