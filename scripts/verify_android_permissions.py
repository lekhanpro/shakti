"""Check the actual packaged APK before distributing a Shakti build."""

import argparse
import os
from pathlib import Path
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--sdk-root', type=Path, default=os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT'))
    args = parser.parse_args()
    if not args.apk.is_file():
        parser.error(f'APK not found: {args.apk}')
    if args.sdk_root is None:
        parser.error('Set ANDROID_HOME or pass --sdk-root')
    tool_name = 'aapt.exe' if os.name == 'nt' else 'aapt'
    candidates = sorted(
        (args.sdk_root / 'build-tools').glob(f'*/{tool_name}'),
        key=lambda p: tuple(int(n) for n in re.findall(r'\d+', p.parent.name)),
    )
    if not candidates:
        parser.error('Android SDK build-tools aapt is required')
    aapt = str(candidates[-1])

    def dump(*command):
        return subprocess.run([aapt, 'dump', *command], check=True, capture_output=True, text=True).stdout

    permissions = dump('permissions', str(args.apk))
    manifest = dump('xmltree', str(args.apk), 'AndroidManifest.xml')
    # Bind permissions appear on components, not in `aapt dump permissions`.
    forbidden = [
        'android.permission.BIND_ACCESSIBILITY_SERVICE',
        'android.accessibilityservice.AccessibilityService',
        'ShaktiAccessibilityService',
        'android.permission.BIND_NOTIFICATION_LISTENER_SERVICE',
        'android.permission.READ_SMS',
        'android.permission.RECEIVE_SMS',
        'android.permission.RECEIVE_MMS',
        'android.permission.RECEIVE_WAP_PUSH',
        'android.permission.READ_CALL_LOG',
        'android.permission.WRITE_CALL_LOG',
    ]
    found = [name for name in forbidden if name in permissions or name in manifest]
    if found:
        raise SystemExit('Permission audit FAILED: ' + ', '.join(found))
    if 'android.permission.SEND_SMS' not in permissions:
        raise SystemExit('Permission audit FAILED: emergency SEND_SMS permission is missing')
    print('Permission audit passed: no accessibility/notification listener or SMS/call-log reading access.')
    print('SEND_SMS retained for user-authorized emergency alerts. This audit is not Play Protect approval.')


if __name__ == '__main__':
    main()
