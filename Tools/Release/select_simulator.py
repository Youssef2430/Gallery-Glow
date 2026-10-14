#!/usr/bin/env python3
"""Select an available Apple TV simulator without hard-coding a runtime version."""
import json
import subprocess

data = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '-j']))
for runtime, devices in sorted(data['devices'].items(), reverse=True):
    if 'tvOS' in runtime:
        for device in devices:
            if device.get('isAvailable') and 'Apple TV' in device['name']:
                print('TVOS_SIMULATOR_ID=' + device['udid'])
                raise SystemExit(0)
raise SystemExit('No tvOS simulator installed. Install the tvOS platform in Xcode Settings > Components.')
