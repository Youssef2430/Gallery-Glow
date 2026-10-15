#!/usr/bin/env python3
"""Select an available Apple TV simulator without hard-coding a runtime version."""
import json
import os
import subprocess

data = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '-j']))
requested = os.environ.get('TVOS_RUNTIME')
for runtime, devices in sorted(data['devices'].items(), reverse=True):
    if 'tvOS' in runtime and (not requested or runtime.endswith('.' + requested)):
        for device in devices:
            if device.get('isAvailable') and 'Apple TV' in device['name']:
                print('TVOS_SIMULATOR_ID=' + device['udid'])
                raise SystemExit(0)
raise SystemExit(f'No matching tvOS simulator installed ({requested or "any"}). Install the tvOS platform in Xcode Settings > Components.')
